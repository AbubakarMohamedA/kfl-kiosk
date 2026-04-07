import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:sss/core/database/daos/orders_dao.dart';
import 'package:sss/features/products/domain/repositories/product_repository.dart';
import 'package:sss/core/database/daos/tenant_config_dao.dart';
import 'package:sss/features/orders/data/models/order_model.dart';
import 'package:sss/core/database/daos/app_config_dao.dart';
import 'package:sss/features/cart/data/models/cart_item_model.dart';
import 'package:sss/features/products/data/models/product_model.dart';
import 'package:sss/features/settings/data/models/tenant_config_model.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sss/core/database/app_database.dart' as drift_db;

import '../../features/orders/data/datasources/sap_invoice_datasource.dart';
import '../../features/orders/data/datasources/local_order_datasource.dart'; // NEW
import '../../di/injection.dart';
import 'sap_auth_service.dart'; // NEW

// NEW: Terminal Info Class
class TerminalInfo {
  final String ip;
  final String name;
  DateTime lastSeen;

  TerminalInfo({
    required this.ip,
    required this.name,
    required this.lastSeen,
  });

  bool get isOnline => DateTime.now().difference(lastSeen).inSeconds < 20;

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'name': name,
    'lastSeen': lastSeen.toIso8601String(),
    'isOnline': isOnline,
  };
}

class LocalServerService {
  final TenantConfigDao _tenantConfigDao;
  final ProductRepository _productRepository;
  final OrdersDao _ordersDao;
  final AppConfigDao _appConfigDao;
  final SapInvoiceDataSource _sapInvoiceDataSource; // NEW
  final SapAuthService _sapAuthService; // NEW: Access active customer
  HttpServer? _server;
  Timer? _sapRetryTimer; // NEW
  final _networkInfo = NetworkInfo();
  
  // NEW: Connected Terminals Tracking
  final Map<String, TerminalInfo> _connectedTerminals = {};

  String? _activeTenantId; // NEW: Track active tenant
  String? _activeBranchId;
  String? _activeWarehouseId;
  String? _activeTierId;

  LocalServerService(
    this._tenantConfigDao,
    this._productRepository,
    this._ordersDao,
    this._appConfigDao,
    this._sapInvoiceDataSource, 
    this._sapAuthService, // NEW
  );

  void setActiveTenantId(String tenantId, {String? branchId, String? warehouseId, String? tierId}) {
    _activeTenantId = tenantId;
    _activeBranchId = branchId;
    _activeWarehouseId = warehouseId;
    _activeTierId = tierId;
    debugPrint('Server: Active Tenant set to $tenantId, Branch: $branchId, Warehouse: $warehouseId, Tier: $tierId');
  }

  // NEW: Method to get connected terminals
  List<TerminalInfo> getConnectedTerminals() {
    _cleanupStaleTerminals();
    return _connectedTerminals.values.toList();
  }
  
  void _cleanupStaleTerminals() {
    final now = DateTime.now();
    _connectedTerminals.removeWhere((ip, info) => now.difference(info.lastSeen).inSeconds > 60); // Optional cleanup of long-dead terminals
  }

  Future<String?> getDeviceIp() async {
    return await _networkInfo.getWifiIP();
  }

  Future<void> start() async {
    if (_server != null) return;

    final app = Router();

    // Health check
    app.get('/api/v1/health', (Request request) => Response.ok('OK'));


    // 0. Sync Init
    app.get('/api/v1/sync/init', (Request request) async {
      if (_activeTenantId == null) {
        return Response.notFound(jsonEncode({'error': 'No active tenant registered on desktop'}), headers: {'Content-Type': 'application/json'});
      }
      
      // NEW: Track terminal
      final clientIp = _getClientIp(request);
      final terminalName = request.url.queryParameters['terminalName'] ?? 'Unknown Terminal';
      
      if (clientIp != null) {
        _connectedTerminals[clientIp] = TerminalInfo(
          ip: clientIp,
          name: terminalName,
          lastSeen: DateTime.now(),
        );
      }

      final configData = await _tenantConfigDao.getConfig(_activeTenantId!);
      
      return Response.ok(
        jsonEncode({
          'tenantId': _activeTenantId,
          'branchId': _activeBranchId,
          'warehouseId': _activeWarehouseId,
          'tierId': _activeTierId,
          'config': configData != null ? TenantConfigModel(
            tenantId: configData.tenantId,
            logoPath: configData.logoPath,
            primaryColor: configData.primaryColor,
            secondaryColor: configData.secondaryColor,
            backgroundPath: configData.backgroundPath,
            appName: configData.appName,
            welcomeMessage: configData.welcomeMessage,
          ).toJson() : null,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    });
    
    // NEW: Heartbeat Endpoint
    app.post('/api/v1/sync/heartbeat', (Request request) async {
      final clientIp = _getClientIp(request);
      
      try {
         final payload = await request.readAsString();
         final data = jsonDecode(payload);
         final terminalName = data['terminalName'] ?? 'Unknown Terminal';
         
         if (clientIp != null) {
            _connectedTerminals[clientIp] = TerminalInfo(
              ip: clientIp,
              name: terminalName,
              lastSeen: DateTime.now(),
            );
         }
         
         return Response.ok(jsonEncode({'status': 'alive'}));
      } catch (e) {
         return Response.internalServerError(body: 'Error processing heartbeat: $e');
      }
    });

    // 1. Get Tenant Config
    app.get('/api/v1/config/<tenantId>', (Request request, String tenantId) async {
      try {
        final actualTenantId = tenantId == 'active' ? _activeTenantId : tenantId;
        if (actualTenantId == null) return Response.notFound('Tenant not found');

        final configData = await _tenantConfigDao.getConfig(actualTenantId);
        if (configData == null) {
          return Response.notFound('Config not found');
        }
        
        final configModel = TenantConfigModel(
          tenantId: configData.tenantId,
          logoPath: configData.logoPath,
          primaryColor: configData.primaryColor,
          secondaryColor: configData.secondaryColor,
          backgroundPath: configData.backgroundPath,
          appName: configData.appName,
          welcomeMessage: configData.welcomeMessage,
        );

        return Response.ok(
          jsonEncode(configModel.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: 'Error fetching config: $e');
      }
    });

    // 1.5 Sync Logo (NEW)
    app.get('/api/v1/sync/logo', (Request request) async {
      try {
        if (_activeTenantId == null) {
          return Response.notFound('No active tenant for logo sync');
        }

        final configData = await _tenantConfigDao.getConfig(_activeTenantId!);
        final logoPath = configData?.logoPath;

        if (logoPath == null || logoPath.isEmpty) {
          return Response.notFound('No custom logo configured');
        }

        final file = File(logoPath);
        if (!await file.exists()) {
          return Response.notFound('Logo file not found on server');
        }

        // Determine simple content type
        final ext = logoPath.toLowerCase();
        String contentType = 'image/png'; // Default
        if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (ext.endsWith('.gif')) {
          contentType = 'image/gif';
        } else if (ext.endsWith('.webp')) {
          contentType = 'image/webp';
        }

        return Response.ok(
          file.openRead(),
          headers: {
            'Content-Type': contentType,
            'Content-Length': (await file.length()).toString(),
          },
        );
      } catch (e) {
        debugPrint('Server: Error serving logo: $e');
        return Response.internalServerError(body: 'Error serving logo: $e');
      }
    });

    // 2. Get Products
    app.get('/api/v1/products/<tenantId>', (Request request, String tenantId) async {
      try {
        final actualTenantId = tenantId == 'active' ? _activeTenantId : tenantId;
        if (actualTenantId == null) return Response.notFound('Tenant not found');

        final requestedBranchId = request.url.queryParameters['branchId'];
        final actualBranchId = requestedBranchId == 'active' ? _activeBranchId : requestedBranchId;

        final products = await _productRepository.getAllProducts();
        var filteredProducts = products.toList();

        if (actualBranchId != null && actualBranchId.isNotEmpty) {
           filteredProducts = products.where((p) => p.branchId == actualBranchId || p.branchId == null || p.branchId!.isEmpty).toList();
        }

        final productModels = filteredProducts.map((product) {
             return ProductModel.fromEntity(product);
        }).toList();
        
        return Response.ok(
          jsonEncode({
            'products': productModels.map((e) => e.toJson()).toList(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: 'Error fetching products: $e');
      }
    });

    // 2.5 Get Product Image (NEW)
    app.get('/api/v1/products/images/<filename>', (Request request, String filename) async {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(docDir.path, 'product_images'));
        final file = File(p.join(imagesDir.path, filename));

        if (!await file.exists()) {
          return Response.notFound('Image not found');
        }

        final ext = filename.toLowerCase();
        String contentType = 'image/png'; // Default
        if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (ext.endsWith('.gif')) {
          contentType = 'image/gif';
        } else if (ext.endsWith('.webp')) {
          contentType = 'image/webp';
        }

        return Response.ok(
          file.openRead(),
          headers: {
            'Content-Type': contentType,
            'Content-Length': (await file.length()).toString(),
          },
        );
      } catch (e) {
        debugPrint('Server: Error serving product image: $e');
        return Response.internalServerError(body: 'Error serving image: $e');
      }
    });

    // 3. Orders
    app.get('/api/v1/orders', (Request request) async {
      try {
        final dbOrders = await _ordersDao.getAllOrders();
        final List<OrderModel> models = [];
        
        for (final order in dbOrders) {
          final items = await _ordersDao.getItemsForOrder(order.id);
          models.add(OrderModel(
            id: order.id,
            phone: order.customerPhone ?? '',
            total: order.totalAmount,
            status: order.status,
            timestamp: order.createdAt,
            tenantId: order.tenantId,
            branchId: order.branchId,
            terminalId: order.terminalId,
            cartItems: items.map((i) => CartItemModel(
              productModel: ProductModel(
                id: i.productId,
                name: i.productName,
                brand: '', // Not in DB snapshot
                price: i.unitPrice,
                category: i.productCategory, // Reconstruct from V13 snapshot
                size: i.productVariant ?? '',
                description: '',
                imageUrl: '',
              ),
              quantity: i.quantity,
              status: i.status, // Reconstruct from V13 snapshot
            )).toList(),
          ));
        }
        
        return Response.ok(
          jsonEncode({
            'orders': models.map((e) => e.toJson()).toList(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        debugPrint('Server: Error fetching orders: $e');
        return Response.internalServerError(body: 'Error fetching orders: $e');
      }
    });

    app.post('/api/v1/orders', (Request request) async {
       try {
         final payload = await request.readAsString();
         final json = jsonDecode(payload);
         OrderModel orderModel = OrderModel.fromJson(json);
         
         // NEW: Capture the active customer at the time of order
         // This ensures retries go to the correct SAP BP even if the staff switches customers later.
         final activeCardCode = await _sapAuthService.getActiveCardCode();
         if (activeCardCode != null && (orderModel.sapCardCode == null || orderModel.sapCardCode!.isEmpty)) {
           orderModel = orderModel.copyWith(sapCardCode: activeCardCode);
         }

         await _ordersDao.upsertOrder(
           drift_db.OrdersCompanion(
             id: drift.Value(orderModel.id),
             totalAmount: drift.Value(orderModel.total),
             status: drift.Value(orderModel.status),
             createdAt: drift.Value(orderModel.timestamp),
             customerPhone: drift.Value(orderModel.phone),
             tenantId: drift.Value(orderModel.tenantId),
             branchId: drift.Value(orderModel.branchId),
             terminalId: drift.Value(orderModel.terminalId),
             sapSyncStatus: drift.Value(orderModel.sapSyncStatus),
             sapCardCode: drift.Value(orderModel.sapCardCode),
           ),
           orderModel.cartItems.map((i) => drift_db.OrderItemsCompanion(
             orderId: drift.Value(orderModel.id),
             productId: drift.Value(i.productModel.id),
             quantity: drift.Value(i.quantity),
             unitPrice: drift.Value(i.productModel.price),
             productName: drift.Value(i.productModel.name),
             productVariant: drift.Value(i.productModel.size),
             status: drift.Value(i.status), // FIX: Prevents Master Server data-wipe
             productCategory: drift.Value(i.productModel.category), // FIX: Prevents Master Server data-wipe
           )).toList(),
         );

         // ✅ NEW: Synchronize with SAP Business One from the Server Side
         // This ensures orders from Kiosks (which don't have SAP credentials) 
         // are synced by the Staff Server which HAS the credentials.
         _sapInvoiceDataSource.syncOrderAsInvoice(orderModel);
         
         // ✅ NEW: Tell the LocalOrderDataSource to refresh its cache and emit to the UI stream
         try {
           getIt<LocalOrderDataSource>().notifyOrdersChanged();
         } catch (e) {
           debugPrint('Server: Error notifying UI stream: $e');
         }

         debugPrint('Server: Order ${orderModel.id} created successfully and triggered SAP sync');
         return Response.ok(
           jsonEncode({'status': 'success', 'orderId': orderModel.id}), 
           headers: {'Content-Type': 'application/json'},
         );
       } catch (e) {
         debugPrint('Server: Error creating order: $e');
         return Response.internalServerError(body: 'Error creating order: $e');
       }
    });
    
    app.post('/api/v1/orders/counter', (Request request) async {
       try {
         final payload = await request.readAsString();
         final data = jsonDecode(payload);
         final key = data['key'] as String;
         final counter = data['counter'] as int;
         
         await _appConfigDao.setInt('counter_$key', counter);
         
         debugPrint('Server: Counter for $key updated to $counter');
         return Response.ok(jsonEncode({'status': 'success'}));
       } catch (e) {
         return Response.internalServerError(body: 'Error updating counter: $e');
       }
    });

    app.get('/api/v1/orders/counter/<keyOrTenantId>', (Request request, String keyOrTenantId) async {
       try {
         String key = keyOrTenantId;
         if (key == 'active') { // For retrocompatibility or direct desktop calls
             final tId = _activeTenantId ?? 'default';
             final bId = _activeBranchId;
             final now = DateTime.now();
             final suffix = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
             
             if (bId != null && bId.isNotEmpty) {
                 key = "${tId}_${bId}_$suffix";
             } else {
                 key = "${tId}_$suffix";
             }
         }
         
         final counter = await _appConfigDao.getInt('counter_$key', defaultValue: 0);
         
         return Response.ok(
           jsonEncode({'counter': counter}),
           headers: {'Content-Type': 'application/json'},
         );
       } catch (e) {
         return Response.internalServerError(body: 'Error fetching counter: $e');
       }
    });
    
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(app.call);

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
      debugPrint('==> Local Server started on port 8080'); // Clearer log
      debugPrint('==> Listening on all interfaces (anyIPv4)');

      // NEW: Start periodic SAP retry task (every 5 minutes)
      _sapRetryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        debugPrint('Server: Running periodic SAP sync retry task...');
        _sapInvoiceDataSource.retryFailedSyncs();
      });
      
      // Perform initial retry on start
      _sapInvoiceDataSource.retryFailedSyncs();

    } catch (e) {
      debugPrint('==> Failed to start server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _sapRetryTimer?.cancel(); // NEW
    _sapRetryTimer = null;
    _connectedTerminals.clear();
  }
  
  // Helper to extract IP from Shelf Request safely cross-platform
  String? _getClientIp(Request request) {
    try {
      final connInfo = request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      return connInfo?.remoteAddress.address;
    } catch (_) {
      return null;
    }
  }
}

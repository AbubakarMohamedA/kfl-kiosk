import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' hide Column;
import 'package:sss/core/config/api_config.dart';
import 'package:sss/core/database/app_database.dart' hide Order, OrderItem;
import 'package:sss/core/database/daos/orders_dao.dart';
import 'package:sss/core/database/daos/app_config_dao.dart';
import 'package:sss/features/orders/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:sss/features/cart/data/models/cart_item_model.dart';
import 'package:sss/features/products/data/models/product_model.dart';

class LocalOrderDataSource implements OrderDataSource {
  static const String _serverUrlKey = 'kfl_server_url';
  static const String _terminalIdKey = 'kfl_terminal_id';
  static const String _ordersKey = 'kfl_orders'; // Legacy
  static const String _migrationDoneKey = 'kfl_persistence_migration_done_v1';
  
  final OrdersDao _ordersDao;
  final AppConfigDao _appConfigDao;
  final http.Client _httpClient;

  LocalOrderDataSource(this._ordersDao, this._appConfigDao, this._httpClient);

  // Terminal ID
  String? _terminalId;
  
  // In-memory cache for fast stream access
  List<OrderModel> _ordersCache = [];
  bool _isInitialized = false;
  bool _isOnline = false;

  // Stream controller for real-time order updates
  final _ordersStreamController = StreamController<List<OrderModel>>.broadcast();

  // Polling timer for sync
  Timer? _syncTimer;
  bool _isSyncing = false;

  @override
  Stream<List<OrderModel>> watchOrders({String? tenantId}) {
    _ensureInitialized();
    if (tenantId == null) {
      return _ordersStreamController.stream;
    }
    return _ordersStreamController.stream.map((orders) {
      return orders.where((o) => o.tenantId == tenantId).toList();
    });
  }

  /// Check if connected to server
  bool get isOnline => _isOnline;

  /// Get current server URL (now from ApiConfig)
  String? get serverUrl => ApiConfig.baseUrl;

  /// Get current terminal ID
  String? get terminalId => _terminalId;

  /// Set terminal ID
  Future<void> setTerminalId(String? id) async {
    _terminalId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null && id.isNotEmpty) {
      await prefs.setString(_terminalIdKey, id);
    } else {
      await prefs.remove(_terminalIdKey);
    }
  }

  /// Set server URL (updates ApiConfig)
  Future<void> setServerUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      ApiConfig.setBaseUrl(url);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverUrlKey, url);
    }
    // Force resync and health check
    await _syncWithServer();
  }

  /// Initialize the data source
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load config from prefs
    final savedUrl = prefs.getString(_serverUrlKey);
    if (savedUrl != null) {
      ApiConfig.setBaseUrl(savedUrl);
    }
    _terminalId = prefs.getString(_terminalIdKey);
    
    // Check for migration
    final migrationDone = prefs.getBool(_migrationDoneKey) ?? false;
    if (!migrationDone) {
      await _migrateFromPrefs(prefs);
      await prefs.setBool(_migrationDoneKey, true);
    }

    // Load from DB
    await _loadFromDb();
    
    _isInitialized = true;
    _startSyncPolling();
    await _syncWithServer();
  }

  Future<void> _loadFromDb() async {
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
            brand: '', // Brand not in snapshot
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
    _ordersCache = models;
    _ordersStreamController.add(List.from(_ordersCache));
  }

  Future<void> _migrateFromPrefs(SharedPreferences prefs) async {
    // 1. Migrate Orders
    final ordersJson = prefs.getString(_ordersKey);
    if (ordersJson != null) {
      try {
        final List<dynamic> ordersList = jsonDecode(ordersJson);
        for (final json in ordersList) {
          final model = OrderModel.fromJson(json as Map<String, dynamic>);
          await _saveToDb(model);
        }
      } catch (e) {
        // Migration error
      }
    }
    // Note: Order counters migration is tricky because it's a map now.
    // We'll rely on the DB's natural count for new IDs or continue with stored counters if needed.
    // Actually, getOrderCounter in this class uses _orderCounters. 
    // I should move counters to a new DB table or keep in AppConfig.
    // Let's use AppConfig for counters to keep it simple and persistent.
  }

  Future<void> _saveToDb(OrderModel model) async {
    await _ordersDao.upsertOrder(
      OrdersCompanion(
        id: Value(model.id),
        totalAmount: Value(model.total),
        status: Value(model.status),
        createdAt: Value(model.timestamp),
        customerPhone: Value(model.phone),
        tenantId: Value(model.tenantId),
        branchId: Value(model.branchId),
        terminalId: Value(model.terminalId),
      ),
      model.cartItems.map((i) => OrderItemsCompanion(
        orderId: Value(model.id),
        productId: Value(i.productModel.id),
        quantity: Value(i.quantity),
        unitPrice: Value(i.productModel.price),
        productName: Value(i.productModel.name),
        productVariant: Value(i.productModel.size),
        status: Value(i.status),              // Persist status (V13)
        productCategory: Value(i.productModel.category), // Persist category (V13)
      )).toList(),
    );
  }

  /// Start polling for server updates
  void _startSyncPolling() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _syncWithServer();
    });
  }

  /// Sync orders with server
  Future<void> _syncWithServer() async {
    if (_isSyncing) return;
    
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isEmpty) {
      _isOnline = false;
      return;
    }

    _isSyncing = true;
    try {
      // 1. Health check first
      final healthResp = await _httpClient.get(
        Uri.parse('$baseUrl/api/v1/health'),
      ).timeout(const Duration(seconds: 10));
      
      if (healthResp.statusCode != 200) {
         _isOnline = false;
         _ordersStreamController.add(List.from(_ordersCache)); // Notify UI of status change
         return;
      }

      // 2. Sync orders
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/v1/orders'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ordersList = data['orders'] ?? [];
        final newOrders = ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
        

        // Update cache if orders changed
        if (_hasOrdersChanged(newOrders)) {
          for (final order in newOrders) {
             await _saveToDb(order); // Now uses createOrUpdateOrder for upsert behavior
          }
          await _loadFromDb(); 
        }
        
        _isOnline = true;
      } else {
        _isOnline = false;
      }
    } catch (e) {
      if (e is! TimeoutException) {
        debugPrint('[OrderDataSource] Sync error: $e');
      }
      _isOnline = false;
    } finally {
      _isSyncing = false;
    }
  }

  bool _hasOrdersChanged(List<OrderModel> newOrders) {
    if (_ordersCache.length != newOrders.length) return true;
    
    for (int i = 0; i < _ordersCache.length; i++) {
      final cached = _ordersCache[i];
      final newOrder = newOrders.firstWhere(
        (o) => o.id == cached.id,
        orElse: () => cached,
      );
      if (cached.status != newOrder.status) {
        return true;
      }
    }
    
    // Check for new orders
    for (final newOrder in newOrders) {
      if (!_ordersCache.any((o) => o.id == newOrder.id)) {
        return true;
      }
    }
    
    return false;
  }

  /// Send order to server
  Future<void> _sendToServer(OrderModel order) async {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isEmpty) return;

    try {
      final resp = await _httpClient.post(
        Uri.parse('$baseUrl/api/v1/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(order.toJson()),
      ).timeout(const Duration(seconds: 10));
      
      if (resp.statusCode != 200) {
        debugPrint('[OrderDataSource] Server returned ${resp.statusCode} on order creation: ${resp.body}');
      }
    } catch (e) {
      debugPrint('[OrderDataSource] Failed to send order to server: $e');
      // Ignore errors - order is saved locally
    }
  }

  /// Update order on server
  Future<void> _updateOnServer(String orderId, Map<String, dynamic> data) async {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isEmpty) return;

    try {
      final resp = await _httpClient.put(
        Uri.parse('$baseUrl/api/v1/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      
      if (resp.statusCode != 200) {
        debugPrint('[OrderDataSource] Server returned ${resp.statusCode} on order update: ${resp.body}');
      }
    } catch (e) {
      debugPrint('[OrderDataSource] Failed to update order on server: $e');
      // Ignore errors
    }
  }

  // Create/Save order
  @override
  Future<String> saveOrder(OrderModel order) async {
    await _ensureInitialized();

    // Inject terminal ID if not present and available
    var orderToSave = order;
    if (order.terminalId == null && _terminalId != null) {
      orderToSave = order.copyWith(terminalId: _terminalId);
    }

    await _saveToDb(orderToSave);
    await _loadFromDb(); // Refresh cache and emit
    await _sendToServer(orderToSave);

    return orderToSave.id;
  }

  // Get all orders
  @override
  Future<List<OrderModel>> getOrders({String? tenantId}) async {
    await _ensureInitialized();
    if (tenantId == null) {
      return List.from(_ordersCache);
    }
    return _ordersCache.where((o) => o.tenantId == tenantId).toList();
  }

  // Get order by ID
  @override
  Future<OrderModel?> getOrderById(String id) async {
    await _ensureInitialized();

    try {
      return _ordersCache.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update order status
  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _ensureInitialized();

    // Update in DB
    await _ordersDao.updateOrderStatus(orderId, status);
    await _loadFromDb();
    await _updateOnServer(orderId, {'status': status});
  }

  // Save full order
  @override
  Future<void> saveFullOrder(OrderModel orderModel) async {
    await _ensureInitialized();

    await _saveToDb(orderModel);
    await _loadFromDb();
    await _sendToServer(orderModel);
  }

  // Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    await _ensureInitialized();
    return _ordersCache.where((order) => order.status == status).toList();
  }

  // Get orders by date
  Future<List<OrderModel>> getOrdersByDate(DateTime date) async {
    await _ensureInitialized();

    return _ordersCache.where((order) {
      return order.timestamp.year == date.year &&
          order.timestamp.month == date.month &&
          order.timestamp.day == date.day;
    }).toList();
  }

  // Get today's orders
  Future<List<OrderModel>> getTodaysOrders() async {
    final today = DateTime.now();
    return getOrdersByDate(today);
  }

  // Get order counter
  @override
  Future<int> getOrderCounter({String? tenantId, String? branchId}) async {
    await _ensureInitialized();
    final key = _getCounterKey(tenantId, branchId);
    
    // 1. Try fetching from server first if online
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isNotEmpty) {
      try {
        final resp = await _httpClient.get(
          Uri.parse('$baseUrl/api/v1/orders/counter/$key'),
        ).timeout(const Duration(seconds: 10));
        
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final serverCounter = data['counter'] as int;
          // Sync local counter to server counter
          await _appConfigDao.setInt('counter_$key', serverCounter);
          return serverCounter;
        }
      } catch (e) {
        debugPrint('[OrderDataSource] Error fetching server counter: $e');
      }
    }

    // 2. Fallback to local
    return await _appConfigDao.getInt('counter_$key', defaultValue: 0);
  }

  // Increment order counter
  @override
  Future<void> incrementOrderCounter({String? tenantId, String? branchId}) async {
    await _ensureInitialized();
    final key = _getCounterKey(tenantId, branchId);
    final count = await getOrderCounter(tenantId: tenantId, branchId: branchId);
    
    // Update local
    await _appConfigDao.setInt('counter_$key', count + 1);

    // Sync to server
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isNotEmpty) {
      try {
        await _httpClient.post(
          Uri.parse('$baseUrl/api/v1/orders/counter'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tenantId': tenantId,
            'key': key,
            'counter': count + 1
          }),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        // Sync error
      }
    }
  }

  String _getCounterKey(String? tenantId, String? branchId) {
    // If no tenant (e.g. legacy/admin), use "default"
    // Format: tenantId_branchId_YYYY-MM-DD or tenantId_YYYY-MM-DD
    final tId = tenantId ?? "default";
    final now = DateTime.now();
    final dateSuffix = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    if (branchId != null && branchId.isNotEmpty) {
      return "${tId}_${branchId}_$dateSuffix";
    }
    return "${tId}_$dateSuffix";
  }


  // Delete order
  Future<void> deleteOrder(String orderId) async {
    await _ordersDao.db.transaction(() async {
       await (_ordersDao.db.delete(_ordersDao.db.orderItems)..where((tbl) => tbl.orderId.equals(orderId))).go();
       await (_ordersDao.db.delete(_ordersDao.db.orders)..where((tbl) => tbl.id.equals(orderId))).go();
    });
    await _loadFromDb();
    
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isNotEmpty) {
      try {
        await _httpClient.delete(
          Uri.parse('$baseUrl/api/v1/orders/$orderId'),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        // Ignore
      }
    }
    
    _ordersStreamController.add(List.from(_ordersCache));
  }

  // Get total sales for today
  Future<double> getTodaysSales() async {
    final todaysOrders = await getTodaysOrders();
    double total = 0.0;

    for (var order in todaysOrders) {
      total += order.total;
    }

    return total;
  }

  // Get order count by status
  Future<int> getOrderCountByStatus(String status) async {
    final orders = await getOrdersByStatus(status);
    return orders.length;
  }

  // Search orders by phone number
  Future<List<OrderModel>> searchByPhone(String phone) async {
    await _ensureInitialized();

    return _ordersCache.where((order) => order.phone.contains(phone)).toList();
  }

  // Search orders by order ID
  Future<List<OrderModel>> searchByOrderId(String query) async {
    await _ensureInitialized();

    return _ordersCache
        .where((order) => order.id.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Clear all orders
  Future<void> clearAllOrders() async {
    await _ordersDao.db.transaction(() async {
      await _ordersDao.db.delete(_ordersDao.db.orderItems).go();
      await _ordersDao.db.delete(_ordersDao.db.orders).go();
    });
    await _loadFromDb();
    
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl.isNotEmpty) {
      try {
        await _httpClient.delete(
          Uri.parse('$baseUrl/api/v1/orders'),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        // Ignore
      }
    }
    
    _ordersStreamController.add(List.from(_ordersCache));
  }

  // Dispose
  void dispose() {
    _syncTimer?.cancel();
    _ordersStreamController.close();
  }
}
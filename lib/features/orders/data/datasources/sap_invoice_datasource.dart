import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:synchronized/synchronized.dart';
import 'package:sss/core/database/app_database.dart'; // for Order type
import 'package:sss/core/database/daos/orders_dao.dart';
import '../../../../core/services/sap_auth_service.dart';
import '../../../cart/data/models/cart_item_model.dart'; // Needed for manual mapping
import '../models/order_model.dart';
import '../../../products/data/models/product_model.dart'; // Needed for manual mapping

class SapInvoiceDataSource {
  final SapAuthService _sapAuthService;
  final OrdersDao _ordersDao;
  static final _lock = Lock();

  SapInvoiceDataSource(this._sapAuthService, this._ordersDao) {
    _startScheduledSyncWorker();
  }

  void _startScheduledSyncWorker() {
  }

  SapAuthService getSapAuthService() => _sapAuthService;

  /// Live stream of failed orders — the UI subscribes to this.
  Stream<List<Order>> watchFailedOrders() => _ordersDao.watchFailedSapOrders();

  /// Permanently cancel sync for an order so retries stop.
  Future<void> cancelOrderSync(String orderId) => _ordersDao.cancelSapSync(orderId);

  /// Retry a single Drift [Order] entity — called from the manual UI.
  /// Goes through the same [_lock] as the background retry so they never overlap.
  Future<void> retrySingleOrder(Order orderEntity) async {
    final dbItems = await _ordersDao.getItemsForOrder(orderEntity.id);
    final orderModel = OrderModel(
      id: orderEntity.id,
      total: orderEntity.totalAmount,
      phone: orderEntity.customerPhone ?? '',
      timestamp: orderEntity.createdAt,
      status: orderEntity.status,
      tenantId: orderEntity.tenantId,
      branchId: orderEntity.branchId,
      terminalId: orderEntity.terminalId,
      sapSyncStatus: orderEntity.sapSyncStatus,
      sapDocEntry: orderEntity.sapDocEntry,
      sapCardCode: orderEntity.sapCardCode,
      cartItems: dbItems.map((item) => CartItemModel(
        productModel: ProductModel(
          id: item.productId,
          name: item.productName,
          price: item.unitPrice,
          brand: '',
          category: item.productCategory,
          size: item.productVariant ?? '',
          description: '',
          imageUrl: '',
          salesVatGroup: item.salesVatGroup,
        ),
        quantity: item.quantity,
        status: item.status,
      )).toList(),
    );
    await syncOrderAsInvoice(orderModel);
  }

  Future<void> syncOrderAsInvoice(OrderModel order) async {
    // Wrap the entire sync process in a lock to prevent concurrent database access 
    // in SAP B1 (ODBC -2028 locks)
    await _lock.synchronized(() async {
      try {
        if (!await _sapAuthService.isConfigured()) {
        debugPrint('SapInvoiceDataSource: SAP is not configured. Skipping sync.');
        return;
      }

      final baseUrl = await _sapAuthService.getBaseUrl();
      final headers = await _sapAuthService.getHeaders();
      
      if (!headers.containsKey('Cookie')) {
        debugPrint('SapInvoiceDataSource: No valid SAP session. Skipping sync.');
        return;
      }

      final url = Uri.parse('$baseUrl/Invoices');
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final docDateString = dateFormat.format(order.timestamp);

      final creds = await _sapAuthService.loadCredentials();
      
      // Capture the card code used for THIS order. 
      // If it's already in the order (from a previous sync attempt), use it.
      // Otherwise, get the current active one and save it for future retries.
      String? activeCardCode = order.sapCardCode;
      if (activeCardCode == null || activeCardCode.isEmpty) {
        activeCardCode = await _sapAuthService.getActiveCardCode();
        // Save it to the DB so retries use the SAME customer
        if (activeCardCode != null) {
          await _ordersDao.updateSapSyncStatus(order.id, 'pending'); 
          // Note: we'll update the full order object in the DB later if we want to persist the card code immediately,
          // but for now let's just make sure we use it.
        }
      }

      final currencyCode = creds['currencyCode'] ?? 'KES';
      final warehouseCode = creds['warehouseCode'];
      final bplId = creds['bplId'];

      final documentLines = order.cartItems.map((item) {
        final line = {
          "ItemCode": item.productModel.id,
          "Quantity": item.quantity,
          "PriceAfterVAT": item.productModel.price,
          "VatGroup": item.productModel.salesVatGroup ?? 'O1',
        };
        if (warehouseCode != null && warehouseCode.isNotEmpty) {
          line["WarehouseCode"] = warehouseCode;
        }
        return line;
      }).toList();

      final payload = {
        "CardCode": activeCardCode ?? 'LC00050',
        "DocCurrency": currencyCode,
        "DocDate": docDateString,
        "DocDueDate": docDateString,
        "ReserveInvoice": "tYES", 
        "DocumentLines": documentLines,
      };

      if (bplId != null && bplId.isNotEmpty) {
        payload["BPL_IDAssignedToInvoice"] = int.tryParse(bplId) ?? bplId;
      }

      final bodyJson = jsonEncode(payload);

      debugPrint('SapInvoiceDataSource → Sending Invoice payload: $bodyJson');

      final response = await _sapAuthService.client.post(
        url,
        headers: headers,
        body: bodyJson,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('SapInvoiceDataSource → Invoice successfully created in SAP B1!');
        
        final responseData = jsonDecode(response.body);
        final docEntry = responseData['DocEntry'];
        final docTotal = responseData['DocTotal'];
        
        final paymentGlAccount = creds['paymentGlAccount'];
        if (paymentGlAccount != null && paymentGlAccount.toString().isNotEmpty && docEntry != null && docTotal != null) {
          debugPrint('SapInvoiceDataSource → Invoice Response Body: ${response.body}');
          
          final bplIdFromInvoice = responseData['BPL_IDAssignedToInvoice']?.toString() 
                                ?? responseData['BPLID']?.toString() 
                                ?? responseData['BPLId']?.toString();
          
          debugPrint('SapInvoiceDataSource → Detected Branch ID from Invoice: $bplIdFromInvoice');

          await _createIncomingPayment(
            docEntry: docEntry,
            docTotal: docTotal,
            cardCode: activeCardCode ?? 'LC00050',
            docDateString: docDateString,
            currencyCode: currencyCode,
            bplId: bplIdFromInvoice ?? bplId, 
            paymentGlAccount: paymentGlAccount.toString(),
            phoneNumber: order.phone,
            baseUrl: baseUrl,
          );
        }

        // Update local DB to synced
        await _ordersDao.updateSapSyncStatus(order.id, 'synced', docEntry: docEntry);

      } else {
        debugPrint('SapInvoiceDataSource → Failed to create SAP Invoice. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        // Mark as failed for retry
        await _ordersDao.updateSapSyncStatus(order.id, 'failed');
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error communicating with SAP: $e');
      // Mark as failed for retry
      await _ordersDao.updateSapSyncStatus(order.id, 'failed');
    }
  }); // End lock
}

  Future<void> _createIncomingPayment({
    required int docEntry,
    required double docTotal,
    required String cardCode,
    required String docDateString,
    required String currencyCode,
    String? bplId,
    required String paymentGlAccount,
    required String phoneNumber,
    required String baseUrl,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/IncomingPayments');
      
      final payload = {
        "DocType": "rCustomer",
        "CardCode": cardCode,
        "DocDate": docDateString,
        "DocCurrency": currencyCode,
        "TransferAccount": paymentGlAccount,
        "TransferSum": docTotal,
        "TransferReference": phoneNumber,
        "TransferDate": docDateString,
        "Remarks": "Mpesa Payment - $phoneNumber",
        "JournalRemarks": "Mpesa $phoneNumber",
        "PaymentInvoices": [
          {
            "DocEntry": docEntry,
            "SumApplied": docTotal,
            "InvoiceType": "it_Invoice"
          }
        ]
      };

      if (bplId != null && bplId.toString().isNotEmpty) {
        payload["BPLID"] = int.tryParse(bplId.toString()) ?? bplId;
      }

      final bodyJson = jsonEncode(payload);

      debugPrint('SapInvoiceDataSource → Sending IncomingPayment payload: $bodyJson');

      final headers = await _sapAuthService.getHeaders();

      final response = await _sapAuthService.client.post(
        url,
        headers: headers,
        body: bodyJson,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('SapInvoiceDataSource → Incoming Payment successfully created in SAP B1!');
      } else {
        debugPrint('SapInvoiceDataSource → Failed to create Incoming Payment. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error creating Incoming Payment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getInvoices({int skip = 0, String? cardCode}) async {
    try {
      if (!await _sapAuthService.isConfigured()) {
        debugPrint('SapInvoiceDataSource: SAP is not configured.');
        return [];
      }

      final baseUrl = await _sapAuthService.getBaseUrl();
      final headers = await _sapAuthService.getHeaders();
      
      if (!headers.containsKey('Cookie')) {
        debugPrint('SapInvoiceDataSource: No valid SAP session.');
        return [];
      }

      final queryParams = [
        '\$select=DocEntry,DocNum,CardCode,CardName,DocDate,DocTotal,DocumentStatus,DocCurrency',
        '\$orderby=DocNum%20desc',
        '\$top=20',
        '\$skip=$skip',
      ];

      if (cardCode != null && cardCode.isNotEmpty) {
        queryParams.add('\$filter=CardCode%20eq%20\'$cardCode\'');
      }

      final url = Uri.parse('$baseUrl/Invoices?${queryParams.join('&')}');
      debugPrint('SapInvoiceDataSource → Fetching Invoices: $url');

      var response = await _sapAuthService.client.get(
        url,
        headers: headers,
      );

      // Handle session expiration (401 Unauthorized)
      if (response.statusCode == 401) {
        debugPrint(
            'SapInvoiceDataSource → 401 Unauthorized. Retrying with new login...');
        final loginResult = await _sapAuthService.login();
        if (loginResult.success) {
          final newHeaders = await _sapAuthService.getHeaders();
          response = await _sapAuthService.client.get(
            url,
            headers: newHeaders,
          );
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> value = data['value'] ?? [];
        debugPrint(
            'SapInvoiceDataSource → Successfully fetched ${value.length} invoices');
        return List<Map<String, dynamic>>.from(value);
      } else {
        debugPrint(
            'SapInvoiceDataSource → Failed to get SAP Invoices. Status: ${response.statusCode}');
        debugPrint('SapInvoiceDataSource → Response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error getting invoices: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getInvoiceDetails(int docEntry) async {
    try {
      if (!await _sapAuthService.isConfigured()) return null;

      final baseUrl = await _sapAuthService.getBaseUrl();
      final headers = await _sapAuthService.getHeaders();

      if (!headers.containsKey('Cookie')) {
        debugPrint('SapInvoiceDataSource: No valid SAP session.');
        return null;
      }

      final url = Uri.parse('$baseUrl/Invoices($docEntry)');

      var response = await _sapAuthService.client.get(
        url,
        headers: headers,
      );

      // Handle session expiration (401 Unauthorized)
      if (response.statusCode == 401) {
        debugPrint(
            'SapInvoiceDataSource → 401 Unauthorized. Retrying with new login...');
        final loginResult = await _sapAuthService.login();
        if (loginResult.success) {
          final newHeaders = await _sapAuthService.getHeaders();
          response = await _sapAuthService.client.get(
            url,
            headers: newHeaders,
          );
        }
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            'SapInvoiceDataSource → Failed to get Invoice details. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error getting invoice details: $e');
      return null;
    }
  }

  /// NEW: Retries all failed SAP syncs
  Future<void> retryFailedSyncs() async {
    try {
      final failedOrders = await _ordersDao.getFailedSapOrders();
      if (failedOrders.isEmpty) return;

      debugPrint('SapInvoiceDataSource → Retrying ${failedOrders.length} failed SAP syncs...');

      for (final orderEntity in failedOrders) {
        // orderEntity is from Drift (db.Order)
        // We need to fetch items to build a full OrderModel
        final dbItems = await _ordersDao.getItemsForOrder(orderEntity.id);
        
        // Manual mapping to bypass type collision with domain Order
        final orderModel = OrderModel(
          id: orderEntity.id,
          total: orderEntity.totalAmount,
          phone: orderEntity.customerPhone ?? '',
          timestamp: orderEntity.createdAt,
          status: orderEntity.status,
          tenantId: orderEntity.tenantId,
          branchId: orderEntity.branchId,
          terminalId: orderEntity.terminalId,
          sapSyncStatus: orderEntity.sapSyncStatus,
          sapDocEntry: orderEntity.sapDocEntry,
          sapCardCode: orderEntity.sapCardCode,
          cartItems: dbItems.map((item) => CartItemModel(
            productModel: ProductModel(
              id: item.productId,
              name: item.productName,
              price: item.unitPrice,
              brand: '', // Minimal mapping for sync
              category: item.productCategory,
              size: item.productVariant ?? '', 
              description: '', 
              imageUrl: '',
              salesVatGroup: item.salesVatGroup,
            ),
            quantity: item.quantity,
            status: item.status,
          )).toList(),
        );

        // This will naturally wait for the lock
        await syncOrderAsInvoice(orderModel);
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error during retry task: $e');
    }
  }
}


import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sss/core/services/sap_auth_service.dart';
import 'package:sss/features/orders/data/models/order_model.dart';
import 'package:intl/intl.dart';

class SapInvoiceDataSource {
  final SapAuthService _sapAuthService;

  SapInvoiceDataSource(this._sapAuthService);

  Future<void> syncOrderAsInvoice(OrderModel order) async {
    try {
      if (!await _sapAuthService.isConfigured()) {
        debugPrint('SapInvoiceDataSource: SAP is not configured. Skipping sync.');
        return;
      }

      final baseUrl = await _sapAuthService.getBaseUrl();
      final sessionId = await _sapAuthService.getSessionId();
      final routeId = await _sapAuthService.getRouteId();

      if (sessionId == null || sessionId.isEmpty) {
        debugPrint('SapInvoiceDataSource: No valid SAP session. Skipping sync.');
        return;
      }

      final url = Uri.parse('$baseUrl/Invoices');
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final docDateString = dateFormat.format(order.timestamp);

      final creds = await _sapAuthService.loadCredentials();
      final walkInCardCode = creds['walkInCardCode'] ?? 'LC00050';
      final currencyCode = creds['currencyCode'] ?? 'KSH';
      final warehouseCode = creds['warehouseCode'];
      final bplId = creds['bplId'];
      final taxCode = creds['taxCode'] ?? 'O1';

      final documentLines = order.cartItems.map((item) {
        final line = {
          "ItemCode": item.productModel.id,
          "Quantity": item.quantity,
          "Price": item.productModel.price,
          "VatGroup": taxCode,
        };
        if (warehouseCode != null && warehouseCode.isNotEmpty) {
          line["WarehouseCode"] = warehouseCode;
        }
        return line;
      }).toList();

      final payload = {
        "CardCode": walkInCardCode,
        "DocCurrency": currencyCode,
        "DocDate": docDateString,
        "DocDueDate": docDateString,
        "ReserveInvoice": "tYES", // From user sample
        "DocumentLines": documentLines,
      };

      if (bplId != null && bplId.isNotEmpty) {
        payload["BPL_IDAssignedToInvoice"] = int.tryParse(bplId) ?? bplId;
      }

      final bodyJson = jsonEncode(payload);

      // Build Cookie header exactly like product fetcher
      final cookies = <String>[];
      cookies.add('B1SESSION=$sessionId');
      if (routeId != null && routeId.isNotEmpty) {
        cookies.add('ROUTEID=$routeId');
      }

      debugPrint('SapInvoiceDataSource → Sending Invoice payload: $bodyJson');

      final response = await _sapAuthService.client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies.join('; '),
        },
        body: bodyJson,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('SapInvoiceDataSource → Invoice successfully created in SAP B1!');
        
        final responseData = jsonDecode(response.body);
        final docEntry = responseData['DocEntry'];
        final docTotal = responseData['DocTotal'];
        
        // Attempt to create Incoming Payment if a GL Account is configured
        final paymentGlAccount = creds['paymentGlAccount'];
        if (paymentGlAccount != null && paymentGlAccount.toString().isNotEmpty && docEntry != null && docTotal != null) {
          await _createIncomingPayment(
            docEntry: docEntry,
            docTotal: docTotal,
            cardCode: walkInCardCode,
            docDateString: docDateString,
            currencyCode: currencyCode,
            bplId: bplId,
            paymentGlAccount: paymentGlAccount.toString(),
            sessionId: sessionId,
            routeId: routeId,
            baseUrl: baseUrl,
          );
        }

      } else {
        debugPrint('SapInvoiceDataSource → Failed to create SAP Invoice. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error communicating with SAP: $e');
    }
  }

  Future<void> _createIncomingPayment({
    required int docEntry,
    required double docTotal,
    required String cardCode,
    required String docDateString,
    required String currencyCode,
    String? bplId,
    required String paymentGlAccount,
    required String sessionId,
    String? routeId,
    required String baseUrl,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/IncomingPayments');
      
      final payload = {
        "CardCode": cardCode,
        "DocDate": docDateString,
        "DocCurrency": currencyCode,
        "CashAccount": paymentGlAccount,
        "CashSum": docTotal,
        "PaymentInvoices": [
          {
            "DocEntry": docEntry,
            "SumApplied": docTotal,
            "InvoiceType": "it_Invoice"
          }
        ]
      };

      if (bplId != null && bplId.isNotEmpty) {
        payload["BPLID"] = int.tryParse(bplId) ?? bplId;
      }

      final bodyJson = jsonEncode(payload);

      final cookies = <String>['B1SESSION=$sessionId'];
      if (routeId != null && routeId.isNotEmpty) {
        cookies.add('ROUTEID=$routeId');
      }

      debugPrint('SapInvoiceDataSource → Sending IncomingPayment payload: $bodyJson');

      final response = await _sapAuthService.client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': cookies.join('; '),
        },
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
      final sessionId = await _sapAuthService.getSessionId();
      final routeId = await _sapAuthService.getRouteId();

      if (sessionId == null || sessionId.isEmpty) {
        debugPrint('SapInvoiceDataSource: No valid SAP session.');
        return [];
      }

      // Querying invoices with filter and pagination
      String filter = '';
      if (cardCode != null && cardCode.isNotEmpty) {
        filter = "&\$filter=CardCode eq '$cardCode'";
      }

      final url = Uri.parse('$baseUrl/Invoices?\$select=DocEntry,DocNum,CardCode,CardName,DocDate,DocTotal,DocumentStatus,DocCurrency&\$orderby=DocNum desc&\$top=20&\$skip=$skip$filter');

      final cookies = <String>[];
      cookies.add('B1SESSION=$sessionId');
      if (routeId != null && routeId.isNotEmpty) {
        cookies.add('ROUTEID=$routeId');
      }

      final response = await _sapAuthService.client.get(
        url,
        headers: {
          'Cookie': cookies.join('; '),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> value = data['value'] ?? [];
        return List<Map<String, dynamic>>.from(value);
      } else {
        debugPrint('SapInvoiceDataSource → Failed to get SAP Invoices. Status: ${response.statusCode}');
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
      final sessionId = await _sapAuthService.getSessionId();
      final routeId = await _sapAuthService.getRouteId();

      if (sessionId == null || sessionId.isEmpty) return null;

      final url = Uri.parse('$baseUrl/Invoices($docEntry)');

      final cookies = <String>[];
      cookies.add('B1SESSION=$sessionId');
      if (routeId != null && routeId.isNotEmpty) {
        cookies.add('ROUTEID=$routeId');
      }

      final response = await _sapAuthService.client.get(
        url,
        headers: {
          'Cookie': cookies.join('; '),
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('SapInvoiceDataSource → Failed to get Invoice details. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('SapInvoiceDataSource → Error getting invoice details: $e');
      return null;
    }
  }
}


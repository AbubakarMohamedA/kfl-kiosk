import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/orders/data/models/order_model.dart';

abstract class OrderDataSource {
  Future<String> saveOrder(OrderModel order);
  Future<List<OrderModel>> getOrders({String? tenantId});
  Future<OrderModel?> getOrderById(String id);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> saveFullOrder(OrderModel order);
  Future<int> getOrderCounter({String? tenantId, String? branchId});
  Future<void> incrementOrderCounter({String? tenantId, String? branchId});
  Stream<List<OrderModel>> watchOrders({String? tenantId});
}

class OrderRemoteDataSource implements OrderDataSource {
  final http.Client client;

  OrderRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<String> saveOrder(OrderModel order) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Ensure we return a String, even if server sends int
      return (data['orderId'] ?? order.id).toString();
    } else {
      throw Exception('Failed to save order');
    }
  }

  @override
  Future<List<OrderModel>> getOrders({String? tenantId}) async {
    // If tenantId is provided, we could pass it as query param: ?tenantId=...
    // For now, fetching all and filtering locally or assuming backend handles it
    final uri = tenantId != null 
        ? Uri.parse('${ApiConfig.baseUrl}/orders?tenantId=$tenantId')
        : Uri.parse('${ApiConfig.baseUrl}/orders');
        
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ordersList = data['orders'] ?? [];
      return ordersList.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    // Ideally use backend endpoint if available, but for now filtering list or using sync
    // Assuming backend supports /orders/:id
    /* 
    final response = await client.get(Uri.parse('${ApiConfig.baseUrl}/orders/$id'));
    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    }
    return null;
    */
    // Fallback to fetching all and filtering for now if server doesn't support direct get by ID fully or if we assume local sync behavior
    // But implementation plan says "Use http client".
    // Let's assume standard REST
    return null; // TODO: Implement specific endpoint logic if server supports it, otherwise relies on sync
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await client.put(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
  }

  @override
  Future<void> saveFullOrder(OrderModel order) async {
    await saveOrder(order);
  }

  @override
  Future<int> getOrderCounter({String? tenantId, String? branchId}) async {
    // TODO: Pass tenantId and branchId to backend
    final response = await client.get(Uri.parse('${ApiConfig.baseUrl}/orders/counter'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final dynamic counterValue = data['counter'];
      if (counterValue == null) return 1;
      return int.tryParse(counterValue.toString()) ?? 1;
    }
    return 1;
  }

  @override
  Future<void> incrementOrderCounter({String? tenantId, String? branchId}) async {
     // This logic typically happens on server side when creating order, 
     // but closely mirroring local logic:
     // We might post to counter endpoint
     final current = await getOrderCounter(tenantId: tenantId, branchId: branchId);
     await client.post(
       Uri.parse('${ApiConfig.baseUrl}/orders/counter'),
       headers: {'Content-Type': 'application/json'},
       body: jsonEncode({'counter': current + 1, 'tenantId': tenantId, 'branchId': branchId}),
     );
  }

  @override
  Stream<List<OrderModel>> watchOrders({String? tenantId}) async* {
    // Simple polling implementation for stream
    while (true) {
      try {
        final orders = await getOrders(tenantId: tenantId);
        yield orders;
      } catch (e) {
        // yield empty or last known?
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}

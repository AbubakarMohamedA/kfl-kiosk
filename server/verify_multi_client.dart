import 'dart:convert';
import 'dart:io';

void main() async {
  final serverUrl = 'http://127.0.0.1:8080';
  final client = HttpClient();


  // 1. Create Order from Client A
  final orderA = {
    'id': 'order_A_${DateTime.now().millisecondsSinceEpoch}',
    'items': [],
    'total': 100.0,
    'phone': '1234567890',
    'timestamp': DateTime.now().toIso8601String(),
    'status': 'PAID',
    'terminalId': 'Client A',
  };

  await _sendOrder(client, serverUrl, orderA);

  // 2. Create Order from Client B
  final orderB = {
    'id': 'order_B_${DateTime.now().millisecondsSinceEpoch}',
    'items': [],
    'total': 200.0,
    'phone': '0987654321',
    'timestamp': DateTime.now().toIso8601String(),
    'status': 'PAID',
    'terminalId': 'Client B',
  };

  await _sendOrder(client, serverUrl, orderB);

  // 3. Fetch Orders and Verify
  final orders = await _getOrders(client, serverUrl);

  
  final receivedOrderA = orders.firstWhere((o) => o['id'] == orderA['id'], orElse: () => null);
  final receivedOrderB = orders.firstWhere((o) => o['id'] == orderB['id'], orElse: () => null);

  if (receivedOrderA != null && receivedOrderA['terminalId'] == 'Client A') {
  } else {
  }

  if (receivedOrderB != null && receivedOrderB['terminalId'] == 'Client B') {
  } else {
  }

  client.close();
}

Future<void> _sendOrder(HttpClient client, String baseUrl, Map<String, dynamic> order) async {
  final request = await client.postUrl(Uri.parse('$baseUrl/orders'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(order));
  final response = await request.close();
  if (response.statusCode != 200) {
  }
}

Future<List<dynamic>> _getOrders(HttpClient client, String baseUrl) async {
  final request = await client.getUrl(Uri.parse('$baseUrl/orders'));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  final data = jsonDecode(body);
  return data['orders'];
}

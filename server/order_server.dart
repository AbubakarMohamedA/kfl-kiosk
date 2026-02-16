import 'dart:convert';
import 'dart:io';

/// Simple HTTP Server for Order Sync
/// 
/// Run this on your desktop machine to sync orders between devices.
/// Usage: dart run server/order_server.dart
/// 
/// Endpoints:
///   GET  /orders          - Get all orders
///   POST /orders          - Add a new order
///   PUT  /orders/:id      - Update an order
///   DELETE /orders/:id    - Delete an order
///   GET  /orders/counter  - Get order counter
///   POST /orders/counter  - Set order counter

// In-memory order storage
List<Map<String, dynamic>> orders = [];
Map<String, int> counterMap = {}; // Maps "tenantId_yyyyMMdd" -> count
int orderCounter = 1; // Legacy/Global fallback

void main() async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4, // Listen on all interfaces
    8080,
    shared: true,
  );
  
  // Get local IP addresses for display
  final interfaces = await NetworkInterface.list();
  final ips = interfaces
      .expand((interface) => interface.addresses)
      .where((addr) => addr.type == InternetAddressType.IPv4)
      .map((addr) => addr.address)
      .toList();
  
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║           SSS Kiosk Order Sync Server Started                ║');
  print('╠══════════════════════════════════════════════════════════════╣');
  print('║ Server running on port 8080                                  ║');
  print('║                                                              ║');
  print('║ Connect your devices using one of these addresses:          ║');
  for (final ip in ips) {
    print('║   http://$ip:8080'.padRight(63) + '║');
  }
  print('║                                                              ║');
  print('║ In the app, set the server URL in Settings.                 ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
  print('Waiting for connections...');
  print('');

  await for (final request in server) {
    // Enable CORS
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    request.response.headers.contentType = ContentType.json;

    // Handle preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;
    final method = request.method;
    
    try {
      // GET /orders - List all orders
      if (method == 'GET' && path == '/orders') {
        print('[${DateTime.now()}] GET /orders - Returning ${orders.length} orders');
        request.response.write(jsonEncode({
          'orders': orders, 
          'counter': orderCounter,
          'counters': counterMap,
        }));
      }
      // POST /orders - Add new order
      else if (method == 'POST' && path == '/orders') {
        final body = await utf8.decoder.bind(request).join();
        final order = jsonDecode(body) as Map<String, dynamic>;
        
        // Check if order already exists
        final existingIndex = orders.indexWhere((o) => o['id'] == order['id']);
        if (existingIndex != -1) {
          orders[existingIndex] = order;
          print('[${DateTime.now()}] POST /orders - Updated order ${order['id']}');
        } else {
          orders.add(order);
          print('[${DateTime.now()}] POST /orders - Added order ${order['id']}');
        }
        
        request.response.write(jsonEncode({'success': true, 'orderId': order['id']}));
      }
      // PUT /orders/:id - Update order
      else if (method == 'PUT' && path.startsWith('/orders/')) {
        final orderId = path.split('/').last;
        final body = await utf8.decoder.bind(request).join();
        final updates = jsonDecode(body) as Map<String, dynamic>;
        
        final index = orders.indexWhere((o) => o['id'] == orderId);
        if (index != -1) {
          orders[index] = {...orders[index], ...updates};
          print('[${DateTime.now()}] PUT /orders/$orderId - Updated');
          request.response.write(jsonEncode({'success': true}));
        } else {
          request.response.statusCode = 404;
          request.response.write(jsonEncode({'error': 'Order not found'}));
        }
      }
      // DELETE /orders/:id - Delete order
      else if (method == 'DELETE' && path.startsWith('/orders/')) {
        final orderId = path.split('/').last;
        orders.removeWhere((o) => o['id'] == orderId);
        print('[${DateTime.now()}] DELETE /orders/$orderId - Deleted');
        request.response.write(jsonEncode({'success': true}));
      }
      // GET /orders/counter - Get counter
      else if (method == 'GET' && path == '/orders/counter') {
        request.response.write(jsonEncode({
          'counter': orderCounter,
          'counters': counterMap,
        }));
      }
      // POST /orders/counter - Set counter
      else if (method == 'POST' && path == '/orders/counter') {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        
        if (data.containsKey('key') && data.containsKey('counter')) {
          final String key = data['key'];
          final int count = data['counter'];
          counterMap[key] = count;
          print('[${DateTime.now()}] POST /orders/counter - Set $key to $count');
        } else {
          orderCounter = data['counter'] ?? orderCounter;
          print('[${DateTime.now()}] POST /orders/counter - Set global to $orderCounter');
        }
        
        request.response.write(jsonEncode({
          'success': true, 
          'counter': orderCounter,
          'counters': counterMap,
        }));
      }
      // DELETE /orders - Clear all orders
      else if (method == 'DELETE' && path == '/orders') {
        orders.clear();
        print('[${DateTime.now()}] DELETE /orders - Cleared all orders');
        request.response.write(jsonEncode({'success': true}));
      }
      // Health check
      else if (method == 'GET' && path == '/health') {
        request.response.write(jsonEncode({
          'status': 'ok',
          'ordersCount': orders.length,
          'counter': orderCounter,
          'countersCount': counterMap.length,
        }));
      }
      // Not found
      else {
        request.response.statusCode = 404;
        request.response.write(jsonEncode({'error': 'Not found'}));
      }
    } catch (e) {
      print('[${DateTime.now()}] ERROR: $e');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'error': e.toString()}));
    }

    await request.response.close();
  }
}

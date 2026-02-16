import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/features/orders/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Network-based Order Data Source
/// 
/// Connects to a local HTTP server for cross-device order sync.
/// Falls back to local storage if server is unavailable.
import 'package:kfm_kiosk/features/orders/data/datasources/order_remote_datasource.dart';

class LocalOrderDataSource implements OrderDataSource {
  static const String _serverUrlKey = 'kfl_server_url';
  static const String _ordersKey = 'kfl_orders';
  static const String _orderCounterKey = 'kfl_order_counter';
  
  // Server URL (configurable via settings)
  String? _serverUrl;
  
  // In-memory cache
  List<OrderModel> _ordersCache = [];
  Map<String, int> _orderCounters = {}; // Maps "tenantId_yyyyMMdd" -> count
  bool _isInitialized = false;
  bool _isOnline = false;

  // Stream controller for real-time order updates
  final _ordersStreamController = StreamController<List<OrderModel>>.broadcast();

  // Polling timer for sync
  Timer? _syncTimer;

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

  /// Get current server URL
  String? get serverUrl => _serverUrl;

  /// Set server URL
  Future<void> setServerUrl(String? url) async {
    _serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString(_serverUrlKey, url);
    } else {
      await prefs.remove(_serverUrlKey);
    }
    // Force resync
    await _syncWithServer();
  }

  /// Initialize the data source
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load server URL
    _serverUrl = prefs.getString(_serverUrlKey);
    
    // Load order counters from local storage
    final countersJson = prefs.getString(_orderCounterKey);
    if (countersJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(countersJson);
        _orderCounters = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        _orderCounters = {};
      }
    } else {
        // Migration or fallback: preserve old counter if it makes sense, 
        // but user requested daily reset per tenant. 
        // We'll start fresh or migrate if needed. Starting fresh for now.
        _orderCounters = {};
    }
    
    // Load orders from local storage (fallback)
    final ordersJson = prefs.getString(_ordersKey);
    if (ordersJson != null) {
      try {
        final List<dynamic> ordersList = jsonDecode(ordersJson);
        _ordersCache = ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _ordersCache = [];
      }
    }
    
    _isInitialized = true;
    
    // Start sync polling
    _startSyncPolling();
    
    // Initial sync
    await _syncWithServer();
    
    // Emit initial state
    _ordersStreamController.add(List.from(_ordersCache));
  }

  /// Start polling for server updates
  void _startSyncPolling() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _syncWithServer();
    });
  }

  /// Sync orders with server
  Future<void> _syncWithServer() async {
    if (_serverUrl == null || _serverUrl!.isEmpty) {
      _isOnline = false;
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/orders'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ordersList = data['orders'] ?? [];
        final newOrders = ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        /* 
        // TODO: Update server sync logic for new map-based counters
        final serverCounter = data['counter'] ?? _orderCounter;
        if (serverCounter > _orderCounter) {
          _orderCounter = serverCounter;
          await _persistCounter();
        }
        */

        // Update cache if orders changed
        if (_hasOrdersChanged(newOrders)) {
          _ordersCache = newOrders;
          await _persistOrders();
          _ordersStreamController.add(List.from(_ordersCache));
        }
        
        _isOnline = true;
      } else {
        _isOnline = false;
      }
    } catch (e) {
      _isOnline = false;
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

  /// Persist orders to local storage
  Future<void> _persistOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = jsonEncode(_ordersCache.map((o) => o.toJson()).toList());
    await prefs.setString(_ordersKey, ordersJson);
  }

  /// Persist order counters
  Future<void> _persistCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderCounterKey, jsonEncode(_orderCounters));
  }

  /// Send order to server
  Future<void> _sendToServer(OrderModel order) async {
    if (_serverUrl == null || _serverUrl!.isEmpty) {
      print('[LocalOrderDataSource] skipping sync: serverUrl is null/empty');
      return;
    }

    print('[LocalOrderDataSource] Sending order ${order.id} to $_serverUrl/orders');
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(order.toJson()),
      ).timeout(const Duration(seconds: 3));
      print('[LocalOrderDataSource] Server response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('[LocalOrderDataSource] Error sending order to server: $e');
      // Ignore errors - order is saved locally
    }
  }

  /// Update order on server
  Future<void> _updateOnServer(String orderId, Map<String, dynamic> data) async {
    if (_serverUrl == null || _serverUrl!.isEmpty) return;

    try {
      await http.put(
        Uri.parse('$_serverUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      // Ignore errors
    }
  }

  // Create/Save order
  @override
  Future<String> saveOrder(OrderModel order) async {
    await _ensureInitialized();

    _ordersCache.add(order);
    await _persistOrders();
    await _sendToServer(order);
    _ordersStreamController.add(List.from(_ordersCache));

    return order.id;
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

    final index = _ordersCache.indexWhere((order) => order.id == orderId);

    if (index != -1) {
      final order = _ordersCache[index];
      _ordersCache[index] = OrderModel(
        id: order.id,
        cartItems: order.cartItems,
        total: order.total,
        phone: order.phone,
        timestamp: order.timestamp,
        status: status,
      );

      await _persistOrders();
      await _updateOnServer(orderId, {'status': status});
      _ordersStreamController.add(List.from(_ordersCache));
    }
  }

  // Save full order
  @override
  Future<void> saveFullOrder(OrderModel orderModel) async {
    await _ensureInitialized();

    final index = _ordersCache.indexWhere((order) => order.id == orderModel.id);

    if (index != -1) {
      _ordersCache[index] = orderModel;
      await _persistOrders();
      await _sendToServer(orderModel);
      _ordersStreamController.add(List.from(_ordersCache));
    }
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
  Future<int> getOrderCounter({String? tenantId}) async {
    await _ensureInitialized();
    final key = _getCounterKey(tenantId);
    final count = (_orderCounters[key] ?? 0) + 1;
    print('[LocalOrderDataSource] getOrderCounter for $key: $count');
    return count;
  }

  // Increment order counter
  @override
  Future<void> incrementOrderCounter({String? tenantId}) async {
    await _ensureInitialized();
    final key = _getCounterKey(tenantId);
    final current = _orderCounters[key] ?? 0;
    _orderCounters[key] = current + 1;
    print('[LocalOrderDataSource] incrementOrderCounter for $key to ${_orderCounters[key]}');
    await _persistCounter();
    
    // Sync counter with server (simplified for now, ideally sync map)
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$_serverUrl/orders/counter'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tenantId': tenantId,
            'key': key,
            'counter': _orderCounters[key]
          }),
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        print('[LocalOrderDataSource] Error syncing counter: $e');
        // Ignore
      }
    }
  }

  String _getCounterKey(String? tenantId) {
    // If no tenant (e.g. legacy/admin), use "default"
    // Format: tenantId_yyyyMMdd
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final tId = tenantId ?? "default";
    return "${tId}_$dateStr";
  }


  // Delete order
  Future<void> deleteOrder(String orderId) async {
    await _ensureInitialized();

    _ordersCache.removeWhere((order) => order.id == orderId);
    await _persistOrders();
    
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('$_serverUrl/orders/$orderId'),
        ).timeout(const Duration(seconds: 3));
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
    await _ensureInitialized();

    _ordersCache.clear();
    await _persistOrders();
    
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('$_serverUrl/orders'),
        ).timeout(const Duration(seconds: 3));
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
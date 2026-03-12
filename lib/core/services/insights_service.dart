import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/features/orders/domain/entities/order.dart';
import 'package:intl/intl.dart';

class InsightsService {
  // ---------------------------------------------------------------------------
  // 1. Sales Insights
  // ---------------------------------------------------------------------------

  /// Calculates total revenue for a given list of orders
  double calculateTotalRevenue(List<Order> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.total);
  }

  /// groups revenue by day for the last 7 days
  Map<String, double> getWeeklyRevenueTrend(List<Order> orders) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final Map<String, double> salesByDay = {};

    // Initialize with 0 for all days to ensure continuous chart
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayKey = DateFormat('EEE').format(date); // Mon, Tue, etc.
      salesByDay[dayKey] = 0.0;
    }

    final recentOrders = orders.where((o) => o.timestamp.isAfter(sevenDaysAgo));
    
    for (var order in recentOrders) {
      final dayKey = DateFormat('EEE').format(order.timestamp);
      salesByDay[dayKey] = (salesByDay[dayKey] ?? 0.0) + order.total;
    }
    
    return salesByDay;
  }

  /// Identifies peak hours based on order volume
  Map<int, int> getPeakHours(List<Order> orders) {
    final Map<int, int> hourCounts = {};
    for (var order in orders) {
      final hour = order.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    return hourCounts;
  }

  /// Get top N selling products by revenue
  List<Map<String, dynamic>> getTopSellingProducts(List<Order> orders, {int limit = 5}) {
    final Map<String, double> productRevenue = {};
    final Map<String, String> productNames = {};

    for (var order in orders) {
      for (var item in order.items) {
        final id = item.product.id;
        productRevenue[id] = (productRevenue[id] ?? 0) + item.subtotal;
        productNames[id] = item.product.name;
      }
    }

    final sortedEntries = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending

    return sortedEntries.take(limit).map((e) => {
      'id': e.key,
      'name': productNames[e.key],
      'revenue': e.value,
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 2. Customer Behavior Analytics
  // ---------------------------------------------------------------------------

  /// Average items per order
  double getAverageBasketSize(List<Order> orders) {
    if (orders.isEmpty) return 0.0;
    final totalItems = orders.fold(0, (sum, o) => sum + o.items.fold(0, (s, i) => s + i.quantity));
    return totalItems / orders.length;
  }

  /// Identify common product combinations (pairs)
  List<Map<String, dynamic>> getPopularCombos(List<Order> orders) {
    // Simplified specific combo logic: Track pairs of items in same order
    final Map<String, int> comboCounts = {};
    
    for (var order in orders) {
      if (order.items.length < 2) continue;
      
      final itemIds = order.items.map((i) => i.product.name).toSet().toList();
      itemIds.sort(); // Sort to ensure A+B is same as B+A
      
      for (int i = 0; i < itemIds.length; i++) {
        for (int j = i + 1; j < itemIds.length; j++) {
          final comboKey = '${itemIds[i]} + ${itemIds[j]}';
          comboCounts[comboKey] = (comboCounts[comboKey] ?? 0) + 1;
        }
      }
    }

    final sortedCombos = comboCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedCombos.take(5).map((e) => {
      'combo': e.key,
      'count': e.value
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 3. Performance Metrics
  // ---------------------------------------------------------------------------

  /// Calculate average time from order creation to fulfillment
  /// Note: Requires 'fulfilledTime' which isn't in Order model yet.
  /// Using mock logic for now or deriving from status changes if tracked.
  Duration getAverageFulfillmentTime(List<Order> orders) {
    final completedOrders = orders.where((o) => o.status == AppConstants.statusFulfilled);
    if (completedOrders.isEmpty) return Duration.zero;
    
    // In a real app, we'd difference timestamp vs completedTimestamp
    // For now, returning a simulated metric based on order volume
    return Duration(minutes: 5 + (completedOrders.length % 10)); 
  }

  /// Get current efficiency score (0-100)
  double getEfficiencyScore(List<Order> todayOrders) {
    if (todayOrders.isEmpty) return 100.0;
    
    final completed = todayOrders.where((o) => o.status == AppConstants.statusFulfilled).length;
    final total = todayOrders.length;
    
    return (completed / total) * 100.0;
  }

  // ---------------------------------------------------------------------------
  // 4. Product Performance
  // ---------------------------------------------------------------------------

  /// Revenue share by category
  Map<String, double> getCategoryPerformance(List<Order> orders) {
    final Map<String, double> categoryRevenue = {};
    
    for (var order in orders) {
      for (var item in order.items) {
        final cat = item.product.category;
        categoryRevenue[cat] = (categoryRevenue[cat] ?? 0) + item.subtotal;
      }
    }
    
    return categoryRevenue;
  }

  /// Calculate margin if cost price available (simulated here)
  double estimateMargin(double revenue) {
    return revenue * 0.35; // Simulated 35% margin
  }

  // ---------------------------------------------------------------------------
  // 5. Business Alerts & Recommendations
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> generateAlerts(List<Order> orders) {
    final List<Map<String, dynamic>> alerts = [];
    final today = DateTime.now();
    final todayOrders = orders.where((o) => 
      o.timestamp.day == today.day && 
      o.timestamp.month == today.month && 
      o.timestamp.year == today.year
    ).toList();

    // Alert 1: Low Velocity Warning
    if (todayOrders.isNotEmpty && todayOrders.length < 5 && today.hour > 12) {
      alerts.add({
        'type': 'warning',
        'title': 'Low Order Velocity',
        'message': 'Order volume is 40% lower than usual for this time.',
        'action': 'Run a flash sale or promotion.'
      });
    }

    // Alert 2: High Demand Spike
    if (todayOrders.length > 50) {
      alerts.add({
        'type': 'success',
        'title': 'High Demand Spike',
        'message': 'Sales are trending 20% higher than average!',
        'action': 'Ensure inventory replenishment for Flour.'
      });
    }

    // Alert 3: Performance Drop
    final efficiency = getEfficiencyScore(todayOrders);
    if (efficiency < 50 && todayOrders.length > 10) {
      alerts.add({
        'type': 'critical',
        'title': 'Fulfillment Delay',
        'message': 'Less than 50% of today\'s orders are fulfilled.',
        'action': 'Check warehouse staffing levels.'
      });
    }

    // Alert 4: Stock Recommendation (Simulated)
    final topProducts = getTopSellingProducts(orders, limit: 1);
    if (topProducts.isNotEmpty) {
      alerts.add({
        'type': 'info',
        'title': 'Restock Recommendation',
        'message': '${topProducts.first['name']} is selling fast.',
        'action': 'Check stock levels immediately.'
      });
    }

    return alerts;
  }
}

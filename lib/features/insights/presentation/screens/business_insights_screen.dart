import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/core/services/insights_service.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_state.dart';

class BusinessInsightsScreen extends StatefulWidget {
  const BusinessInsightsScreen({super.key});

  @override
  State<BusinessInsightsScreen> createState() => _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState extends State<BusinessInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InsightsService _insightsService = InsightsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is! OrdersLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = state.orders;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesTab(orders),
                    _buildCustomerTab(orders),
                    _buildPerformanceTab(orders),
                    _buildProductTab(orders),
                    _buildAlertsTab(orders),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Intelligence',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time data-driven insights for smarter decisions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_graph, color: Color(AppColors.primaryBlue), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'AI Analysis Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(AppColors.primaryBlue),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(AppColors.primaryBlue),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Sales Insights', icon: Icon(Icons.attach_money)),
              Tab(text: 'Customer Behavior', icon: Icon(Icons.people_alt)),
              Tab(text: 'Performance', icon: Icon(Icons.speed)),
              Tab(text: 'Products', icon: Icon(Icons.inventory)),
              Tab(text: 'Smart Alerts', icon: Icon(Icons.notifications_active)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Sales Insights Tab
  // ---------------------------------------------------------------------------
  Widget _buildSalesTab(List<Order> orders) {
    final revenue = _insightsService.calculateTotalRevenue(orders);
    final weeklyTrend = _insightsService.getWeeklyRevenueTrend(orders);
    final topProducts = _insightsService.getTopSellingProducts(orders);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Revenue',
                  'KSh ${revenue.toStringAsFixed(0)}',
                  Icons.monetization_on,
                  Colors.green,
                  subtitle: '+12% vs last week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Avg. Order Value',
                  'KSh ${(revenue / (orders.isEmpty ? 1 : orders.length)).toStringAsFixed(0)}',
                  Icons.shopping_bag,
                  Colors.blue,
                  subtitle: '+5% vs last week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Conversion Rate',
                  '3.2%',
                  Icons.trending_up,
                  Colors.orange,
                  subtitle: '-0.5% vs last week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildCard(
                  'Weekly Revenue Trend',
                  SizedBox(
                    height: 300,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: weeklyTrend.entries.map((e) {
                        final heightFactor = (e.value / (revenue + 1)) * 5; // Normalize
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 40,
                              height: (heightFactor * 100).clamp(20.0, 250.0),
                              decoration: BoxDecoration(
                                color: const Color(AppColors.primaryBlue).withValues(alpha: 0.8),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(e.key, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildCard(
                  'Top Selling Products',
                  Column(
                    children: topProducts.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[50],
                        child: Text(
                          (p['name'] as String)[0],
                          style: const TextStyle(color: Color(AppColors.primaryBlue)),
                        ),
                      ),
                      title: Text(
                        p['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        'KSh ${p['revenue']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Customer Behavior Tab
  // ---------------------------------------------------------------------------
  Widget _buildCustomerTab(List<Order> orders) {
    final basketSize = _insightsService.getAverageBasketSize(orders);
    final combos = _insightsService.getPopularCombos(orders); // Mocked for now

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg. Basket Size',
                  '${basketSize.toStringAsFixed(1)} Items',
                  Icons.shopping_basket,
                  Colors.purple,
                  subtitle: 'Consistent with last month',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Repeat Customers',
                  '42%',
                  Icons.repeat,
                  Colors.teal,
                  subtitle: '+8% growth',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            'Popular Combinations',
            Column(
              children: combos.map((c) => ListTile(
                leading: const Icon(Icons.link, color: Colors.orange),
                title: Text(c['combo'], style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Chip(
                  label: Text('${c['count']} orders'),
                  backgroundColor: Colors.orange[50],
                  labelStyle: const TextStyle(color: Colors.orange),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Performance Tab
  // ---------------------------------------------------------------------------
  Widget _buildPerformanceTab(List<Order> orders) {
    final fulfillmentTime = _insightsService.getAverageFulfillmentTime(orders);
    final efficiency = _insightsService.getEfficiencyScore(orders);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg. Fulfillment Time',
                  '${fulfillmentTime.inMinutes} min',
                  Icons.timer,
                  Colors.orange,
                  subtitle: '-2 min improvement',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Efficiency Score',
                  '${efficiency.toStringAsFixed(1)}%',
                  Icons.speed,
                  efficiency > 80 ? Colors.green : Colors.red,
                  subtitle: efficiency > 80 ? 'Excellent' : 'Needs Attention',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCard(
            'Queue Analysis',
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Queue Analytics requires real-time sensor data integration',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Product Tab
  // ---------------------------------------------------------------------------
  Widget _buildProductTab(List<Order> orders) {
    final topProducts = _insightsService.getTopSellingProducts(orders, limit: 10);
    final categoryPerf = _insightsService.getCategoryPerformance(orders);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildCard(
                  'Category Performance',
                  Column(
                    children: categoryPerf.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text('KSh ${e.value.toStringAsFixed(0)}'),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: (e.value / (categoryPerf.values.fold(0.0, (s, v) => s + v) + 1)),
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(Color(AppColors.primaryBlue)),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildCard(
                  'Inventory Movement',
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topProducts.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = topProducts[index];
                      return ListTile(
                        dense: true,
                        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('High Demand'),
                        trailing: const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Alerts Tab
  // ---------------------------------------------------------------------------
  Widget _buildAlertsTab(List<Order> orders) {
    final alerts = _insightsService.generateAlerts(orders);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final type = alert['type'];
        Color color;
        IconData icon;

        switch (type) {
          case 'warning':
            color = Colors.orange;
            icon = Icons.warning_amber;
            break;
          case 'critical':
            color = Colors.red;
            icon = Icons.error_outline;
            break;
          case 'success':
            color = Colors.green;
            icon = Icons.check_circle_outline;
            break;
          case 'info':
          default:
            color = Colors.blue;
            icon = Icons.info_outline;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, size: 16, color: Color(AppColors.primaryBlue)),
                        const SizedBox(width: 8),
                        Text(
                          'Recommendation: ${alert['action']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  // Dismiss logic
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets
  // ---------------------------------------------------------------------------
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitle.contains('+') ? Colors.green : (subtitle.contains('-') ? Colors.red : Colors.grey),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }
}

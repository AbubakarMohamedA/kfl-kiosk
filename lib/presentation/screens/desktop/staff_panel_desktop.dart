import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_state.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/presentation/widgets/desktop/staff_order_card.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/home_screen_desktop.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

class StaffPanelDesktop extends StatefulWidget {
  const StaffPanelDesktop({super.key});

  @override
  State<StaffPanelDesktop> createState() => _StaffPanelDesktopState();
}

class _StaffPanelDesktopState extends State<StaffPanelDesktop> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late Timer _autoRefreshTimer;
  late Timer _clockTimer;
  
  String _selectedFilter = 'all';
  bool _showHistory = false;
  bool _isDarkMode = false;
  DateTime _currentTime = DateTime.now();
  int _paidOrdersCount = 0; // Track paid orders count
  
  // Analytics data
  int _peakHourOrders = 0;
  double _averagePrepTime = 0.0;
  List<Map<String, dynamic>> _hourlyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Silent auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_showHistory) {
        // Silent refresh - no setState, just reload data in background
        context.read<OrderBloc>().add(const LoadOrders());
      }
    });
    
    // Update clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    
    _generateMockAnalytics();
  }

  void _generateMockAnalytics() {
    // Generate hourly data for the day
    final _ = DateTime.now();
    _hourlyData = List.generate(24, (index) {
      return {
        'hour': index,
        'orders': math.Random().nextInt(20) + 5,
        'revenue': (math.Random().nextDouble() * 5000) + 1000,
      };
    });
    
    _peakHourOrders = _hourlyData.map((e) => e['orders'] as int).reduce(math.max);
    _averagePrepTime = 8.5 + (math.Random().nextDouble() * 6);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _autoRefreshTimer.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F1419) : Colors.grey[50],
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          // Update paid orders count silently without triggering full rebuild
          if (state is OrdersLoaded) {
            final newPaidCount = state.paidCount;
            if (_paidOrdersCount != newPaidCount) {
              // Only update if count changed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _paidOrdersCount = newPaidCount;
                  });
                }
              });
            }
          }
        },
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        if (!_showHistory) ...[
                          _buildDashboardTitle(),
                          _buildSearchAndFilterBar(),
                        ] else ...[
                          _buildHistoryHeader(),
                        ],
                        Expanded(
                          child: _showHistory 
                              ? _buildEnhancedHistoryView() 
                              : _buildEnhancedOrdersView(),
                        ),
                      ],
                    ),
                  ),
                  _buildRightPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode 
              ? [const Color(0xFF1a237e), const Color(0xFF083E22)]
              : [const Color(AppColors.primaryBlue), const Color(0xFF0A6F38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo and Title
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha:0.2)),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded, 
              size: 32, 
              color: Colors.white
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Staff Command Center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_currentTime),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha:0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // Live Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha:0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha:0.9), size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm:ss').format(_currentTime),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Theme Toggle
          _buildHeaderIconButton(
            icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 12),
          
          // Manual Refresh Button (optional - for user-triggered refresh)
          _buildHeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Data',
            onPressed: () => context.read<OrderBloc>().add(const LoadOrders()),
          ),
          const SizedBox(width: 12),
          
          // Notifications - Show count of paid orders
          _buildHeaderIconButton(
            icon: Icons.notifications_outlined,
            tooltip: 'New Orders (Paid)',
            badge: _paidOrdersCount > 0 ? '$_paidOrdersCount' : null,
            onPressed: () => _showNotificationsDialog(),
          ),
          const SizedBox(width: 12),
          
          // Settings
          _buildHeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    String? badge,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        children: [
          Material(
            color: Colors.white.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          right: BorderSide(
            color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildSidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: !_showHistory,
            onTap: () => setState(() => _showHistory = false),
          ),
          _buildSidebarItem(
            icon: Icons.history_rounded,
            label: 'Order History',
            isSelected: _showHistory,
            onTap: () => setState(() => _showHistory = true),
          ),
          _buildSidebarItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            onTap: () => _showAnalyticsDialog(),
          ),
          _buildSidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.people_outline,
            label: 'Staff Management',
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSidebarItem(
            icon: Icons.storefront_rounded,
            label: 'Customer Kiosk',
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => const HomeScreenDesktop(),
              );
            },
          ),
          const Spacer(),
          
          // Quick Stats in Sidebar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(AppColors.primaryBlue).withValues(alpha:0.1),
                  const Color(AppColors.primaryBlue).withValues(alpha:0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(AppColors.primaryBlue).withValues(alpha:0.2),
              ),
            ),
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrdersLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Overview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSidebarStat('Orders', '${state.todaysOrderCount}'),
                      _buildSidebarStat('Revenue', 'KSh ${state.todaysSales.toStringAsFixed(0)}'),
                      _buildSidebarStat('Active', '${state.paidCount + state.preparingCount + state.readyCount}'),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected 
            ? const Color(AppColors.primaryBlue).withValues(alpha:0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected 
                      ? const Color(AppColors.primaryBlue)
                      : (_isDarkMode ? Colors.white70 : Colors.grey[600]),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                        ? const Color(AppColors.primaryBlue)
                        : (_isDarkMode ? Colors.white70 : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.white60 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          left: BorderSide(
            color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Live Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrdersLoaded) {
                  final completedToday = state.orders.where((o) => 
                    o.status == AppConstants.statusFulfilled && 
                    _isToday(o.timestamp)
                  ).length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInsightCard(
                          'Order Flow',
                          'Real-time status',
                          Icons.waterfall_chart,
                          Colors.blue,
                          [
                            _buildInsightRow('Paid', state.paidCount, Colors.blue),
                            _buildInsightRow('Preparing', state.preparingCount, Colors.orange),
                            _buildInsightRow('Ready', state.readyCount, Colors.purple),
                            _buildInsightRow('Completed', completedToday, Colors.green),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInsightCard(
                          'Performance',
                          'Today\'s metrics',
                          Icons.speed,
                          Colors.green,
                          [
                            _buildInsightRow('Completion Rate', 
                              state.todaysOrderCount > 0 
                                  ? '${((completedToday / state.todaysOrderCount) * 100).toStringAsFixed(0)}%'
                                  : '0%', 
                              Colors.green),
                            _buildInsightRow('Avg Prep Time', '${_averagePrepTime.toStringAsFixed(1)} min', Colors.teal),
                            _buildInsightRow('Peak Hour', '$_peakHourOrders orders', Colors.indigo),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInsightCard(
                          'Revenue',
                          'Financial summary',
                          Icons.attach_money,
                          Colors.green,
                          [
                            _buildInsightRow('Today', 'KSh ${state.todaysSales.toStringAsFixed(0)}', Colors.green),
                            _buildInsightRow('Avg Order', 
                              state.todaysOrderCount > 0 
                                  ? 'KSh ${(state.todaysSales / state.todaysOrderCount).toStringAsFixed(0)}'
                                  : 'KSh 0', 
                              Colors.blue),
                            _buildInsightRow('Orders', '${state.todaysOrderCount}', Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTrendChart(state),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(OrdersLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hourly Trends',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: SimpleTrendChartPainter(
                data: _hourlyData,
                isDarkMode: _isDarkMode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTitle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: const Color(AppColors.primaryBlue),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Active Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode 
                      ? Colors.white.withValues(alpha:0.1)
                      : Colors.grey[300]!,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<OrderBloc>().add(SearchOrders(value));
                },
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Order ID or Phone Number...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(AppColors.primaryBlue),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<OrderBloc>().add(const SearchOrders(''));
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Filter Dropdown
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode 
                      ? Colors.white.withValues(alpha:0.1)
                      : Colors.grey[300]!,
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
                dropdownColor: _isDarkMode ? const Color(0xFF252b3b) : Colors.white,
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded, size: 18, color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                        const SizedBox(width: 12),
                        const Text('All Orders'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPaid,
                    child: Row(
                      children: [
                        Icon(Icons.payment_rounded, size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Paid'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPreparing,
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Preparing'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusReadyForPickup,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.purple),
                        const SizedBox(width: 12),
                        const Text('Ready'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFilter = value);
                    context.read<OrderBloc>().add(FilterOrders(value));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOrdersView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final activeOrders = state.filteredActiveOrders;

          if (activeOrders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Active Orders',
              subtitle: _selectedFilter != 'all' 
                  ? 'No orders match the selected filter'
                  : 'All orders have been completed!',
            );
          }

          // List view only - removed grid view
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final order = activeOrders[activeOrders.length - 1 - index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaffOrderCard(
                  order: order,
                  onStartPreparing: () {
                    context.read<OrderBloc>().add(UpdateOrderStatus(
                      orderId: order.id,
                      status: AppConstants.statusPreparing,
                    ));
                  },
                  onMarkReady: () {
                    context.read<OrderBloc>().add(UpdateOrderStatus(
                      orderId: order.id,
                      status: AppConstants.statusReadyForPickup,
                    ));
                  },
                  onMarkFulfilled: () {
                    context.read<OrderBloc>().add(UpdateOrderStatus(
                      orderId: order.id,
                      status: AppConstants.statusFulfilled,
                    ));
                    _showSuccessSnackBar(order.id);
                  },
                ),
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildHistoryHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white.withValues(alpha:0.1) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: const Color(AppColors.primaryBlue),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Order History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDarkMode 
                          ? Colors.white.withValues(alpha:0.1)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => context.read<OrderBloc>().add(SearchOrders(value)),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search completed orders...',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(AppColors.primaryBlue),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                context.read<OrderBloc>().add(const SearchOrders(''));
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppColors.primaryBlue).withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  onPressed: () => _showAdvancedFilters(),
                  tooltip: 'Advanced Filters',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHistoryView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final completedOrders = state.orders
              .where((order) => order.status == AppConstants.statusFulfilled)
              .toList();

          if (completedOrders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.history,
              title: 'No Order History',
              subtitle: 'Completed orders will appear here',
            );
          }

          final groupedOrders = <String, List<dynamic>>{};
          for (var order in completedOrders) {
            final dateKey = DateFormat('yyyy-MM-dd').format(order.timestamp);
            groupedOrders.putIfAbsent(dateKey, () => []).add(order);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: groupedOrders.length,
            itemBuilder: (context, index) {
              final dateKey = groupedOrders.keys.toList()[groupedOrders.length - 1 - index];
              final ordersForDate = groupedOrders[dateKey]!;
              final date = DateTime.parse(dateKey);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(date, ordersForDate.length),
                  const SizedBox(height: 16),
                  ...ordersForDate.map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildHistoryCard(order),
                  )),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDateHeader(DateTime date, int orderCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppColors.primaryBlue).withValues(alpha:0.1),
            const Color(AppColors.primaryBlue).withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: const Color(AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Text(
            _isToday(date) 
                ? 'Today' 
                : _isYesterday(date)
                    ? 'Yesterday'
                    : DateFormat('EEEE, MMMM d, yyyy').format(date),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(AppColors.primaryBlue),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryBlue).withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$orderCount orders',
              style: const TextStyle(
                color: Color(AppColors.primaryBlue),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.green.withValues(alpha:0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode 
                ? Colors.black.withValues(alpha:0.3)
                : Colors.grey.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                      ),
                      child: const Text(
                        'FULFILLED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_rounded,
                      size: 14,
                      color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.length} items',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.phone,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm:ss').format(order.timestamp),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KSh ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => _showOrderDetails(order),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _isDarkMode 
                  ? Colors.white.withValues(alpha:0.05)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: _isDarkMode ? Colors.white24 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.white60 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('Order $orderId marked as fulfilled'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(AppColors.primaryBlue)),
            const SizedBox(width: 12),
            const Text('New Orders'),
          ],
        ),
        content: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrdersLoaded && state.paidCount > 0) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You have ${state.paidCount} new ${state.paidCount == 1 ? 'order' : 'orders'} waiting to be prepared.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'These orders are in "Paid" status and ready for preparation.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              );
            }
            return const Text('No new orders at this time.');
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Analytics'),
        content: const Text('Advanced analytics coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: const Text('Advanced filtering options coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${order.phone}'),
            Text('Items: ${order.items.length}'),
            Text('Total: KSh ${order.total.toStringAsFixed(2)}'),
            Text('Status: ${order.status}'),
            Text('Time: ${DateFormat('HH:mm:ss').format(order.timestamp)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
}

// Custom painter for simple trend chart
class SimpleTrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final bool isDarkMode;

  SimpleTrendChartPainter({required this.data, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withValues(alpha:0.3),
          Colors.blue.withValues(alpha:0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxValue = data.map((e) => e['orders'] as int).reduce(math.max).toDouble();
    final path = Path();
    final fillPath = Path();

    fillPath.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final value = (data[i]['orders'] as int).toDouble();
      final y = size.height - (value / maxValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_state.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/core/widgets/desktop/warehouse_order_card.dart';
// import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_desktop.dart';
import 'package:kfm_kiosk/features/warehouse/domain/entities/warehouse.dart'; // ✅ Entity Import
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen.dart';

class StaffPanelWarehouseDesktop extends StatefulWidget {
  final Warehouse warehouse;

  const StaffPanelWarehouseDesktop({
    super.key,
    required this.warehouse,
  });

  @override
  State<StaffPanelWarehouseDesktop> createState() => _StaffPanelWarehouseDesktopState();
}

class _StaffPanelWarehouseDesktopState extends State<StaffPanelWarehouseDesktop> {
  final TextEditingController _searchController = TextEditingController();
  late Timer _autoRefreshTimer;
  late Timer _clockTimer;

  String _selectedFilter = 'all';
  bool _showHistory = false;
  bool _isDarkMode = false;
  DateTime _currentTime = DateTime.now();
  int _pendingItemsCount = 0;

  @override
  void initState() {
    super.initState();

    // Auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_showHistory) {
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _autoRefreshTimer.cancel();
    _clockTimer.cancel();
    super.dispose();
  }
  
  // Helper to generate a consistent color based on warehouse ID
  Color _getWarehouseColor() {
    // Simple hash to pick a color from a palette
    final palette = [
      Colors.brown,
      Colors.amber,
      Colors.orange,
      Colors.yellow.shade700,
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.pink,
    ];
    final hash = widget.warehouse.id.hashCode;
    return palette[hash.abs() % palette.length];
  }

  IconData _getWarehouseIcon() {
    // Simple logic to pick icon based on name or category
    final name = widget.warehouse.name.toLowerCase();
    if (name.contains('flour')) return Icons.grain;
    if (name.contains('oil')) return Icons.water_drop;
    if (name.contains('bakery') || name.contains('bread')) return Icons.bakery_dining;
    if (name.contains('premium')) return Icons.grade;
    return Icons.warehouse; // Default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F1419) : Colors.grey[50],
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrdersLoaded) {
            final newPendingCount = _countPendingItems(state);
            if (_pendingItemsCount != newPendingCount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _pendingItemsCount = newPendingCount;
                  });
                }
              });
            }
          }
        },
        child: Column(
          children: [
            _buildWarehouseHeader(),
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
                              ? _buildHistoryView()
                              : _buildActiveOrdersView(),
                        ),
                      ],
                    ),
                  ),
                  _buildStatsPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseHeader() {
    final color = _getWarehouseColor();
    final icon = _getWarehouseIcon();
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.warehouse.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_currentTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),

          // Live Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 20),
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

          // Manual Refresh
          _buildHeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Data',
            onPressed: () => context.read<OrderBloc>().add(const LoadOrders()),
          ),
          const SizedBox(width: 12),

          // Notifications
          _buildHeaderIconButton(
            icon: Icons.notifications_outlined,
            tooltip: 'Pending Items',
            badge: _pendingItemsCount > 0 ? '$_pendingItemsCount' : null,
            onPressed: () => _showNotificationsDialog(),
          ),
          const SizedBox(width: 12),

          // Logout
          _buildHeaderIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onPressed: () => _handleLogout(),
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
            color: Colors.white.withValues(alpha: 0.15),
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
    final color = _getWarehouseColor();
    final icon = _getWarehouseIcon();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          right: BorderSide(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildSidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Active Pickups',
            isSelected: !_showHistory,
            onTap: () => setState(() => _showHistory = false),
          ),
          _buildSidebarItem(
            icon: Icons.history_rounded,
            label: 'Pickup History',
            isSelected: _showHistory,
            onTap: () => setState(() => _showHistory = true),
          ),
          const Spacer(),

          // Warehouse Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.warehouse.categories.join(', '),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    if (state is OrdersLoaded) {
                      final todayItems =
                          state.getTodaysWarehouseItemCount(widget.warehouse.categories);
                      final pendingItems = _getPendingWarehouseItems(state);

                      return Column(
                        children: [
                          _buildSidebarStat('Today\'s Items', '$todayItems'),
                          _buildSidebarStat('Pending', '$pendingItems'),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
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
    final color = _getWarehouseColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? color.withValues(alpha: 0.1)
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
                      ? color
                      : (_isDarkMode ? Colors.white70 : Colors.grey[600]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? color
                          : (_isDarkMode ? Colors.white70 : Colors.grey[700]),
                    ),
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildStatsPanel() {
    final color = _getWarehouseColor();
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          left: BorderSide(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
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
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Warehouse Stats',
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStatCard(
                          'Item Status',
                          'Current pickups',
                          Icons.inventory_2,
                          color,
                          [
                            _buildStatRow(
                                'Paid',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.categories, AppConstants.statusPaid),
                                Colors.blue),
                            _buildStatRow(
                                'Preparing',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.categories,
                                    AppConstants.statusPreparing),
                                Colors.orange),
                            _buildStatRow(
                                'Ready',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.categories,
                                    AppConstants.statusReadyForPickup),
                                Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Today\'s Summary',
                          widget.warehouse.categories.join(', '),
                          Icons.today,
                          Colors.green,
                          [
                            _buildStatRow(
                                'Items Picked',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.categories,
                                    AppConstants.statusFulfilled),
                                Colors.green),
                            _buildStatRow(
                                'Total Orders',
                                state.getTodaysWarehouseOrderCount(
                                    widget.warehouse.categories),
                                Colors.blue),
                          ],
                        ),
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

  Widget _buildStatCard(
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
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
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
                  color: color.withValues(alpha: 0.1),
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

  Widget _buildStatRow(String label, dynamic value, Color color) {
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
              color: color.withValues(alpha: 0.1),
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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 1. Navigate to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDashboardTitle() {
    final color = _getWarehouseColor();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_basket,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Active - ${widget.warehouse.categories.join(', ')}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
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
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
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
                  hintText: 'Search by Order ID or Phone...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterChip(AppConstants.statusPaid, 'Paid', Colors.blue),
          const SizedBox(width: 8),
          _buildFilterChip(
              AppConstants.statusPreparing, 'Preparing', Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip(AppConstants.statusReadyForPickup, 'Ready', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, Color color) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? 'all' : filter;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (_isDarkMode ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (_isDarkMode ? Colors.white70 : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  int _countPendingItems(OrderState state) {
    if (state is! OrdersLoaded) return 0;
    return state.getWarehouseItemCountByStatus(
      widget.warehouse.categories,
      AppConstants.statusPaid,
    ) +
    state.getWarehouseItemCountByStatus(
      widget.warehouse.categories,
      AppConstants.statusPreparing,
    ) +
    state.getWarehouseItemCountByStatus(
      widget.warehouse.categories,
      AppConstants.statusReadyForPickup,
    );
  }

  int _getPendingWarehouseItems(OrdersLoaded state) {
    return state.getWarehouseItemCountByStatus(
          widget.warehouse.categories,
          AppConstants.statusPaid,
        ) +
        state.getWarehouseItemCountByStatus(
          widget.warehouse.categories,
          AppConstants.statusPreparing,
        );
  }

  Widget _buildActiveOrdersView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final activeOrders = state.getWarehouseActiveOrders(widget.warehouse.categories);

          if (activeOrders.isEmpty) {
            return _buildEmptyState();
          }

          // Apply local status filter
          final filteredOrders = activeOrders.where((order) {
            if (_selectedFilter == 'all') return true;
            // Filter by if the warehouse SPECIFIC status for this order matches
            // We need a helper on Order to check if it has items in this status for this warehouse
            return order.warehouseHasItemsInStatus(
                widget.warehouse.categories, _selectedFilter);
          }).toList();

          if (filteredOrders.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 380, // Height of card
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              final color = _getWarehouseColor();
              final icon = _getWarehouseIcon();
              
              return WarehouseOrderCard(
                order: order,
                warehouseItems: order.getItemsForWarehouse(widget.warehouse.categories),
                warehouse: widget.warehouse,
                color: color,
                icon: icon,
                onStartPreparing: () {
                   context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
                     orderId: order.id,
                     warehouseCategories: widget.warehouse.categories,
                     newStatus: AppConstants.statusPreparing,
                   ));
                },
                onMarkReady: () {
                   context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
                     orderId: order.id,
                     warehouseCategories: widget.warehouse.categories,
                     newStatus: AppConstants.statusReadyForPickup,
                   ));
                },
                onMarkFulfilled: () {
                   context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
                     orderId: order.id,
                     warehouseCategories: widget.warehouse.categories,
                     newStatus: AppConstants.statusFulfilled,
                   ));
                },
              );
            },
          );
        } else if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is OrderError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  // History View Implementation
  Widget _buildHistoryHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: _isDarkMode ? Colors.white70 : Colors.grey[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pickup History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final completedOrders = state.getWarehouseFulfilledOrders(widget.warehouse.categories);

          if (completedOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_outlined,
                    size: 64,
                    color: _isDarkMode ? Colors.white24 : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed pickups yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: completedOrders.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = completedOrders[index];
              return _buildHistoryItem(order);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildHistoryItem(Order order) {
    // simplified history item
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF252b3b) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: Colors.green.withValues(alpha: 0.1),
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.check, color: Colors.green, size: 20),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Order #${order.id}', style: TextStyle(
                   fontWeight: FontWeight.bold,
                   color: _isDarkMode ? Colors.white : Colors.black87,
                 )),
                 Text(DateFormat('MMM d, y • HH:mm').format(order.timestamp), style: TextStyle(
                   fontSize: 13,
                   color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                 )),
               ],
             )
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text('${order.items.length} items', style: TextStyle(
                 fontWeight: FontWeight.w500,
                 color: _isDarkMode ? Colors.white70 : Colors.grey[800],
               )),
               Text('Completed', style: TextStyle(
                 fontSize: 12,
                 color: Colors.green,
                 fontWeight: FontWeight.bold,
               )),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: _isDarkMode ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    // Implement standard notification dialog
  }
}
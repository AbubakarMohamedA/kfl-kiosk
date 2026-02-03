import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_state.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/presentation/widgets/desktop/warehouse_order_card.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/home_screen_desktop.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Warehouse definitions
enum Warehouse {
  flour,
  premiumFlour,
  bakerFlour,
  cookingOil,
}

extension WarehouseExtension on Warehouse {
  String get displayName {
    switch (this) {
      case Warehouse.flour:
        return 'Flour Warehouse';
      case Warehouse.premiumFlour:
        return 'Premium Flour Warehouse';
      case Warehouse.bakerFlour:
        return 'Baker Flour Warehouse';
      case Warehouse.cookingOil:
        return 'Cooking Oil Warehouse';
    }
  }

  String get category {
    switch (this) {
      case Warehouse.flour:
        return 'Flour';
      case Warehouse.premiumFlour:
        return 'Premium Flour';
      case Warehouse.bakerFlour:
        return 'Bakers Flour';
      case Warehouse.cookingOil:
        return 'Cooking Oil';
    }
  }

  IconData get icon {
    switch (this) {
      case Warehouse.flour:
        return Icons.grain;
      case Warehouse.premiumFlour:
        return Icons.grade;
      case Warehouse.bakerFlour:
        return Icons.bakery_dining;
      case Warehouse.cookingOil:
        return Icons.water_drop;
    }
  }

  Color get color {
    switch (this) {
      case Warehouse.flour:
        return Colors.brown;
      case Warehouse.premiumFlour:
        return Colors.amber;
      case Warehouse.bakerFlour:
        return Colors.orange;
      case Warehouse.cookingOil:
        return Colors.yellow.shade700;
    }
  }

  // Check if a product belongs to this warehouse
  bool hasProduct(String productCategory) {
    return category == productCategory;
  }
}

class StaffPanelWarehouse extends StatefulWidget {
  final Warehouse warehouse;

  const StaffPanelWarehouse({
    super.key,
    required this.warehouse,
  });

  @override
  State<StaffPanelWarehouse> createState() => _StaffPanelWarehouseState();
}

class _StaffPanelWarehouseState extends State<StaffPanelWarehouse> {
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
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.warehouse.color,
            widget.warehouse.color.withValues(alpha: 0.7),
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
              widget.warehouse.icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.warehouse.displayName,
                style: const TextStyle(
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
                  color: Colors.white.withValues(alpha: 0.85),
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

          // Warehouse Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.warehouse.color.withValues(alpha: 0.1),
                  widget.warehouse.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.warehouse.color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  widget.warehouse.icon,
                  size: 48,
                  color: widget.warehouse.color,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.warehouse.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.warehouse.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    if (state is OrdersLoaded) {
                      final todayItems =
                          state.getTodaysWarehouseItemCount(widget.warehouse.category);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? widget.warehouse.color.withValues(alpha: 0.1)
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
                      ? widget.warehouse.color
                      : (_isDarkMode ? Colors.white70 : Colors.grey[600]),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? widget.warehouse.color
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

  Widget _buildStatsPanel() {
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
                          widget.warehouse.color,
                          [
                            _buildStatRow(
                                'Paid',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.category, AppConstants.statusPaid),
                                Colors.blue),
                            _buildStatRow(
                                'Preparing',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.category,
                                    AppConstants.statusPreparing),
                                Colors.orange),
                            _buildStatRow(
                                'Ready',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.category,
                                    AppConstants.statusReadyForPickup),
                                Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Today\'s Summary',
                          widget.warehouse.category,
                          Icons.today,
                          Colors.green,
                          [
                            _buildStatRow(
                                'Items Picked',
                                state.getWarehouseItemCountByStatus(
                                    widget.warehouse.category,
                                    AppConstants.statusFulfilled),
                                Colors.green),
                            _buildStatRow(
                                'Total Orders',
                                state.getTodaysWarehouseOrderCount(
                                    widget.warehouse.category),
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

  Widget _buildDashboardTitle() {
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
            color: widget.warehouse.color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Active - ${widget.warehouse.category}',
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
                  hintText: 'Search by Order ID or Phone Number...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: widget.warehouse.color,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<OrderBloc>()
                                .add(const SearchOrders(''));
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
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
                dropdownColor:
                    _isDarkMode ? const Color(0xFF252b3b) : Colors.white,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        // Icon(Icons.grid_view_rounded, size: 18),
                        SizedBox(width: 12),
                        Text('All'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPaid,
                    child: Row(
                      children: [
                        Icon(Icons.payment_rounded,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Paid'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPreparing,
                    child: Row(
                      children: [
                        Icon(Icons.inventory_rounded,
                            size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Preparing'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusReadyForPickup,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: Colors.purple),
                        const SizedBox(width: 12),
                        const Text('Ready'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? value) {
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

  Widget _buildActiveOrdersView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          // Filter orders to only show items from this warehouse
          final warehouseOrders = _getWarehouseOrders(state);

          if (warehouseOrders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.inventory_2,
              title: 'No Active Pickups',
              subtitle: _selectedFilter != 'all'
                  ? 'No items match the selected filter'
                  : 'All items have been picked up!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            itemCount: warehouseOrders.length,
            itemBuilder: (context, index) {
              final orderData =
                  warehouseOrders[warehouseOrders.length - 1 - index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WarehouseOrderCard(
                  order: orderData['order'],
                  warehouseItems: orderData['items'],
                  warehouse: widget.warehouse,
                  // ✅ NEW: Use UpdateWarehouseItemsStatus event
                  onStartPreparing: () {
                    context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
                          orderId: orderData['order'].id,
                          warehouseCategory: widget.warehouse.category,
                          newStatus: AppConstants.statusPreparing,
                        ));
                  },
                  onMarkReady: () {
                    context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
                          orderId: orderData['order'].id,
                          warehouseCategory: widget.warehouse.category,
                          newStatus: AppConstants.statusReadyForPickup,
                        ));
                  },
                  onMarkFulfilled: () {
                    context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
                          orderId: orderData['order'].id,
                          warehouseCategory: widget.warehouse.category,
                          newStatus: AppConstants.statusFulfilled,
                        ));
                    _showSuccessSnackBar(orderData['order'].id);
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
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: widget.warehouse.color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Pickup History - ${widget.warehouse.category}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.grey[800],
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
          final fulfilledOrders = _getFulfilledWarehouseOrders(state);

          if (fulfilledOrders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.history,
              title: 'No Pickup History',
              subtitle: 'Completed pickups will appear here',
            );
          }

          // Group by date
          final groupedOrders = <String, List<Map<String, dynamic>>>{};
          for (var orderData in fulfilledOrders) {
            final dateKey =
                DateFormat('yyyy-MM-dd').format(orderData['order'].timestamp);
            groupedOrders.putIfAbsent(dateKey, () => []).add(orderData);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: groupedOrders.length,
            itemBuilder: (context, index) {
              final dateKey =
                  groupedOrders.keys.toList()[groupedOrders.length - 1 - index];
              final ordersForDate = groupedOrders[dateKey]!;
              final date = DateTime.parse(dateKey);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(date, ordersForDate.length),
                  const SizedBox(height: 16),
                  ...ordersForDate.map((orderData) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHistoryCard(orderData),
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

  Widget _buildDateHeader(DateTime date, int itemCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.warehouse.color.withValues(alpha: 0.1),
            widget.warehouse.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 20,
            color: widget.warehouse.color,
          ),
          const SizedBox(width: 12),
          Text(
            _isToday(date)
                ? 'Today'
                : _isYesterday(date)
                    ? 'Yesterday'
                    : DateFormat('EEEE, MMMM d, yyyy').format(date),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: widget.warehouse.color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.warehouse.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$itemCount pickups',
              style: TextStyle(
                color: widget.warehouse.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> orderData) {
    final order = orderData['order'];
    final items = orderData['items'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.08),
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
              color: Colors.green.withValues(alpha: 0.1),
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
                      '${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    // const SizedBox(width: 12),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //       horizontal: 10, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: Colors.green.withValues(alpha: 0.1),
                    //     borderRadius: BorderRadius.circular(6),
                    //     border: Border.all(
                    //         color: Colors.green.withValues(alpha: 0.3)),
                    //   ),
                    //   child: const Text(
                    //     'PICKED UP',
                    //     style: TextStyle(
                    //       color: Colors.green,
                    //       fontSize: 10,
                    //       fontWeight: FontWeight.bold,
                    //       letterSpacing: 0.5,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${items.length} items picked up',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                    fontSize: 13,
                  ),
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
          TextButton.icon(
            onPressed: () => _showItemsDialog(order, items),
            icon: const Icon(Icons.visibility_rounded, size: 16),
            label: const Text('View Items'),
            style: TextButton.styleFrom(
              foregroundColor: widget.warehouse.color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
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
                  ? Colors.white.withValues(alpha: 0.05)
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

  // Helper methods for filtering warehouse-specific data
  List<Map<String, dynamic>> _getWarehouseOrders(OrdersLoaded state) {
    final warehouseOrders = <Map<String, dynamic>>[];

    for (var order in state.getWarehouseActiveOrders(widget.warehouse.category)) {
      final warehouseItems = order.getItemsForWarehouse(widget.warehouse.category);

      if (warehouseItems.isNotEmpty) {
        warehouseOrders.add({
          'order': order,
          'items': warehouseItems,
        });
      }
    }

    return warehouseOrders;
  }

  List<Map<String, dynamic>> _getFulfilledWarehouseOrders(OrdersLoaded state) {
    final fulfilledOrders = <Map<String, dynamic>>[];

    for (var order in state.getWarehouseFulfilledOrders(widget.warehouse.category)) {
      final warehouseItems = order.getItemsForWarehouse(widget.warehouse.category);

      if (warehouseItems.isNotEmpty) {
        fulfilledOrders.add({
          'order': order,
          'items': warehouseItems,
        });
      }
    }

    return fulfilledOrders;
  }

  int _countPendingItems(OrdersLoaded state) {
    return state.getWarehouseItemCountByStatus(
            widget.warehouse.category, AppConstants.statusPaid) +
        state.getWarehouseItemCountByStatus(
            widget.warehouse.category, AppConstants.statusPreparing);
  }

  int _getPendingWarehouseItems(OrdersLoaded state) {
    return state.getWarehouseItemCountByStatus(
            widget.warehouse.category, AppConstants.statusPaid) +
        state.getWarehouseItemCountByStatus(
            widget.warehouse.category, AppConstants.statusPreparing);
  }

  void _showSuccessSnackBar(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('Order $orderId items picked up'),
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
            Icon(Icons.notifications_active, color: widget.warehouse.color),
            const SizedBox(width: 12),
            Text('Pending Items - ${widget.warehouse.category}'),
          ],
        ),
        content: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrdersLoaded && _pendingItemsCount > 0) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You have $_pendingItemsCount items waiting to be picked up.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              );
            }
            return const Text('No pending items at this time.');
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

  void _showItemsDialog(dynamic order, List items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Items from Order #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${item.product.name} (${item.product.size}) x${item.quantity}',
                    ),
                  ))
              .toList(),
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
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
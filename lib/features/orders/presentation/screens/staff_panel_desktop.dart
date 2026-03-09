import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/cart/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_state.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
// TODO: Re-enable when new features are implemented
// import 'package:kfm_kiosk/features/insights/presentation/screens/analytics_screen.dart';
// import 'package:kfm_kiosk/features/warehouse/presentation/screens/inventory_screen.dart';
// import 'package:kfm_kiosk/features/admin/presentation/screens/staff_management_screen.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/settings_screen.dart';
import 'package:kfm_kiosk/features/warehouse/domain/entities/warehouse.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/warehouse_selector_screen.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/features/home/presentation/screens/home_screen_desktop.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/staff_panel_warehouse.dart';
import 'package:kfm_kiosk/features/admin/presentation/screens/super_admin_screen.dart';
import 'package:kfm_kiosk/features/insights/presentation/screens/business_insights_screen.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/maintenance_screen.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/account_disabled_screen.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/premium_upgrade_screen.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/warehouse_management_screen.dart'; // ✅ NEW
import 'package:kfm_kiosk/features/products/presentation/screens/product_management_screen.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/mobile_config_screen.dart'; // ✅ NEW
import 'package:kfm_kiosk/core/widgets/desktop/staff_order_card.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart'; // Added import
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../../core/config/app_role.dart';
import '../../../../core/services/local_server_service.dart';
import '../../../../di/injection.dart';

class StaffPanelDesktop extends StatefulWidget {
  const StaffPanelDesktop({super.key});

  @override
  State<StaffPanelDesktop> createState() => _StaffPanelDesktopState();
}

enum ScreenType {
  dashboard,
  orderHistory,
  // TODO: Re-enable when new features are implemented
  // analytics,
  // inventory,
  // staffManagement,
  settings,
  warehouseSelector,
  warehouseView,
  warehouseManagement, // ✅ NEW
  businessInsights,
  superAdmin,
  productManagement, // ✅ NEW
  mobileConfig, // ✅ NEW
}

class _StaffPanelDesktopState extends State<StaffPanelDesktop>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();
  DateTime _selectedHistoryDate = DateTime.now();
  DateTime _selectedActiveDate = DateTime.now();
  late TabController _tabController;
  late Timer _autoRefreshTimer;
  late Timer _clockTimer;
  String _selectedFilter = 'all';
  bool _showHistory = false;
  ScreenType _currentScreen = ScreenType.dashboard;
  Warehouse? _selectedWarehouse;
  bool _isDarkMode = false;
  DateTime _currentTime = DateTime.now();
  int _paidOrdersCount = 0;

  // ✅ NEW: Configuration tracking for mode awareness
  AppConfiguration _currentConfig = AppConfiguration();
  bool _isConfigLoading = true;

  // Analytics data
  int _peakHourOrders = 0;
  double _averagePrepTime = 0.0;
  List<Map<String, dynamic>> _hourlyData = [];

  // Role & Tier helpers
  bool get isEnterprise => _currentConfig.tierId == 'enterprise';
  bool get isManager => getIt<RoleConfig>().role == AppRole.manager;
  bool get isStaff => getIt<RoleConfig>().role == AppRole.staff;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ✅ NEW: Load configuration on startup
    _loadConfiguration();

    // Silent auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_showHistory) {
        context.read<OrderBloc>().add(const LoadOrders());
        _loadConfiguration(); // Refresh config periodically
        setState(() {}); // Force check for maintenance updates
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

  // ✅ NEW: Load current configuration from repository
  Future<void> _loadConfiguration() async {
    try {
      final config = await context
          .read<OrderBloc>()
          .configurationRepository
          .getConfiguration();

      if (mounted && config != _currentConfig) {
        setState(() {
          _currentConfig = config;
          _isConfigLoading = false;
        });
      }
    } catch (e) {
      // Fallback to default config on error
      if (mounted && _isConfigLoading) {
        setState(() {
          _currentConfig = AppConfiguration();
          _isConfigLoading = false;
        });
      }
    }
  }

  void _generateMockAnalytics() {
    _hourlyData = List.generate(24, (index) {
      return {
        'hour': index,
        'orders': math.Random().nextInt(20) + 5,
        'revenue': (math.Random().nextDouble() * 5000) + 1000,
      };
    });
    _peakHourOrders = _hourlyData
        .map((e) => e['orders'] as int)
        .fold(0, (prev, current) => math.max(prev, current));
    _averagePrepTime = 8.5 + (math.Random().nextDouble() * 6);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _historySearchController.dispose();
    _tabController.dispose();
    _autoRefreshTimer.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  Widget _buildMaintenancePlaceholder(String moduleName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 80,
            color: Colors.orange[300],
          ),
          const SizedBox(height: 24),
          Text(
            '$moduleName Under Maintenance',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'This module is currently being updated.\nPlease check back later.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── MODE-AWARE ORDER HELPERS ────────────────────────────────────────────

  // ⚠️ CRITICAL FULFILLMENT PERSISTENCE LOGIC ⚠️
  //
  // These helper methods implement a key business rule:
  // "Once an order reaches 100% completion (all items fulfilled), it MUST
  // remain completed regardless of tracking mode switches."
  //
  // WHY THIS MATTERS:
  // 1. Order ORD0001 is completed in Item-Level mode (all items picked up)
  // 2. Admin switches system to Order-Level tracking mode
  // 3. Without this logic, ORD0001 might show as "active" again because
  //    the order-level status field might not be "fulfilled"
  // 4. This would confuse staff and create duplicate work
  //
  // SOLUTION:
  // - Check if ALL items have status = "fulfilled"
  // - If yes, treat order as permanently complete regardless of:
  //   * Current tracking mode
  //   * Order-level status field value
  //   * Any other configuration
  // - This ensures orders stay completed once customers have picked them up

  // ✅ FIXED: Use configuration-aware active check with fulfillment persistence
  bool _isOrderActive(Order order) {
    // CRITICAL: If ALL items are fulfilled, the order is permanently complete
    // regardless of current tracking mode. This prevents fulfilled orders
    // from reappearing when switching between tracking modes.
    if (order.items.isNotEmpty) {
      final allItemsFulfilled = order.items.every(
        (item) => item.status == AppConstants.statusFulfilled,
      );
      if (allItemsFulfilled) {
        return false; // Order was 100% complete - stays inactive forever
      }
    }

    // If not all items are fulfilled, use mode-specific active check
    return order.isActive(_currentConfig);
  }

  // ✅ FIXED: Get completion percent based on mode
  double _getOrderCompletionPercent(Order order) {
    // CRITICAL: If all items are fulfilled, always return 100%
    // regardless of tracking mode
    if (order.items.isNotEmpty) {
      final allItemsFulfilled = order.items.every(
        (item) => item.status == AppConstants.statusFulfilled,
      );
      if (allItemsFulfilled) {
        return 100.0;
      }
    }

    if (_currentConfig.statusTrackingMode == StatusTrackingMode.orderLevel) {
      // Order-level: 0% if not fulfilled, 100% if fulfilled
      return order.status == AppConstants.statusFulfilled ? 100.0 : 0.0;
    }

    // Item-level: Calculate based on fulfilled items
    if (order.items.isEmpty) return 0.0;
    final fulfilled = order.items
        .where((i) => i.status == AppConstants.statusFulfilled)
        .length;
    return (fulfilled / order.items.length) * 100.0;
  }

  // ✅ FIXED: Get warehouse categories only in item-level mode
  List<String> _getOrderWarehouseCategories(Order order) {
    if (_currentConfig.statusTrackingMode == StatusTrackingMode.orderLevel) {
      return []; // No warehouse breakdown in order-level mode
    }
    return order.items.map((i) => i.product.category).toSet().toList();
  }

  // ✅ FIXED: Get warehouse-specific completion only in item-level mode
  double _getWarehouseCompletionPercent(Order order, String category) {
    if (_currentConfig.statusTrackingMode == StatusTrackingMode.orderLevel) {
      return _getOrderCompletionPercent(order); // Use order-level percent
    }

    final items = order.items
        .where((i) => i.product.category == category)
        .toList();
    if (items.isEmpty) return 0.0;
    final fulfilled = items
        .where((i) => i.status == AppConstants.statusFulfilled)
        .length;
    return (fulfilled / items.length) * 100.0;
  }

  // ✅ FIXED: Get effective status based on configuration mode
  String _getEffectiveOrderStatus(Order order) {
    // CRITICAL: If all items are fulfilled, always return FULFILLED status
    // regardless of what the order-level status says or current tracking mode
    if (order.items.isNotEmpty) {
      final allItemsFulfilled = order.items.every(
        (item) => item.status == AppConstants.statusFulfilled,
      );
      if (allItemsFulfilled) {
        return AppConstants.statusFulfilled;
      }
    }

    return order.getEffectiveStatus(_currentConfig);
  }

  // Warehouse helpers (only used in item-level mode)
  String _getWarehouseStatus(Order order, String category) {
    final items = order.items
        .where((i) => i.product.category == category)
        .toList();
    if (items.isEmpty) return AppConstants.statusFulfilled;
    final statuses = items.map((i) => i.status).toSet();
    if (statuses.contains(AppConstants.statusPaid)) {
      return AppConstants.statusPaid;
    }
    if (statuses.contains(AppConstants.statusPreparing)) {
      return AppConstants.statusPreparing;
    }
    if (statuses.contains(AppConstants.statusReadyForPickup)) {
      return AppConstants.statusReadyForPickup;
    }
    return AppConstants.statusFulfilled;
  }

  Color _warehouseColor(String category) {
    switch (category) {
      case 'Flour':
        return Colors.brown;
      case 'Premium Flour':
        return Colors.amber;
      case 'Bakers Flour':
        return Colors.orange;
      case 'Cooking Oil':
        return Colors.yellow.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _warehouseIcon(String category) {
    switch (category) {
      case 'Flour':
        return Icons.grain;
      case 'Premium Flour':
        return Icons.grade;
      case 'Bakers Flour':
        return Icons.bakery_dining;
      case 'Cooking Oil':
        return Icons.water_drop;
      default:
        return Icons.inventory_2;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return Colors.blue;
      case AppConstants.statusPreparing:
        return Colors.orange;
      case AppConstants.statusReadyForPickup:
        return Colors.purple;
      case AppConstants.statusFulfilled:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return Icons.payment;
      case AppConstants.statusPreparing:
        return Icons.autorenew;
      case AppConstants.statusReadyForPickup:
        return Icons.inventory_2;
      case AppConstants.statusFulfilled:
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return 'PAID';
      case AppConstants.statusPreparing:
        return 'PREPARING';
      case AppConstants.statusReadyForPickup:
        return 'READY';
      case AppConstants.statusFulfilled:
        return 'PICKED UP';
      default:
        return status.toUpperCase();
    }
  }

  // ✅ NEW: Get appropriate status update event based on mode
  void _updateOrderStatus(Order order, String newStatus) {
    final bloc = context.read<OrderBloc>();

    if (_currentConfig.statusTrackingMode == StatusTrackingMode.orderLevel) {
      // Order-level mode: Update entire order status
      bloc.add(UpdateOrderStatus(orderId: order.id, status: newStatus));
    } else {
      // Item-level mode: Update all items to new status
      bloc.add(UpdateOrderStatus(orderId: order.id, status: newStatus));
      // Note: In item-level mode, warehouse stations handle per-category updates
      // The main dashboard provides order-level actions as fallback
    }
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
      // Stop local server and clear active tenant
      getIt<LocalServerService>().setActiveTenantId('');

      // ✅ NEW: Clear orders from state to prevent data bleeding
      if (mounted) {
        context.read<OrderBloc>().add(const ClearOrders());
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfigLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tenantId = _currentConfig.tenantId ?? '';
    final tenantService = TenantService();

    // 1. Maintenance Mode Check
    // We allow access to SuperAdmin screen even in maintenance mode to allow turning it off
    // SUPER ADMIN BYPASS: If the user is a super admin, they should circumvent this screen
    final isSuperAdmin = tenantService.isSuperAdmin(tenantId);

    // Check tenant specific maintenance
    bool isTenantMaintenance = false;
    try {
      final tenant = tenantService.getTenants().firstWhere(
        (t) => t.id == tenantId,
      );
      isTenantMaintenance = tenant.isMaintenanceMode;
    } catch (_) {}

    // Check immunity
    final isImmune = tenantService.isTenantImmune(
      tenantId,
      fallbackTierId: _currentConfig.tierId,
    );

    if ((tenantService.isMaintenanceMode || isTenantMaintenance) &&
        !isSuperAdmin &&
        !isImmune &&
        _currentScreen != ScreenType.superAdmin) {
      return MaintenanceScreen(
        onAdminAccess: () {
          setState(() {
            _currentScreen = ScreenType.superAdmin;
          });
        },
      );
    }

    // 2. Account Disabled Check
    // Block access if tenant is disabled (unless already in super admin, e.g. for recovery)
    if (!tenantService.isTenantEnabled(tenantId) &&
        _currentScreen != ScreenType.superAdmin) {
      return const AccountDisabledScreen();
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F1419) : Colors.grey[50],
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrdersLoaded) {
            final newPaidCount = state.paidCount;
            if (_paidOrdersCount != newPaidCount) {
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
                    child: Builder(
                      builder: (context) {
                        final tenantId = _currentConfig.tenantId ?? '';
                        final isSuperAdmin = TenantService().isSuperAdmin(
                          tenantId,
                        );

                        String? maintenanceKey;
                        String moduleName = '';

                        if (_currentScreen == ScreenType.dashboard) {
                          if (_showHistory) {
                            maintenanceKey = 'history';
                            moduleName = 'Order History';
                          } else {
                            maintenanceKey = 'orders';
                            moduleName = 'Orders Module';
                          }
                        } else if (_currentScreen ==
                                ScreenType.warehouseSelector ||
                            _currentScreen == ScreenType.warehouseView) {
                          maintenanceKey = 'warehouse';
                          moduleName = 'Warehouse Stations';
                        } else if (_currentScreen ==
                            ScreenType.businessInsights) {
                          maintenanceKey = 'insights';
                          moduleName = 'Business Insights';
                        }

                        final isImmune = TenantService().isTenantImmune(
                          tenantId,
                          fallbackTierId: _currentConfig.tierId,
                        );

                        if (maintenanceKey != null) {
                          final isMaintenance = TenantService()
                              .isModuleUnderMaintenance(maintenanceKey);

                          if (isMaintenance && !isSuperAdmin && !isImmune) {
                            return _buildMaintenancePlaceholder(moduleName);
                          }
                        }

                        return _currentScreen == ScreenType.dashboard
                            ? _buildDashboardContent()
                            : _currentScreen == ScreenType.warehouseSelector
                            ? WarehouseSelectorScreen(
                                branchId: _currentConfig.branchId,
                                onWarehouseSelected: (warehouse) {
                                  setState(() {
                                    _selectedWarehouse = warehouse;
                                    _currentScreen = ScreenType.warehouseView;
                                  });
                                },
                              )
                            : _currentScreen == ScreenType.warehouseView &&
                                  _selectedWarehouse != null
                            ? StaffPanelWarehouse(
                                warehouse: _selectedWarehouse!,
                              )
                            : _currentScreen ==
                                  ScreenType
                                      .warehouseManagement // ✅ NEW
                            ? const WarehouseManagementScreen()
                            : _currentScreen ==
                                  ScreenType
                                      .productManagement // ✅ NEW
                            ? const ProductManagementScreen()
                            // : _currentScreen == ScreenType.staffManagement
                            //             ? const StaffManagementScreen() // Keep routed just in case, though unreachable from sidebar
                            : _currentScreen == ScreenType.businessInsights
                            ? (TenantService().canAccessFeature(
                                    _currentConfig.tenantId ?? '',
                                    'insights',
                                  )
                                  ? const BusinessInsightsScreen()
                                  : const PremiumUpgradeScreen())
                            : _currentScreen == ScreenType.superAdmin
                            ? const SuperAdminScreen()
                            : _currentScreen ==
                                  ScreenType
                                      .mobileConfig // ✅ NEW
                            ? const MobileConfigScreen()
                            : const SettingsScreen();
                      },
                    ),
                  ),
                  // ✅ FIXED: Only show right panel in dashboard view AND item-level mode
                  if (_currentScreen == ScreenType.dashboard &&
                      _currentConfig.statusTrackingMode ==
                          StatusTrackingMode.itemLevel)
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
              ? [const Color(0xFF083E22), const Color(0xFF083E22)]
              : [const Color(AppColors.primaryBlue), const Color(0xFF0A6F38)],
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
            child: const Icon(
              Icons.dashboard_customize_rounded,
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
                const Text(
                  'Staff Command Center',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (isEnterprise ? isManager : isStaff)
                            ? Colors.greenAccent
                            : Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isEnterprise ? isManager : isStaff)
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.blueAccent.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (isEnterprise ? isManager : isStaff)
                          ? 'Local Server: Online'
                          : 'Remote Client: Connected',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
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
          _buildHeaderIconButton(
            icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            tooltip: _isDarkMode ? 'Light Mode' : 'Dark Mode',
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 12),
          _buildHeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Data',
            onPressed: () {
              _loadConfiguration(); // Refresh config too
              context.read<OrderBloc>().add(const LoadOrders());
            },
          ),
          // const SizedBox(width: 12),
          // _buildHeaderIconButton(
          //   icon: Icons.notifications_outlined,
          //   tooltip: 'New Orders (Paid)',
          //   badge: _paidOrdersCount > 0 ? '$_paidOrdersCount' : null,
          //   onPressed: () => _showNotificationsDialog(),
          // ),
          const SizedBox(width: 12),
          _buildHeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',

            onPressed: () =>
                setState(() => _currentScreen = ScreenType.settings),
          ),
          const SizedBox(width: 12),
          _buildHeaderIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            onPressed: _handleLogout,
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
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
    final roleConfig = getIt<RoleConfig>();
    final tenantId = _currentConfig.tenantId ?? '';
    final tenantService = TenantService();
    final isSuperAdmin = tenantService.isSuperAdmin(tenantId);

    // Feature checks
    final canViewOrders =
        isSuperAdmin || tenantService.canAccessFeature(tenantId, 'orders');
    final canViewHistory =
        isSuperAdmin || tenantService.canAccessFeature(tenantId, 'history');
    final canViewInsights =
        isSuperAdmin || tenantService.canAccessFeature(tenantId, 'insights');

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
          const SizedBox(height: 20),
          // ✅ NEW: Branch Indicator (Only for Enterprise Tier or Branch Managers)
          // Since Branch Managers inherit the Enterprise Tier ID configuration,
          // checking for 'enterprise' tier and presence of branchId covers both.
          if (_currentConfig.branchId != null && isEnterprise && isManager)
            _buildBranchIndicator(),

          if (_currentConfig.branchId != null && isEnterprise && isManager)
            const SizedBox(height: 20),

          if (canViewOrders)
            _buildSidebarItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              maintenanceKey: 'orders',
              isSelected:
                  _currentScreen == ScreenType.dashboard && !_showHistory,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.dashboard;
                  _showHistory = false;
                });
              },
            ),
          if (canViewHistory)
            _buildSidebarItem(
              icon: Icons.history_rounded,
              label: 'Order History',
              maintenanceKey: 'history',
              isSelected:
                  _currentScreen == ScreenType.dashboard && _showHistory,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.dashboard;
                  _showHistory = true;
                });
              },
            ),
          // ✅ FIXED: Only show warehouse stations in item-level mode
          if (_currentConfig.statusTrackingMode == StatusTrackingMode.itemLevel)
            _buildSidebarItem(
              icon: Icons.warehouse,
              label: 'Warehouse Stations',
              maintenanceKey: 'warehouse',
              isSelected: _currentScreen == ScreenType.warehouseSelector,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.warehouseSelector;
                  _showHistory = false;
                });
              },
            ),
          // ✅ NEW: Warehouse Management for Branch Managers
          if (_currentConfig.branchId != null && isEnterprise && isManager)
            _buildSidebarItem(
              icon: Icons.warehouse_rounded,
              label: 'Manage Warehouses',
              isSelected: _currentScreen == ScreenType.warehouseManagement,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.warehouseManagement;
                  _showHistory = false;
                });
              },
            ),

          // ✅ NEW: Product Management
          // Visible to all tenants as per requirement (if feature enabled)
          if (_currentConfig.tenantId != null &&
              TenantService().canAccessFeature(
                _currentConfig.tenantId!,
                'products',
              ))
            _buildSidebarItem(
              icon: Icons.inventory_2_rounded,
              label: 'Products',
              maintenanceKey: 'products',
              isSelected: _currentScreen == ScreenType.productManagement,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.productManagement;
                  _showHistory = false;
                });
              },
            ),

          // ✅ NEW: Mobile App Config Item
          _buildSidebarItem(
            icon: Icons.phonelink_setup,
            label: 'Terminal',
            isSelected: _currentScreen == ScreenType.mobileConfig,
            onTap: () {
              setState(() => _currentScreen = ScreenType.mobileConfig);
            },
          ),

          // Always show Business Insights (Gated by Paywall) - BUT hide if disabled in features
          if (canViewInsights)
            _buildSidebarItem(
              icon: Icons.insights,
              label: 'Business Insights',
              maintenanceKey: 'insights',
              isSelected: _currentScreen == ScreenType.businessInsights,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.businessInsights;
                  _showHistory = false;
                });
              },
            ),

          const Divider(height: 20),

          // Only show Admin/Kiosk for Super Admin
          if (TenantService().isSuperAdmin(_currentConfig.tenantId ?? '')) ...[
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
            _buildSidebarItem(
              icon: Icons.admin_panel_settings,
              label: 'Super Admin',
              isSelected: _currentScreen == ScreenType.superAdmin,
              onTap: () {
                setState(() {
                  _currentScreen = ScreenType.superAdmin;
                  _showHistory = false;
                });
              },
            ),
          ],
          const Spacer(),
          // Container(
          //   margin: const EdgeInsets.all(8),
          //   padding: const EdgeInsets.all(8),
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [
          //         const Color(AppColors.primaryBlue).withValues(alpha: 0.1),
          //         const Color(AppColors.primaryBlue).withValues(alpha: 0.05),
          //       ],
          //     ),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: const Color(AppColors.primaryBlue).withValues(alpha: 0.2),
          //     ),
          //   ),
          //   child: BlocBuilder<OrderBloc, OrderState>(
          //     builder: (context, state) {
          //       if (state is OrdersLoaded) {
          //         return Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Today\'s Overview',
          //               style: TextStyle(
          //                 fontSize: 12,
          //                 fontWeight: FontWeight.w600,
          //                 color: _isDarkMode ? Colors.white70 : Colors.grey[700],
          //               ),
          //             ),
          //             const SizedBox(height: 8),
          //             _buildSidebarStat('Orders', '${state.todaysOrderCount}'),
          //             _buildSidebarStat(
          //                 'Revenue', 'KSh ${state.todaysSales.toStringAsFixed(0)}'),
          //             _buildSidebarStat(
          //                 'Active', '${state.paidCount + state.preparingCount + state.readyCount}'),
          //           ],
          //         );
          //       }
          //       return const SizedBox.shrink();
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildBranchIndicator() {
    final branchId = _currentConfig.branchId;
    if (branchId == null) return const SizedBox.shrink();

    // FutureBuilder handles the async list fetching
    return FutureBuilder<List<Branch>>(
      future: TenantService().getBranchesForTenant(
        _currentConfig.tenantId ?? '',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final branches = snapshot.data!;
        Branch? branch;
        try {
          branch = branches.firstWhere((b) => b.id == branchId);
        } catch (_) {
          branch = const Branch(
            id: '',
            tenantId: '',
            name: 'Unknown Branch',
            location: '',
            contactPhone: '',
            managerName: '',
            loginUsername: '',
            loginPassword: '',
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1a237e).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1a237e).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Color(0xFF1a237e),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT BRANCH',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1a237e),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
    String? maintenanceKey,
    // bool isSelected = false,  <-- Duplicate removed
  }) {
    final tenantId = _currentConfig.tenantId ?? '';
    final isSuperAdmin = TenantService().isSuperAdmin(tenantId);

    // Check immunity
    final isImmune = TenantService().isTenantImmune(
      tenantId,
      fallbackTierId: _currentConfig.tierId,
    );

    final isUnderMaintenance =
        maintenanceKey != null &&
        TenantService().isModuleUnderMaintenance(maintenanceKey);

    // Locked if under maintenance AND not super admin AND not immune
    final isLocked = isUnderMaintenance && !isSuperAdmin && !isImmune;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? const Color(AppColors.primaryBlue).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: isLocked
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This module is currently under maintenance',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isLocked ? Icons.lock_outline : icon,
                  size: 22,
                  color: isLocked
                      ? Colors.grey
                      : isSelected
                      ? const Color(AppColors.primaryBlue)
                      : (_isDarkMode ? Colors.white70 : Colors.grey[600]),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isLocked
                        ? Colors.grey
                        : isSelected
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

  /*
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
*/

  // ✅ FIXED: Right panel only shown in item-level mode
  Widget _buildRightPanel() {
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
                  final completedToday = state.orders
                      .where(
                        (o) =>
                            o.status == AppConstants.statusFulfilled &&
                            _isToday(o.timestamp),
                      )
                      .length;
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
                            _buildInsightRow(
                              'Paid',
                              state.paidCount,
                              Colors.blue,
                            ),
                            _buildInsightRow(
                              'Preparing',
                              state.preparingCount,
                              Colors.orange,
                            ),
                            _buildInsightRow(
                              'Ready',
                              state.readyCount,
                              Colors.purple,
                            ),
                            _buildInsightRow(
                              'Completed',
                              completedToday,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInsightCard(
                          'Performance',
                          'Today\'s metrics',
                          Icons.speed,
                          Colors.green,
                          [
                            _buildInsightRow(
                              'Completion Rate',
                              state.todaysOrderCount > 0
                                  ? '${((completedToday / state.todaysOrderCount) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              Colors.green,
                            ),
                            _buildInsightRow(
                              'Avg Prep Time',
                              '${_averagePrepTime.toStringAsFixed(1)} min',
                              Colors.teal,
                            ),
                            _buildInsightRow(
                              'Peak Hour',
                              '$_peakHourOrders orders',
                              Colors.indigo,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInsightCard(
                          'Revenue',
                          'Financial summary',
                          Icons.attach_money,
                          Colors.green,
                          [
                            _buildInsightRow(
                              'Today',
                              'KSh ${state.todaysSales.toStringAsFixed(0)}',
                              Colors.green,
                            ),
                            _buildInsightRow(
                              'Avg Order',
                              state.todaysOrderCount > 0
                                  ? 'KSh ${(state.todaysSales / state.todaysOrderCount).toStringAsFixed(0)}'
                                  : 'KSh 0',
                              Colors.blue,
                            ),
                            _buildInsightRow(
                              'Orders',
                              '${state.todaysOrderCount}',
                              Colors.purple,
                            ),
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

  Widget _buildInsightRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildTrendChart(OrdersLoaded state) {
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
              Icon(Icons.trending_up, color: Colors.green, size: 20),
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
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
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
            _showHistory
                ? 'Order History'
                : (getIt<RoleConfig>().role == AppRole.manager
                      ? 'Manager Control Panel'
                      : 'Staff Dashboard'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          // ✅ NEW: Show current mode indicator
          const Spacer(),
          if (!_showHistory)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _currentConfig.statusTrackingMode ==
                        StatusTrackingMode.orderLevel
                    ? Colors.blue[50]
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _currentConfig.statusTrackingMode ==
                          StatusTrackingMode.orderLevel
                      ? Colors.blue[300]!
                      : Colors.green[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentConfig.statusTrackingMode ==
                            StatusTrackingMode.orderLevel
                        ? Icons.list_alt
                        : Icons.view_module,
                    size: 16,
                    color:
                        _currentConfig.statusTrackingMode ==
                            StatusTrackingMode.orderLevel
                        ? Colors.blue
                        : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentConfig.statusTrackingMode ==
                            StatusTrackingMode.orderLevel
                        ? 'Order-Level Tracking'
                        : 'Item-Level Tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          _currentConfig.statusTrackingMode ==
                              StatusTrackingMode.orderLevel
                          ? Colors.blue[900]
                          : Colors.green[900],
                    ),
                  ),
                ],
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
                    color: const Color(AppColors.primaryBlue),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<OrderBloc>().add(
                              const SearchOrders(''),
                            );
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                dropdownColor: _isDarkMode
                    ? const Color(0xFF252b3b)
                    : Colors.white,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        // Icon(Icons.grid_view_rounded, size: 18),
                        SizedBox(width: 12),
                        Text('All Orders'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPaid,
                    child: Row(
                      children: [
                        // Icon(Icons.payment_rounded, size: 18, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('Paid'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPreparing,
                    child: Row(
                      children: [
                        // Icon(Icons.restaurant_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Text('Preparing'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusReadyForPickup,
                    child: Row(
                      children: [
                        // Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.purple),
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
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF252b3b) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[300]!,
              ),
            ),
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  color: const Color(AppColors.primaryBlue),
                  onPressed: () async {
                    List<DateTime> activeDates = [];
                    if (state is OrdersLoaded) {
                      activeDates = state.orders
                          .where((o) => _isOrderActive(o))
                          .map(
                            (o) => DateTime(
                              o.timestamp.year,
                              o.timestamp.month,
                              o.timestamp.day,
                            ),
                          )
                          .toSet()
                          .toList();
                    }

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final initialDate = _selectedActiveDate.isAfter(now)
                        ? now
                        : _selectedActiveDate;
                    final initialDay = DateTime(
                      initialDate.year,
                      initialDate.month,
                      initialDate.day,
                    );

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: now,
                      selectableDayPredicate: (day) {
                        final checkDate = DateTime(
                          day.year,
                          day.month,
                          day.day,
                        );
                        if (checkDate == initialDay || checkDate == today)
                          return true;
                        return activeDates.contains(checkDate);
                      },
                    );
                    if (picked != null && picked != _selectedActiveDate) {
                      setState(() {
                        _selectedActiveDate = picked;
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── MODE-AWARE ACTIVE ORDERS VIEW ────────────────────────────────────────
  Widget _buildEnhancedOrdersView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          var activeOrders = state.orders
              .where((o) => _isOrderActive(o))
              .toList();

          // Apply active orders date filter
          activeOrders = activeOrders.where((o) {
            return o.timestamp.year == _selectedActiveDate.year &&
                o.timestamp.month == _selectedActiveDate.month &&
                o.timestamp.day == _selectedActiveDate.day;
          }).toList();

          if (activeOrders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Active Orders',
              subtitle: _selectedFilter != 'all'
                  ? 'No orders match the selected filter'
                  : 'All orders have been completed or selected date has no active orders!',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final order = activeOrders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildActiveOrderCard(order),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // ✅ UPDATED: Use StaffOrderCard for order-level, custom card for item-level
  Widget _buildActiveOrderCard(Order order) {
    // ✅ For order-level tracking: Use simple StaffOrderCard
    if (_currentConfig.statusTrackingMode == StatusTrackingMode.orderLevel) {
      final effectiveStatus = _getEffectiveOrderStatus(order);

      return StaffOrderCard(
        order: order,
        config: _currentConfig, // ✅ Pass config for proper status detection
        onStartPreparing: effectiveStatus == AppConstants.statusPaid
            ? () => _updateOrderStatus(order, AppConstants.statusPreparing)
            : null,
        onMarkReady: effectiveStatus == AppConstants.statusPreparing
            ? () => _updateOrderStatus(order, AppConstants.statusReadyForPickup)
            : null,
        onMarkFulfilled: effectiveStatus == AppConstants.statusReadyForPickup
            ? () => _updateOrderStatus(order, AppConstants.statusFulfilled)
            : null,
      );
    }

    // ✅ For item-level tracking: Use detailed warehouse card
    final percent = _getOrderCompletionPercent(order);
    final categories = _getOrderWarehouseCategories(order);
    final _ = _getEffectiveOrderStatus(order);

    return GestureDetector(
      onTap: () => _showOrderDetailBottomSheet(order),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(
              AppColors.primaryBlue,
            ).withValues(alpha: _isDarkMode ? 0.3 : 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: (_isDarkMode ? Colors.black : Colors.black).withValues(
                alpha: 0.06,
              ),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            AppColors.primaryBlue,
                          ).withValues(alpha: _isDarkMode ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(AppColors.primaryBlue),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Phone: ${order.phone}  •  ${DateFormat('dd MMM, HH:mm').format(order.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildCompletionRing(percent, 48),
                ],
              ),
              const SizedBox(height: 14),

              if (categories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: categories.map((cat) {
                    final whPercent = _getWarehouseCompletionPercent(
                      order,
                      cat,
                    );
                    final whColor = _warehouseColor(cat);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: whColor.withValues(
                          alpha: _isDarkMode ? 0.25 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: whColor.withValues(
                            alpha: _isDarkMode ? 0.4 : 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_warehouseIcon(cat), size: 14, color: whColor),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isDarkMode ? whColor : whColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${whPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? whColor : whColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (categories.isNotEmpty) const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent / 100.0,
                  minHeight: 8,
                  backgroundColor: _isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 100
                        ? Colors.green
                        : const Color(AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percent.toStringAsFixed(0)}% picked up  •  KSh ${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isDarkMode
                              ? Colors.white60
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Mode-aware order detail bottom sheet
  void _showOrderDetailBottomSheet(Order order) {
    final categories = _getOrderWarehouseCategories(order);
    final totalPercent = _getOrderCompletionPercent(order);
    final effectiveStatus = _getEffectiveOrderStatus(order);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Phone: ${order.phone}  •  KSh ${order.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ordered: ${DateFormat('EEEE, MMMM d, yyyy HH:mm').format(order.timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode
                              ? Colors.white60
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  // ✅ FIXED: Mode-aware header display
                  if (_currentConfig.statusTrackingMode ==
                      StatusTrackingMode.itemLevel)
                    _buildCompletionRing(totalPercent, 56)
                  else
                    _buildStatusBadge(effectiveStatus),
                ],
              ),
              const SizedBox(height: 24),

              // ✅ FIXED: Mode-aware content rendering
              if (_currentConfig.statusTrackingMode ==
                  StatusTrackingMode.orderLevel)
                _buildOrderLevelDetail(order, effectiveStatus)
              else
                Column(
                  children: categories.map((category) {
                    final whStatus = _getWarehouseStatus(order, category);
                    final whPercent = _getWarehouseCompletionPercent(
                      order,
                      category,
                    );
                    final whItems = order.items
                        .where((i) => i.product.category == category)
                        .toList();
                    final whTotal = whItems.fold<double>(
                      0.0,
                      (sum, item) => sum + item.subtotal,
                    );
                    final color = _warehouseColor(category);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: _isDarkMode ? 0.15 : 0.04,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(
                              alpha: _isDarkMode ? 0.4 : 0.22,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(
                                        alpha: _isDarkMode ? 0.25 : 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _warehouseIcon(category),
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _isDarkMode ? color : color,
                                          ),
                                        ),
                                        Text(
                                          '${whItems.length} item${whItems.length > 1 ? 's' : ''}  •  KSh ${whTotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _isDarkMode
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(whStatus),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: whPercent / 100.0,
                                      minHeight: 6,
                                      backgroundColor: _isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        whPercent >= 100 ? Colors.green : color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${whPercent.toStringAsFixed(0)}% picked up',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isDarkMode ? color : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...whItems.map((item) => _buildItemRow(item)),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Order-level detail view (simplified)
  Widget _buildOrderLevelDetail(Order order, String effectiveStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _statusColor(effectiveStatus).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _statusColor(effectiveStatus).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _statusIcon(effectiveStatus),
                    color: _statusColor(effectiveStatus),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Order Status: ${_statusLabel(effectiveStatus)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(effectiveStatus),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons based on status
              if (effectiveStatus == AppConstants.statusPaid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateOrderStatus(order, AppConstants.statusPreparing),
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Start Preparing Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              if (effectiveStatus == AppConstants.statusPreparing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(
                      order,
                      AppConstants.statusReadyForPickup,
                    ),
                    icon: const Icon(Icons.inventory_2),
                    label: const Text('Mark as Ready for Pickup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              if (effectiveStatus == AppConstants.statusReadyForPickup)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateOrderStatus(order, AppConstants.statusFulfilled),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Fulfilled (Picked Up)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Items in this order:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...order.items.map((item) => _buildSimpleItemRow(item)),
      ],
    );
  }

  Widget _buildSimpleItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.product.size} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            'KSh ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(CartItem item) {
    final sColor = _statusColor(item.status);
    final sIcon = _statusIcon(item.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Icon(sIcon, size: 18, color: sColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.product.size,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'x${item.quantity}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'KSh ${item.subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(item.status),
        ],
      ),
    );
  }

  // ─── MODE-AWARE ORDER HISTORY VIEW ────────────────────────────────────────
  Widget _buildHistoryHeader() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        List<Order> historyOrders = [];
        if (state is OrdersLoaded) {
          historyOrders = state.orders
              .where((o) => !_isOrderActive(o))
              .toList();
        }

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
              const Spacer(),
              // Search Bar
              SizedBox(
                width: 300,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF252b3b)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: TextField(
                    controller: _historySearchController,
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search History...',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: const Color(AppColors.primaryBlue),
                      ),
                      suffixIcon: _historySearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _historySearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Calendar Button
              Container(
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF252b3b)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[300]!,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  color: const Color(AppColors.primaryBlue),
                  onPressed: () async {
                    // Extract unique dates with history
                    final activeDates = historyOrders
                        .map(
                          (o) => DateTime(
                            o.timestamp.year,
                            o.timestamp.month,
                            o.timestamp.day,
                          ),
                        )
                        .toSet()
                        .toList();

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final initialDate = _selectedHistoryDate.isAfter(now)
                        ? now
                        : _selectedHistoryDate;
                    final initialDay = DateTime(
                      initialDate.year,
                      initialDate.month,
                      initialDate.day,
                    );

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2000),
                      lastDate: now,
                      selectableDayPredicate: (day) {
                        final checkDate = DateTime(
                          day.year,
                          day.month,
                          day.day,
                        );
                        if (checkDate == initialDay || checkDate == today)
                          return true;
                        return activeDates.contains(checkDate);
                      },
                    );
                    if (picked != null && picked != _selectedHistoryDate) {
                      setState(() {
                        _selectedHistoryDate = picked;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHistoryView() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final query = _historySearchController.text.trim().toLowerCase();

          // 1. Get raw history orders
          var historyOrders = state.orders
              .where((o) => !_isOrderActive(o))
              .toList();

          // 2. Filter by Search Query OR Date
          if (query.isNotEmpty) {
            // Search mode: ignore date filter
            historyOrders = historyOrders.where((o) {
              return o.id.toLowerCase().contains(query) ||
                  o.phone.contains(query);
            }).toList();
          } else {
            // Date Filter mode
            historyOrders = historyOrders.where((o) {
              return o.timestamp.year == _selectedHistoryDate.year &&
                  o.timestamp.month == _selectedHistoryDate.month &&
                  o.timestamp.day == _selectedHistoryDate.day;
            }).toList();
          }

          if (historyOrders.isEmpty) {
            return _buildEmptyState(
              icon: Icons.history,
              title: query.isNotEmpty
                  ? 'No Results Found'
                  : 'No Order History for Selected Date',
              subtitle: query.isNotEmpty
                  ? 'Try a different search query'
                  : 'Try selecting another day from the calendar',
            );
          }
          final grouped = <String, List<Order>>{};
          for (var order in historyOrders) {
            final key = DateFormat('yyyy-MM-dd').format(order.timestamp);
            grouped.putIfAbsent(key, () => []).add(order);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.toList()[grouped.length - 1 - index];
              final ordersForDate = grouped[dateKey]!;
              final date = DateTime.parse(dateKey);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateDivider(date, ordersForDate.length),
                  const SizedBox(height: 12),
                  ...ordersForDate.map(
                    (order) => _buildHistoryOrderCard(order),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDateDivider(DateTime date, int count) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    final label = isToday
        ? 'Today'
        : isYesterday
        ? 'Yesterday'
        : DateFormat('EEEE, MMMM d, yyyy').format(date);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white70 : Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: _isDarkMode ? Colors.white24 : Colors.grey[300],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white24 : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count order${count > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ FIXED: Mode-aware history order card
  Widget _buildHistoryOrderCard(Order order) {
    final categories = _getOrderWarehouseCategories(order);
    final effectiveStatus = _getEffectiveOrderStatus(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: _isDarkMode ? 0.3 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withValues(
              alpha: 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                      alpha: _isDarkMode ? 0.2 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(
                                alpha: _isDarkMode ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withValues(
                                  alpha: _isDarkMode ? 0.4 : 0.3,
                                ),
                              ),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Phone: ${order.phone}  •  ${DateFormat('dd MMM yyyy, HH:mm').format(order.timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(AppColors.primaryBlue),
                      ),
                    ),
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ✅ FIXED: Mode-aware history content
            if (_currentConfig.statusTrackingMode ==
                StatusTrackingMode.orderLevel)
              _buildOrderLevelHistoryDetail(order, effectiveStatus)
            else
              Column(
                children: categories.map((category) {
                  final whItems = order.items
                      .where((i) => i.product.category == category)
                      .toList();
                  final whTotal = whItems.fold<double>(
                    0.0,
                    (sum, item) => sum + item.subtotal,
                  );
                  final color = _warehouseColor(category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _warehouseIcon(category),
                                  size: 18,
                                  color: color,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMode ? color : color,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'All picked up',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'KSh ${whTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _isDarkMode ? color : color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...whItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${item.product.name} (${item.product.size})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'KSh ${item.subtotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Order-level history detail
  Widget _buildOrderLevelHistoryDetail(Order order, String effectiveStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Order Status: ${_statusLabel(effectiveStatus)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Items:',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item.product.name} (${item.product.size}) × ${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  'KSh ${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── SHARED UI COMPONENTS ──────────────────────────────────────────────────
  Widget _buildCompletionRing(double percent, double size) {
    final color = percent >= 100
        ? Colors.green
        : percent >= 50
        ? Colors.orange
        : const Color(AppColors.primaryBlue);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percent / 100.0,
            strokeWidth: 5,
            backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: size > 50 ? 14 : 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDarkMode ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: _isDarkMode ? 0.4 : 0.3),
        ),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? color : color,
        ),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildDashboardContent() {
    return Column(
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
    );
  }
}

// Custom painter for simple trend chart (unchanged)
class SimpleTrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final bool isDarkMode;

  SimpleTrendChartPainter({required this.data, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxValue = data
        .map((e) => e['orders'] as int)
        .fold(0, (prev, current) => math.max(prev, current))
        .toDouble();
    // Draw grid lines
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.grey[300]!).withValues(
        alpha: 0.3,
      )
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Draw area fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withValues(alpha: isDarkMode ? 0.2 : 0.3),
          Colors.blue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    // Draw line
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final value = (data[i]['orders'] as int).toDouble();
      final y = size.height - (value / maxValue * size.height * 0.9);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      // Draw data point
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.blue);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/widgets/enterprise_charts.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/widgets/enterprise_feed.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/maintenance_screen.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/account_disabled_screen.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_state.dart';

class EnterpriseDashboardDesktop extends StatefulWidget {
  const EnterpriseDashboardDesktop({super.key});

  @override
  State<EnterpriseDashboardDesktop> createState() => _EnterpriseDashboardDesktopState();
}

class _EnterpriseDashboardDesktopState extends State<EnterpriseDashboardDesktop> with SingleTickerProviderStateMixin {
  final TenantService _tenantService = TenantService();
  late AppConfiguration _currentConfig;
  bool _isLoading = true;
  List<Branch> _branches = [];
  Tenant? _currentTenant;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedAnalyticsDate = DateTime.now();

  // Mock aggregated metrics
  int _totalSystemOrders = 0;
  double _totalSystemRevenue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    
    // Trigger load of all orders for analytics
    context.read<OrderBloc>().add(const LoadOrders());
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = context.read<OrderBloc>().configurationRepository;
    final config = await repo.getConfiguration();
    
    // Force clear branch ID if we are in Enterprise View
    if (config.branchId != null) {
       final newConfig = config.copyWith(branchId: null);
       // However, since we are IN EnterpriseDashboard, we don't strictly *need* to clear it in config
       // unless we want subsequent launches to default here. 
       // For now, just use local state.
    }

    // Get Tenant
    final tenants = _tenantService.getTenants();
    try {
      _currentTenant = tenants.firstWhere((t) => t.id == config.tenantId);
      
      // Load Branches
      _branches = await _tenantService.getBranchesForTenant(config.tenantId ?? '');
      
      // Calculate Aggregates
      final orderState = context.read<OrderBloc>().state;
      if (orderState is OrdersLoaded) {
        _recalculateMetricsWithoutSetState(orderState.orders);
      } else {
        _totalSystemOrders = _branches.fold(0, (sum, b) => sum + b.totalOrders);
        _totalSystemRevenue = _branches.fold(0, (sum, b) => sum + b.revenue);
      }
      
    } catch (e) {
      // Handle error
    }

    if (mounted) {
      setState(() {
        _currentConfig = config;
        _isLoading = false;
      });
    }
  }

  void _navigateToBranch(Branch branch) async {
    // 1. Update Configuration with Branch ID
    final repo = context.read<OrderBloc>().configurationRepository;
    var config = await repo.getConfiguration();
    
    config = config.copyWith(
      branchId: branch.id,
      // Keep tier as enterprise
    );
    await repo.saveConfiguration(config);

    if (mounted) {
      context.read<OrderBloc>().add(const LoadOrders()); // Fetch branch-isolated orders
    }

    // 2. Navigate to StaffPanel
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StaffPanel()),
      ).then((_) async {
        // Clear branch context when returning to Enterprise Dashboard
        var exitConfig = await repo.getConfiguration();
        exitConfig = exitConfig.copyWith(clearBranchId: true, branchId: null);
        await repo.saveConfiguration(exitConfig);
        
        if (mounted) {
          context.read<OrderBloc>().add(const LoadOrders());
          _loadData(); // Reload UI
        }
      });
    }
  }

  void _recalculateMetricsWithoutSetState(List<Order> orders) {
    double totalRev = 0;
    int totalOrd = 0;
    Map<String, double> branchRev = {};
    Map<String, int> branchOrd = {};
    
    for (var order in orders) {
      final isSameDay = order.timestamp.year == _selectedDate.year &&
                        order.timestamp.month == _selectedDate.month &&
                        order.timestamp.day == _selectedDate.day;
      if (!isSameDay) continue;

      totalOrd++;
      totalRev += order.total;
      if (order.branchId != null) {
        branchRev[order.branchId!] = (branchRev[order.branchId!] ?? 0) + order.total;
        branchOrd[order.branchId!] = (branchOrd[order.branchId!] ?? 0) + 1;
      }
    }

    _totalSystemOrders = totalOrd;
    _totalSystemRevenue = totalRev;
    _branches = _branches.map((b) => b.copyWith(
      revenue: branchRev[b.id] ?? 0.0,
      totalOrders: branchOrd[b.id] ?? 0,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tenantId = _currentConfig.tenantId ?? '';

    // 1. Maintenance Mode Check
    final isMaintenance = _tenantService.isModuleUnderMaintenance('enterprise_dashboard');
    final isGlobalMaintenance = _tenantService.isMaintenanceMode;
    bool isTenantMaintenance = _currentTenant?.isMaintenanceMode ?? false;

    // Check immunity
    final isImmune = _tenantService.isTenantImmune(
      tenantId,
      fallbackTierId: _currentConfig.tierId,
    );

    // Bypass for super admin (usually done via id check)
    final isSuperAdmin = _tenantService.isSuperAdmin(tenantId);

    if ((isMaintenance || isGlobalMaintenance || isTenantMaintenance) && !isImmune && !isSuperAdmin) {
      return const MaintenanceScreen();
    }

    // 2. Account Disabled Check
    if (!_tenantService.isTenantEnabled(tenantId) && !isSuperAdmin) {
      return const AccountDisabledScreen();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrdersLoaded) {
            setState(() {
              _recalculateMetricsWithoutSetState(state.orders);
            });
          }
        },
        child: Row(
          children: [
          // ─── LEFT SIDEBAR ────────────────────────────────────────────────
          Container(
            width: 250,
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo / Tenant Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a237e),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_center, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentTenant?.businessName ?? 'Enterprise',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Navigation Items
                _buildNavItem(0, 'Overview', Icons.dashboard_rounded, isDarkMode),
                _buildNavItem(1, 'Analytics', Icons.bar_chart_rounded, isDarkMode),
                _buildNavItem(2, 'Branches', Icons.store_mall_directory_rounded, isDarkMode),
                _buildNavItem(3, 'Settings', Icons.settings_rounded, isDarkMode), // Placeholder
                
                const Spacer(),
                const Divider(),
                 ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
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
                      // Clear configuration (Logout)
                      final repo = context.read<OrderBloc>().configurationRepository;
                      await repo.saveConfiguration(AppConfiguration()); // Reset to default

                      // Clear orders from state to prevent data bleeding
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
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // ─── MAIN CONTENT ────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 70,
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Text(
                        _getTabTitle(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      // User Profile
                      Row(
                        children: [
                           CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person, color: Colors.grey),
                           ),
                           const SizedBox(width: 12),
                           Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(_currentTenant?.name ?? 'Admin', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode?Colors.white:Colors.black)),
                               Text('Enterprise Admin', style: TextStyle(fontSize: 10, color: Colors.grey)),
                             ],
                           )
                        ],
                      )
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe
                    children: [
                      _buildOverviewTab(isDarkMode),
                      _buildAnalyticsTab(isDarkMode),
                      _buildBranchesTab(isDarkMode),
                      const Center(child: Text('Settings Placeholder')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  String _getTabTitle() {
    switch(_selectedTabIndex) {
      case 0: return 'Command Center';
      case 1: return 'Performance Analytics';
      case 2: return 'Branch Network';
      case 3: return 'Enterprise Settings';
      default: return 'Dashboard';
    }
  }

  Widget _buildNavItem(int index, String title, IconData icon, bool isDarkMode) {
    final isSelected = _selectedTabIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1a237e).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? const Color(0xFF1a237e) : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
                ? const Color(0xFF1a237e) 
                : (isDarkMode ? Colors.white70 : Colors.grey[700]),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _tabController.animateTo(index);
          });
        },
      ),
    );
  }

  // ─── TABS ───────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Metrics & Quick Actions
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Text(
                         'Overview for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                         style: TextStyle(
                           fontSize: 20, 
                           fontWeight: FontWeight.bold,
                           color: isDarkMode ? Colors.white : Colors.black87
                         ),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     OutlinedButton.icon(
                       onPressed: () async {
                         final orderState = context.read<OrderBloc>().state;
                         Set<DateTime> activeDates = {};
                         if (orderState is OrdersLoaded) {
                           activeDates = orderState.orders.map((o) => DateTime(o.timestamp.year, o.timestamp.month, o.timestamp.day)).toSet();
                         }
                         
                         final today = DateTime.now();
                         final todayDate = DateTime(today.year, today.month, today.day);

                         final picked = await showDatePicker(
                           context: context,
                           initialDate: _selectedDate,
                           firstDate: DateTime(2000),
                           lastDate: DateTime.now().add(const Duration(days: 365)),
                           selectableDayPredicate: (day) {
                             final checkDate = DateTime(day.year, day.month, day.day);
                             if (checkDate == todayDate) return true; // Always allow selecting today
                             return activeDates.contains(checkDate);
                           },
                         );
                         if (picked != null && mounted) {
                           setState(() {
                             _selectedDate = picked;
                             if (orderState is OrdersLoaded) {
                               _recalculateMetricsWithoutSetState(orderState.orders);
                             }
                           });
                         }
                       },
                       icon: const Icon(Icons.calendar_today, size: 18),
                       label: const Text('Select Date'),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 // Metrics Row
                 Row(
                   children: [
                     _buildMetricCard('Total Revenue', 'KSh ${NumberFormat('#,##0').format(_totalSystemRevenue)}', Icons.attach_money, Colors.green, isDarkMode),
                     const SizedBox(width: 16),
                     _buildMetricCard('Total Orders', '$_totalSystemOrders', Icons.shopping_bag, Colors.blue, isDarkMode),
                     const SizedBox(width: 16),
                     _buildMetricCard('Active Branches', '${_branches.where((b)=>b.isActive).length}', Icons.store, Colors.orange, isDarkMode),
                   ],
                 ),
                 const SizedBox(height: 32),
                 
                 // Recent Activity Section Header
                 Text(
                   'Live Order Feed',
                   style: TextStyle(
                     fontSize: 18, 
                     fontWeight: FontWeight.bold,
                     color: isDarkMode ? Colors.white : Colors.black87
                   ),
                 ),
                 const SizedBox(height: 16),
                 
                 // Feed Widget
                 Expanded(
                   child: Container(
                     decoration: BoxDecoration(
                       color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                       ]
                     ),
                     child: EnterpriseFeed(isDarkMode: isDarkMode, selectedDate: _selectedDate),
                   ),
                 ),
              ],
            ),
          ),
          
          const SizedBox(width: 32),
          
          // Right: Top Performing Branches (Mini Leaderboard)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   'Top Branches',
                   style: TextStyle(
                     fontSize: 18, 
                     fontWeight: FontWeight.bold,
                     color: isDarkMode ? Colors.white : Colors.black87
                   ),
                 ),
                 const SizedBox(height: 16),
                 Container(
                   decoration: BoxDecoration(
                       color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                       ]
                   ),
                   child: ListView.separated(
                     shrinkWrap: true,
                     itemCount: _branches.take(5).length,
                     separatorBuilder: (c,i) => const Divider(height: 1),
                     itemBuilder: (context, index) {
                       // Sort branches by revenue descending
                       final sortedBranches = List<Branch>.from(_branches)
                          ..sort((a,b) => b.revenue.compareTo(a.revenue));
                       final branch = sortedBranches[index];
                       
                       return ListTile(
                         leading: CircleAvatar(
                           backgroundColor: const Color(0xFF1a237e).withValues(alpha: 0.1),
                           child: Text('${index+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
                         ),
                         title: Text(branch.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                         trailing: Text(
                           'KSh ${NumberFormat.compact().format(branch.revenue)}',
                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                         ),
                       );
                     },
                   ),
                 )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isDarkMode) {
    // Collect order analytics based on current selected date
    final orderState = context.read<OrderBloc>().state;
    List<Order> dateOrders = [];
    if (orderState is OrdersLoaded) {
      dateOrders = orderState.orders.where((o) =>
          o.timestamp.year == _selectedAnalyticsDate.year &&
          o.timestamp.month == _selectedAnalyticsDate.month &&
          o.timestamp.day == _selectedAnalyticsDate.day).toList();
    }

    // 1. Hourly Data
    final hourlyOrders = List.filled(24, 0);
    for (var o in dateOrders) {
      hourlyOrders[o.timestamp.hour]++;
    }

    // 2. Category Metrics (Derived from synthetic ratios for creative viz, as item data is granular)
    Map<String, double> categoryAcct = {
      'Flour': 0, 'Oil': 0, 'Sugar': 0, 'Other': 0
    };
    for (var o in dateOrders) {
      categoryAcct['Flour'] = (categoryAcct['Flour'] ?? 0) + o.total * 0.45;
      categoryAcct['Oil'] = (categoryAcct['Oil'] ?? 0) + o.total * 0.30;
      categoryAcct['Sugar'] = (categoryAcct['Sugar'] ?? 0) + o.total * 0.15;
      categoryAcct['Other'] = (categoryAcct['Other'] ?? 0) + o.total * 0.10;
    }

    // 3. Peak Hour
    int peakHour = 0;
    int maxOrders = 0;
    for (int i = 0; i < 24; i++) {
       if (hourlyOrders[i] > maxOrders) {
         maxOrders = hourlyOrders[i];
         peakHour = i;
       }
    }
    
    // KPI metrics
    final totalRev = dateOrders.fold(0.0, (sum, o) => sum + o.total);
    final avgOrderValue = dateOrders.isEmpty ? 0.0 : totalRev / dateOrders.length;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                 child: Text(
                   'Analytics (${DateFormat('MMM d, yyyy').format(_selectedAnalyticsDate)})',
                   style: TextStyle(
                     fontSize: 24, 
                     fontWeight: FontWeight.bold,
                     color: isDarkMode ? Colors.white : Colors.black87
                   ),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               OutlinedButton.icon(
                 onPressed: () async {
                   final orderState = context.read<OrderBloc>().state;
                   Set<DateTime> activeDates = {};
                   if (orderState is OrdersLoaded) {
                     activeDates = orderState.orders.map((o) => DateTime(o.timestamp.year, o.timestamp.month, o.timestamp.day)).toSet();
                   }
                   
                   final today = DateTime.now();
                   final todayDate = DateTime(today.year, today.month, today.day);

                   final picked = await showDatePicker(
                     context: context,
                     initialDate: _selectedAnalyticsDate,
                     firstDate: DateTime(2000),
                     lastDate: DateTime.now().add(const Duration(days: 365)),
                     selectableDayPredicate: (day) {
                       final checkDate = DateTime(day.year, day.month, day.day);
                       if (checkDate == todayDate) return true;
                       return activeDates.contains(checkDate);
                     },
                   );
                   if (picked != null && mounted) {
                     setState(() {
                       _selectedAnalyticsDate = picked;
                     });
                   }
                 },
                 icon: const Icon(Icons.calendar_today, size: 18),
                 label: const Text('Select Date'),
               ),
               const SizedBox(width: 24),
               // Quick KPI Cards
               Expanded(
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                      _buildMiniKpi('Avg Order Value', 'KSh ${NumberFormat('#,##0').format(avgOrderValue)}', Icons.receipt_long, Colors.purple, isDarkMode),
                      const SizedBox(width: 16),
                      _buildMiniKpi('Peak Volume Hour', '${peakHour.toString().padLeft(2, '0')}:00', Icons.access_time, Colors.orange, isDarkMode),
                   ],
                 ),
               )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                // Hourly Trends Chart
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Orders by Time of Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: HourlyOrdersChart(data: hourlyOrders, isDarkMode: isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Category Donut Chart
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: CategoryDonutChart(data: categoryAcct, isDarkMode: isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ),
          const SizedBox(height: 24),
          // Branch Revenue
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branch Revenue Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BranchRevenueChart(
                      data: () {
                         Map<String, double> chartData = {};
                         Map<String, double> branchRevMap = {};
                         for (var o in dateOrders) {
                           if (o.branchId != null) {
                             branchRevMap[o.branchId!] = (branchRevMap[o.branchId!] ?? 0.0) + o.total;
                           }
                         }
                         for (var b in _branches) {
                           final rev = branchRevMap[b.id] ?? 0.0;
                           if (rev > 0) {
                             chartData[b.name] = rev;
                           }
                         }
                         return chartData;
                      }(),
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpi(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white70 : Colors.grey[600]), overflow: TextOverflow.ellipsis),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBranchesTab(bool isDarkMode) {
     return Padding(
       padding: const EdgeInsets.all(32),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Expanded(
                   child: Text(
                     'All Branches',
                     style: TextStyle(
                       fontSize: 18, 
                       fontWeight: FontWeight.bold,
                       color: isDarkMode ? Colors.white : Colors.black87
                     ),
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
                 ElevatedButton.icon(
                   onPressed: () {
                     _showAddEditBranchDialog(context);
                   },
                   icon: const Icon(Icons.add),
                   label: const Text('Add Branch'),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF1a237e),
                     foregroundColor: Colors.white,
                   ),
                 )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.5,
                ),
                itemCount: _branches.length,
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  return _buildBranchCard(branch, isDarkMode);
                },
              ),
            ),
         ],
       ),
     );
  }

  Future<void> _showAddEditBranchDialog(BuildContext context, {Branch? branch}) async {
    final isEditing = branch != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: branch?.name);
    final locationController = TextEditingController(text: branch?.location);
    final phoneController = TextEditingController(text: branch?.contactPhone);
    final managerController = TextEditingController(text: branch?.managerName);
    final usernameController = TextEditingController(text: branch?.loginUsername);
    final passwordController = TextEditingController(text: branch?.loginPassword);
    
    // Auto-generate ID if not editing
    final branchId = isEditing ? branch.id : 'BR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Branch' : 'Add New Branch'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Branch Name', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Manager Credentials', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: managerController,
                    decoration: const InputDecoration(labelText: 'Manager Name', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Login Username', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Login Password', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                final updatedBranch = branch?.copyWith(
                  name: nameController.text,
                  location: locationController.text,
                  contactPhone: phoneController.text,
                  managerName: managerController.text,
                  loginUsername: usernameController.text,
                  loginPassword: passwordController.text,
                ) ?? Branch(
                  id: branchId,
                  tenantId: _currentConfig.tenantId ?? '',
                  name: nameController.text,
                  location: locationController.text,
                  contactPhone: phoneController.text,
                  managerName: managerController.text,
                  loginUsername: usernameController.text,
                  loginPassword: passwordController.text,
                );
                
                if (isEditing) {
                  await _tenantService.updateBranch(updatedBranch);
                } else {
                  await _tenantService.addBranch(updatedBranch);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadData(); // Refresh list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? 'Branch updated successfully' : 'Branch added successfully')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Save Changes' : 'Create Branch'),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(Branch branch, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
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
                      color: const Color(0xFF1a237e).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: Color(0xFF1a237e)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: branch.isActive ? Colors.green[50] : Colors.red[50],
                       borderRadius: BorderRadius.circular(4),
                       border: Border.all(color: branch.isActive ? Colors.green : Colors.red),
                     ),
                     child: Text(branch.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: branch.isActive ? Colors.green : Colors.red)),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) async {
                  if (val == 'edit') {
                    _showAddEditBranchDialog(context, branch: branch);
                  } else if (val == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Branch'),
                        content: Text('Are you sure you want to delete ${branch.name}? This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await _tenantService.deleteBranch(branch.id);
                      _loadData();
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Branch')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete Branch', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(branch.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
          Text(branch.location, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey[600])),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _navigateToBranch(branch), 
              child: const Text('Access Branch Panel'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.05),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title, 
                    style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value, 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_desktop.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/widgets/enterprise_charts.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/widgets/enterprise_feed.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen_desktop.dart';
import 'package:kfm_kiosk/features/settings/presentation/screens/maintenance_screen.dart';
import 'package:kfm_kiosk/features/auth/presentation/screens/account_disabled_screen.dart';

class EnterpriseDashboard extends StatefulWidget {
  const EnterpriseDashboard({super.key});

  @override
  State<EnterpriseDashboard> createState() => _EnterpriseDashboardState();
}

class _EnterpriseDashboardState extends State<EnterpriseDashboard> with SingleTickerProviderStateMixin {
  final TenantService _tenantService = TenantService();
  late AppConfiguration _currentConfig;
  bool _isLoading = true;
  List<Branch> _branches = [];
  Tenant? _currentTenant;
  late TabController _tabController;
  int _selectedTabIndex = 0;

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
      _branches = _tenantService.getBranchesForTenant(config.tenantId ?? '');
      
      // Calculate Aggregates
      _totalSystemOrders = _branches.fold(0, (sum, b) => sum + b.totalOrders);
      _totalSystemRevenue = _branches.fold(0, (sum, b) => sum + b.revenue);
      
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

    // 2. Navigate to StaffPanel
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StaffPanelDesktop()),
      ).then((_) => _loadData()); // Reload when coming back
    }
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
      body: Row(
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
                          MaterialPageRoute(builder: (_) => const LoginScreenDesktop()),
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
    );
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
                     child: EnterpriseFeed(isDarkMode: isDarkMode),
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
    // Prepare Data for Chart
    final Map<String, double> revenueData = {};
    for (var b in _branches) {
      if (b.revenue > 0) {
        revenueData[b.name] = b.revenue;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
             'Branch Revenue Comparison',
             style: TextStyle(
               fontSize: 18, 
               fontWeight: FontWeight.bold,
               color: isDarkMode ? Colors.white : Colors.black87
             ),
           ),
           const SizedBox(height: 24),
           Expanded(
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
               child: BranchRevenueChart(
                 data: revenueData,
                 isDarkMode: isDarkMode,
               ),
             ),
           ),
        ],
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
                 Text(
                   'All Branches',
                   style: TextStyle(
                     fontSize: 18, 
                     fontWeight: FontWeight.bold,
                     color: isDarkMode ? Colors.white : Colors.black87
                   ),
                 ),
                 ElevatedButton.icon(
                   onPressed: () {
                     // Show contact super admin dialog
                     showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add New Branch'),
                          content: const Text(
                              'Please contact your System Administrator to provision additional branches for your Enterprise license.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'))
                          ],
                        ),
                      );
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a237e).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Color(0xFF1a237e)),
              ),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: branch.isActive ? Colors.green[50] : Colors.red[50],
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: branch.isActive ? Colors.green : Colors.red),
                 ),
                 child: Text(branch.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: branch.isActive ? Colors.green : Colors.red)),
              )
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey[600], fontSize: 12)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

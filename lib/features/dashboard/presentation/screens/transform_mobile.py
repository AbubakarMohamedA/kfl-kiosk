import re

with open("enterprise_dashboard_mobile.dart", "r") as f:
    text = f.read()

# 1. Rename classes
text = text.replace("EnterpriseDashboardDesktop", "EnterpriseDashboardMobile")

# 2. Replace the build method
build_pattern = re.compile(r'Widget build\(BuildContext context\) \{.*?\n  \}\n\n  String _getTabTitle', re.DOTALL)
new_build = """Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: Text(
          _getTabTitle(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      drawer: Drawer(
        child: Container(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 50),
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
                    final repo = context.read<OrderBloc>().configurationRepository;
                    await repo.saveConfiguration(AppConfiguration()); 
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
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrdersLoaded) {
            setState(() {
              _recalculateMetricsWithoutSetState(state.orders);
            });
          }
        },
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildOverviewTab(isDarkMode),
            _buildAnalyticsTab(isDarkMode),
            _buildBranchesTab(isDarkMode),
            const Center(child: Text('Settings Placeholder')),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: const Color(0xFF1a237e),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
            _tabController.animateTo(index);
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.store_mall_directory_rounded), label: 'Branches'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  String _getTabTitle"""
text = build_pattern.sub(new_build, text)

# 3. Replace _buildOverviewTab
overview_pattern = re.compile(r'Widget _buildOverviewTab\(bool isDarkMode\) \{.*?  Widget _buildAnalyticsTab', re.DOTALL)
new_overview = """Widget _buildOverviewTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87
                  ),
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
                      if (checkDate == todayDate) return true; 
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
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(DateFormat('MMM d').format(_selectedDate), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metrics in a column for mobile
          _buildMetricCard('Total Revenue', 'KSh ${NumberFormat.compact().format(_totalSystemRevenue)}', Icons.attach_money, Colors.green, isDarkMode),
          const SizedBox(height: 8),
          _buildMetricCard('Total Orders', '$_totalSystemOrders', Icons.shopping_bag, Colors.blue, isDarkMode),
          const SizedBox(height: 8),
          _buildMetricCard('Active Branches', '${_branches.where((b)=>b.isActive).length}', Icons.store, Colors.orange, isDarkMode),
          const SizedBox(height: 24),
          
          Text(
            'Live Order Feed',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
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
          const SizedBox(height: 24),
          
          Text(
            'Top Branches',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87
            ),
          ),
          const SizedBox(height: 12),
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _branches.take(5).length,
              separatorBuilder: (c,i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sortedBranches = List<Branch>.from(_branches)
                   ..sort((a,b) => b.revenue.compareTo(a.revenue));
                final branch = sortedBranches[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1a237e).withValues(alpha: 0.1),
                    child: Text('${index+1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
                  ),
                  title: Text(branch.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  trailing: Text(
                    'KSh ${NumberFormat.compact().format(branch.revenue)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab"""
text = overview_pattern.sub(new_overview, text)

# 4. Replace _buildAnalyticsTab
analytics_pattern = re.compile(r'Widget _buildAnalyticsTab\(bool isDarkMode\) \{.*?  Widget _buildMiniKpi', re.DOTALL)
new_analytics = """Widget _buildAnalyticsTab(bool isDarkMode) {
    final orderState = context.read<OrderBloc>().state;
    List<Order> dateOrders = [];
    if (orderState is OrdersLoaded) {
      dateOrders = orderState.orders.where((o) =>
          o.timestamp.year == _selectedAnalyticsDate.year &&
          o.timestamp.month == _selectedAnalyticsDate.month &&
          o.timestamp.day == _selectedAnalyticsDate.day).toList();
    }

    final hourlyOrders = List.filled(24, 0);
    for (var o in dateOrders) {
      hourlyOrders[o.timestamp.hour]++;
    }

    Map<String, double> categoryAcct = {
      'Flour': 0, 'Oil': 0, 'Sugar': 0, 'Other': 0
    };
    for (var o in dateOrders) {
      categoryAcct['Flour'] = (categoryAcct['Flour'] ?? 0) + o.total * 0.45;
      categoryAcct['Oil'] = (categoryAcct['Oil'] ?? 0) + o.total * 0.30;
      categoryAcct['Sugar'] = (categoryAcct['Sugar'] ?? 0) + o.total * 0.15;
      categoryAcct['Other'] = (categoryAcct['Other'] ?? 0) + o.total * 0.10;
    }

    int peakHour = 0;
    int maxOrders = 0;
    for (int i = 0; i < 24; i++) {
       if (hourlyOrders[i] > maxOrders) {
         maxOrders = hourlyOrders[i];
         peakHour = i;
       }
    }
    
    final totalRev = dateOrders.fold(0.0, (sum, o) => sum + o.total);
    final avgOrderValue = dateOrders.isEmpty ? 0.0 : totalRev / dateOrders.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                 child: Text(
                   'Analytics',
                   style: TextStyle(
                     fontSize: 18, 
                     fontWeight: FontWeight.bold,
                     color: isDarkMode ? Colors.white : Colors.black87
                   ),
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
                 icon: const Icon(Icons.calendar_today, size: 16),
                 label: Text(DateFormat('MMM d').format(_selectedAnalyticsDate), style: const TextStyle(fontSize: 12)),
               ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMiniKpi('Avg Order Value', 'KSh ${NumberFormat.compact().format(avgOrderValue)}', Icons.receipt_long, Colors.purple, isDarkMode),
          const SizedBox(height: 8),
          _buildMiniKpi('Peak Volume Hour', '${peakHour.toString().padLeft(2, '0')}:00', Icons.access_time, Colors.orange, isDarkMode),
          const SizedBox(height: 24),
          
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
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
                Text('Orders by Time of Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87)),
                const SizedBox(height: 12),
                Expanded(child: HourlyOrdersChart(data: hourlyOrders, isDarkMode: isDarkMode)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
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
                Text('Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87)),
                const SizedBox(height: 12),
                Expanded(child: CategoryDonutChart(data: categoryAcct, isDarkMode: isDarkMode)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
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
                Text('Branch Revenue Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 12),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMiniKpi"""
text = analytics_pattern.sub(new_analytics, text)

# 5. Fix _buildMiniKpi
mini_kpi_pattern = re.compile(r'Widget _buildMiniKpi\(String title, String value, IconData icon, Color color, bool isDarkMode\) \{.*?  \}', re.DOTALL)
new_mini_kpi = """Widget _buildMiniKpi(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.grey[600]), overflow: TextOverflow.ellipsis),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }"""
text = mini_kpi_pattern.sub(new_mini_kpi, text)

# 6. Replace _buildBranchesTab
branches_pattern = re.compile(r'Widget _buildBranchesTab\(bool isDarkMode\) \{.*?  Future<void> _showAddEditBranchDialog', re.DOTALL)
new_branches = """Widget _buildBranchesTab(bool isDarkMode) {
     return Padding(
       padding: const EdgeInsets.all(16),
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
                   icon: const Icon(Icons.add, size: 16),
                   label: const Text('Add', style: TextStyle(fontSize: 12)),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF1a237e),
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                   ),
                 )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _branches.length,
                separatorBuilder: (c,i) => const SizedBox(height: 12),
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

  Future<void> _showAddEditBranchDialog"""
text = branches_pattern.sub(new_branches, text)

# 7. Replace _buildMetricCard
metric_card_pattern = re.compile(r'Widget _buildMetricCard\(String title, String value, IconData icon, Color color, bool isDarkMode\) \{.*\}', re.DOTALL)
new_metric_card = """Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
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
    );
  }
}"""
text = metric_card_pattern.sub(new_metric_card, text)

# Remove the unused _buildNavItem since we use bottomnav
text = re.compile(r'Widget _buildNavItem\(int index, String title, IconData icon, bool isDarkMode\) \{.*?  \}', re.DOTALL).sub('', text)

with open("enterprise_dashboard_mobile.dart", "w") as f:
    f.write(text)


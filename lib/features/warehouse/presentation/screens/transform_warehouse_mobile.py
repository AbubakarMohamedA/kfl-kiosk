import re

with open("staff_panel_warehouse_mobile.dart", "r") as f:
    text = f.read()

# 1. Rename classes
text = text.replace("StaffPanelWarehouse", "StaffPanelWarehouseMobile")

# 2. Add BottomNavigationBar state and replace build
insert_state_pattern = re.compile(r'int _pendingItemsCount = 0;\n', re.MULTILINE)
text = insert_state_pattern.sub("int _pendingItemsCount = 0;\n  int _selectedBottomNavIndex = 0;\n", text)

# Ensure _autoRefreshTimer avoids refreshing if in History tab (which is index 1)
refresh_pattern = re.compile(r'if \(mounted && !_showHistory\) \{')
text = refresh_pattern.sub(r'if (mounted && _selectedBottomNavIndex == 0) {', text)

# Replace build method to use Scaffold with BottomNavigationBar
build_pattern = re.compile(r'Widget build\(BuildContext context\) \{.*?  Widget _buildWarehouseHeader', re.DOTALL)
new_build = """Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F1419) : Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildWarehouseHeader(),
      ),
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
        child: IndexedStack(
          index: _selectedBottomNavIndex,
          children: [
            // 0: Active Pickups
            Column(
              children: [
                _buildDashboardTitle(),
                _buildSearchAndFilterBar(),
                Expanded(child: _buildActiveOrdersView()),
              ],
            ),
            // 1: History
            Column(
              children: [
                _buildHistoryHeader(),
                Expanded(child: _buildHistoryView()),
              ],
            ),
            // 2: Stats
            _buildStatsPanel(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        backgroundColor: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        selectedItemColor: _getWarehouseColor(),
        unselectedItemColor: _isDarkMode ? Colors.white60 : Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedBottomNavIndex = index;
            // Align internal expected state with nav index where needed
            if (index == 1) {
              _showHistory = true;
            } else {
              _showHistory = false;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Active Pickups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseHeader"""

text = build_pattern.sub(new_build, text)

# 3. Simplify the header for mobile size (hide clock/theme text, just icons)
header_pattern = re.compile(r'Widget _buildWarehouseHeader\(.*?  Widget _buildHeaderIconButton', re.DOTALL)
new_header = """Widget _buildWarehouseHeader() {
    final color = _getWarehouseColor();
    final icon = _getWarehouseIcon();
    
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: color,
      elevation: 2,
      title: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.warehouse.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy - HH:mm:ss').format(_currentTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildHeaderIconButton(
          icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
          tooltip: 'Theme',
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
        ),
        _buildHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onPressed: () => context.read<OrderBloc>().add(const LoadOrders()),
        ),
        _buildHeaderIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          badge: _pendingItemsCount > 0 ? '$_pendingItemsCount' : null,
          onPressed: () => _showNotificationsDialog(),
        ),
        _buildHeaderIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Logout',
          onPressed: () => _handleLogout(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderIconButton"""
text = header_pattern.sub(new_header, text)

# We simplified the HeaderIconButton for appbar action sizing
header_icon_btn_pattern = re.compile(r'Widget _buildHeaderIconButton.*?  Widget _buildSidebar', re.DOTALL)
new_header_icon_btn = """Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    String? badge,
    required VoidCallback onPressed,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 22),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
        if (badge != null)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebar"""

text = header_icon_btn_pattern.sub(new_header_icon_btn, text)

# 4. Remove sidebar (we use bottomnav now)
# Find _buildSidebar and completely remove or comment out / ignore it because it's no longer used, but let's just make it return empty container to avoid dangling references if any
sidebar_pattern = re.compile(r'Widget _buildSidebar\(\) \{.*?  Widget _buildSidebarItem\(\{', re.DOTALL)
text = sidebar_pattern.sub(r'Widget _buildSidebar() { return const SizedBox.shrink(); }\n\n  Widget _buildSidebarItem({', text)

# 5. Fix Stats Panel styling for full screen mobile view
stats_pattern = re.compile(r'Widget _buildStatsPanel\(\) \{.*?  Widget _buildStatCard', re.DOTALL)
new_stats = """Widget _buildStatsPanel() {
    final color = _getWarehouseColor();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(16),
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
                          'Today\\'s Summary',
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

  Widget _buildStatCard"""
text = stats_pattern.sub(new_stats, text)

# 6. Grid changes: Use 1 column for orders on mobile
active_grid_pattern = re.compile(r'gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent\([\s\S]*?maxCrossAxisExtent: 400,[\s\S]*?childAspectRatio: 1.2,')
text = active_grid_pattern.sub('gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(\n                              crossAxisCount: 1,\n                              mainAxisExtent: 320, // fixed height for order card in list', text)

history_grid_pattern = re.compile(r'gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent\([\s\S]*?maxCrossAxisExtent: 400,[\s\S]*?childAspectRatio: 1.2,')
text = history_grid_pattern.sub('gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(\n                            crossAxisCount: 1,\n                            mainAxisExtent: 320,', text)


with open("staff_panel_warehouse_mobile.dart", "w") as f:
    f.write(text)


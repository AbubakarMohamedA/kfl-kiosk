import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TenantService _tenantService = TenantService();
  String _searchQuery = '';
  List<Tenant> _tenants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTenants();
  }

  void _loadTenants() {
    setState(() {
      _tenants = _tenantService.getTenants();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Tenant> get _filteredTenants {
    if (_searchQuery.isEmpty) return _tenants;
    return _tenants.where((tenant) {
      final query = _searchQuery.toLowerCase();
      return tenant.name.toLowerCase().contains(query) ||
          tenant.businessName.toLowerCase().contains(query) ||
          tenant.email.toLowerCase().contains(query) ||
          tenant.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTenantListTab(),
                      _buildAnalyticsTab(),
                      _buildSettingsTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a237e), // Deep indigo for super admin
            const Color(0xFF283593),
          ],
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Super Admin Panel',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Manage tenants and system settings',
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          _buildHeaderStat('Total Tenants', '${_tenants.length}', Icons.people),
          const SizedBox(width: 16),
          _buildHeaderStat(
              'Active',
              '${_tenants.where((t) => t.status == 'Active').length}',
              Icons.check_circle),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTenantDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Tenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1a237e),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          _buildSidebarItem(0, Icons.people_outline, 'Tenants'),
          _buildSidebarItem(1, Icons.analytics_outlined, 'Analytics'),
          _buildSidebarItem(2, Icons.settings_outlined, 'Settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildQuickStat(
                    'Active',
                    '${_tenants.where((t) => t.status == 'Active').length}',
                    Icons.check_circle,
                    Colors.green),
                const SizedBox(height: 12),
                _buildQuickStat(
                    'Pending',
                    '${_tenants.where((t) => t.status == 'Pending').length}',
                    Icons.pending,
                    Colors.orange),
                const SizedBox(height: 12),
                _buildQuickStat(
                    'Inactive',
                    '${_tenants.where((t) => t.status == 'Inactive').length}',
                    Icons.cancel,
                    Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1a237e).withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
              left: BorderSide(
                  color:
                      isSelected ? const Color(0xFF1a237e) : Colors.transparent,
                  width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF1a237e) : Colors.grey[600],
                size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF1a237e)
                        : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantListTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, business, email, or ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12)),
                child: DropdownButton<String>(
                  value: 'All Status',
                  underline: const SizedBox.shrink(),
                  items: ['All Status', 'Active', 'Inactive', 'Pending']
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Tenants',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_filteredTenants.length}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._filteredTenants.map((tenant) => _buildTenantCard(tenant)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTenantCard(Tenant tenant) {
    final statusColor = tenant.status == 'Active'
        ? Colors.green
        : tenant.status == 'Pending'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: const Color(0xFF1a237e).withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Center(
                child: Text(
                    tenant.name
                        .toString()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a237e)))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tenant.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tenant.status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    if (tenant.tier == TenantTier.premium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.purple),
                            SizedBox(width: 4),
                            Text('PREMIUM',
                                style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (tenant.isMaintenanceMode)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                            SizedBox(width: 4),
                            Text('MAINTENANCE',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${tenant.businessName} • ${tenant.id}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(tenant.email,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(tenant.phone,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('KSh ${NumberFormat('#,###').format(tenant.revenue)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a237e))),
              Text('${tenant.ordersCount} orders',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                  'Joined ${DateFormat('MMM d, yyyy').format(tenant.createdDate)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(width: 24),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditTenantDialog(tenant);
                  break;
                case 'view':
                  _showTenantDetailsDialog(tenant);
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(tenant);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Details')),
              const PopupMenuItem(value: 'edit', child: Text('Edit Tenant')),
              const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('Delete Tenant', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final stats = _tenantService.getStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildAnalyticsCard('Total Revenue',
                      'KSh ${NumberFormat('#,###').format(stats['totalRevenue'])}', Icons.attach_money, Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildAnalyticsCard('Total Orders', '${stats['totalOrders']}',
                      Icons.shopping_cart, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildAnalyticsCard('Active Tenants',
                      '${stats['activeTenants']}', Icons.people, Colors.purple)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildAnalyticsCard(
                      'Avg Revenue/Tenant',
                      'KSh ${NumberFormat('#,###').format(stats['avgRevenue'])}',
                      Icons.trending_up,
                      Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Top Performing Tenants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._tenants
              .where((t) => t.status == 'Active')
              .toList()
              .sublist(0, 3)
              .asMap()
              .entries
              .map((entry) => _buildTopTenantCard(entry.value, entry.key + 1)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTopTenantCard(Tenant tenant, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: rank == 1
                ? Colors.amber
                : rank == 2
                    ? Colors.grey[400]!
                    : Colors.orange[300]!,
            width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: rank == 1
                    ? Colors.amber
                    : rank == 2
                        ? Colors.grey[400]
                        : Colors.orange[300],
                shape: BoxShape.circle),
            child: Center(
                child: Text('#$rank',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tenant.businessName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(tenant.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('KSh ${NumberFormat('#,###').format(tenant.revenue)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingsCard('Default Tenant Settings', [
            _buildSettingsTile('Auto-approve new tenants', true),
            _buildSettingsTile('Send welcome email', true),
            _buildSettingsTile('Enable order notifications', true),
          ]),
          const SizedBox(height: 16),
          _buildSettingsCard('Security', [
            _buildSettingsTile('Two-factor authentication', false),
            _buildSettingsTile('Session timeout (30 min)', true),
            _buildSettingsTile('IP whitelisting', false),
          ]),
          const SizedBox(height: 16),
          _buildSettingsCard('Notifications', [
            _buildSettingsTile('Email notifications', true),
            _buildSettingsTile('SMS notifications', false),
            _buildSettingsTile('Push notifications', true),
          ]),
          const SizedBox(height: 16),
          _buildSettingsCard('System Control', [
            _buildSettingsTile(
              'Maintenance Mode (Full System)',
              _tenantService.isMaintenanceMode,
              onChanged: (val) {
                setState(() {
                  _tenantService.setMaintenanceMode(val);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(val
                        ? 'System is now in Maintenance Mode'
                        : 'System is back online'),
                    backgroundColor: val ? Colors.orange : Colors.green,
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSettingsCard('Module Maintenance', [
            _buildSettingsTile(
              'Orders Module',
              _tenantService.isModuleUnderMaintenance('orders'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('orders', val)),
            ),
            _buildSettingsTile(
              'Order History',
              _tenantService.isModuleUnderMaintenance('history'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('history', val)),
            ),
            _buildSettingsTile(
              'Business Insights',
              _tenantService.isModuleUnderMaintenance('insights'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('insights', val)),
            ),
            _buildSettingsTile(
              'Warehouse Stations',
              _tenantService.isModuleUnderMaintenance('warehouse'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('warehouse', val)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, bool value,
      {Function(bool)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Switch(
            value: value,
            onChanged: onChanged ?? (newValue) {},
            activeTrackColor: const Color(0xFF1a237e),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showAddTenantDialog() {
    final nameController = TextEditingController();
    final businessController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    TenantTier selectedTier = TenantTier.standard;
    List<String> enabledFeatures = ['orders', 'history', 'insights', 'warehouse'];
    final List<String> availableFeatures = ['orders', 'history', 'insights', 'warehouse'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Color(0xFF1a237e)),
              SizedBox(width: 12),
              Text('Add New Tenant'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: businessController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TenantTier>(
                    value: selectedTier,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Tier',
                      border: OutlineInputBorder(),
                    ),
                    items: TenantTier.values
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toString().split('.').last.toUpperCase())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedTier = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Feature Access', style: TextStyle(fontWeight: FontWeight.bold)),
                       Row(
                         children: [
                           TextButton(
                             onPressed: () {
                               setDialogState(() {
                                 enabledFeatures = List.from(availableFeatures);
                               });
                             },
                             child: const Text('Select All', style: TextStyle(fontSize: 12)),
                           ),
                           TextButton(
                             onPressed: () {
                               setDialogState(() {
                                 enabledFeatures.clear();
                               });
                             },
                             child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.grey)),
                           ),
                         ],
                       ),
                    ],
                  ),
                  ...availableFeatures.map((feature) {
                    final isEnabled = enabledFeatures.contains(feature);
                    return CheckboxListTile(
                      title: Text(feature[0].toUpperCase() + feature.substring(1)),
                      value: isEnabled,
                      activeColor: const Color(0xFF1a237e),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            enabledFeatures.add(feature);
                          } else {
                            enabledFeatures.remove(feature);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    businessController.text.isNotEmpty) {
                  
                  final newTenant = Tenant(
                    id: 'TEN${(_tenants.length + 1).toString().padLeft(3, '0')}', // Simple ID generation
                    name: nameController.text,
                    businessName: businessController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    status: 'Pending',
                    tier: selectedTier,
                    createdDate: DateTime.now(),
                    enabledFeatures: enabledFeatures,
                  );

                _tenantService.addTenant(newTenant);
                _loadTenants(); // Refresh UI

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Tenant added successfully'),
                      backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Tenant'),
          ),
        ],
      ),
    ),
  );
}

  void _showEditTenantDialog(Tenant tenant) {
    final nameController = TextEditingController(text: tenant.name);
    final businessController =
        TextEditingController(text: tenant.businessName);
    final emailController = TextEditingController(text: tenant.email);
    final phoneController = TextEditingController(text: tenant.phone);
    String status = tenant.status;
    TenantTier tier = tenant.tier;
    bool isMaintenanceMode = tenant.isMaintenanceMode;
    List<String> enabledFeatures = List.from(tenant.enabledFeatures);
    final List<String> availableFeatures = ['orders', 'history', 'insights', 'warehouse'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF1a237e)),
              SizedBox(width: 12),
              Text('Edit Tenant'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: businessController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Active', 'Inactive', 'Pending']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TenantTier>(
                    value: tier,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Tier',
                      border: OutlineInputBorder(),
                    ),
                    items: TenantTier.values
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toString().split('.').last.toUpperCase())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tier = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Maintenance Mode'),
                    subtitle: const Text('Restrict system access'),
                    value: isMaintenanceMode,
                    activeColor: Colors.red,
                    onChanged: (value) =>
                        setDialogState(() => isMaintenanceMode = value),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Feature Access', style: TextStyle(fontWeight: FontWeight.bold)),
                       Row(
                         children: [
                           TextButton(
                             onPressed: () {
                               setDialogState(() {
                                 enabledFeatures = List.from(availableFeatures);
                               });
                             },
                             child: const Text('Select All', style: TextStyle(fontSize: 12)),
                           ),
                           TextButton(
                             onPressed: () {
                               setDialogState(() {
                                 enabledFeatures.clear();
                               });
                             },
                             child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.grey)),
                           ),
                         ],
                       ),
                    ],
                  ),
                  ...availableFeatures.map((feature) {
                    final isEnabled = enabledFeatures.contains(feature);
                    return CheckboxListTile(
                      title: Text(feature[0].toUpperCase() + feature.substring(1)),
                      value: isEnabled,
                      activeColor: const Color(0xFF1a237e),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            enabledFeatures.add(feature);
                          } else {
                            enabledFeatures.remove(feature);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedTenant = tenant.copyWith(
                  name: nameController.text,
                  businessName: businessController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  status: status,
                  tier: tier,
                  isMaintenanceMode: isMaintenanceMode,
                  enabledFeatures: enabledFeatures,
                );

                _tenantService.updateTenant(updatedTenant);
                _loadTenants(); // Refresh UI

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Tenant updated successfully'),
                      backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a237e),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTenantDetailsDialog(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFF1a237e).withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Center(
                  child: Text(
                      tenant.name
                          .toString()
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e)))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(tenant.businessName,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tenant ID', tenant.id),
              _buildDetailRow('Email', tenant.email),
              _buildDetailRow('Phone', tenant.phone),
              _buildDetailRow('Status', tenant.status),
              _buildDetailRow('Tier', tenant.tier.toString().split('.').last.toUpperCase()),
              _buildDetailRow('Created',
                  DateFormat('MMM d, yyyy').format(tenant.createdDate)),
              _buildDetailRow(
                  'Last Login',
                  tenant.lastLogin != null
                      ? DateFormat('MMM d, yyyy HH:mm')
                          .format(tenant.lastLogin!)
                      : 'Never'),
              _buildDetailRow('Orders', '${tenant.ordersCount}'),
              _buildDetailRow('Revenue',
                  'KSh ${NumberFormat('#,###').format(tenant.revenue)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Tenant'),
          ],
        ),
        content: Text(
            'Are you sure you want to delete "${tenant.businessName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _tenantService.deleteTenant(tenant.id);
              _loadTenants(); // Refresh UI
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tenant deleted'),
                    backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tier.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart';
import 'package:flutter/services.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/core/services/license_service.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/features/warehouse/domain/services/warehouse_service.dart';
import 'package:kfm_kiosk/features/warehouse/domain/entities/warehouse.dart' as entity;

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
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTenants();
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
                      _buildTierListTab(),
                      _buildLicensesTab(), // New Tab
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
          _buildSidebarItem(1, Icons.layers_outlined, 'Tiers'),
          _buildSidebarItem(2, Icons.vpn_key_outlined, 'Licenses'), // New Item
          _buildSidebarItem(3, Icons.analytics_outlined, 'Analytics'),
          _buildSidebarItem(4, Icons.settings_outlined, 'Settings'),
          // const Spacer(),
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Column(
          //     children: [
          //       const Divider(),
          //       const SizedBox(height: 16),
          //       const Divider(),
          //       const SizedBox(height: 16),
          //       _buildQuickStat(
          //           'Active',
          //           '${_tenants.where((t) => t.status == 'Active').length}',
          //           Icons.check_circle,
          //           Colors.green),
          //       const SizedBox(height: 12),
          //       _buildQuickStat(
          //           'Pending',
          //           '${_tenants.where((t) => t.status == 'Pending').length}',
          //           Icons.pending,
          //           Colors.orange),
          //       const SizedBox(height: 12),
          //       _buildQuickStat(
          //           'Inactive',
          //           '${_tenants.where((t) => t.status == 'Inactive').length}',
          //           Icons.cancel,
          //           Colors.red),
          //     ],
          //   ),
          // ),
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

  Widget _buildTierListTab() {
    final tiers = _tenantService.getTiers();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Tiers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddTierDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Tier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a237e),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tiers.map((tier) => _buildTierCard(tier)),
        ],
      ),
    );
  }

  Widget _buildTierCard(Tier tier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(tier.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(tier.id,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontFamily: 'monospace')),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditTierDialog(tier);
                  } else if (value == 'delete') {
                    await _tenantService.deleteTier(tier.id);
                    if (mounted) setState(() {});
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          if (tier.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tier.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...tier.enabledFeatures.map((f) => Chip(
                    label: Text(f),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: Colors.blue, fontSize: 11),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
              if (!tier.allowUpdates)
                Chip(
                  label: const Text('No Updates'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: Colors.orange, fontSize: 11),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              if (tier.immuneToBlocking)
                Chip(
                  label: const Text('Immune to Blocking'),
                  backgroundColor: Colors.teal.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: Colors.teal, fontSize: 11),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTierDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    List<String> enabledFeatures = ['orders', 'history'];
    bool allowUpdates = true;
    bool immuneToBlocking = false;
    final List<String> availableFeatures = ['orders', 'history', 'insights', 'warehouse', 'products'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Tier'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                      labelText: 'Tier ID (unique)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tier Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Allow Updates'),
                    value: allowUpdates,
                    onChanged: (val) => setDialogState(() => allowUpdates = val),
                  ),
                  SwitchListTile(
                    title: const Text('Immune to Blocking'),
                    value: immuneToBlocking,
                    onChanged: (val) => setDialogState(() => immuneToBlocking = val),
                  ),
                  const Divider(),
                   const Text('Enabled Features', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   ...availableFeatures.map((feature) {
                    final isEnabled = enabledFeatures.contains(feature);
                    return CheckboxListTile(
                      title: Text(feature),
                      value: isEnabled,
                      contentPadding: EdgeInsets.zero,
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
                if (idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                  final newTier = Tier(
                    id: idController.text.toLowerCase().replaceAll(' ', '_'),
                    name: nameController.text,
                    description: descController.text,
                    enabledFeatures: enabledFeatures,
                    allowUpdates: allowUpdates,
                    immuneToBlocking: immuneToBlocking,
                  );
                  _tenantService.addTier(newTier).then((_) {
                    if (mounted) setState(() {}); // Refresh Tier List
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Tier'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditTierDialog(Tier tier) {
     final nameController = TextEditingController(text: tier.name);
     final descController = TextEditingController(text: tier.description);
     List<String> enabledFeatures = List.from(tier.enabledFeatures);
     bool allowUpdates = tier.allowUpdates;
     bool immuneToBlocking = tier.immuneToBlocking;
     final List<String> availableFeatures = ['orders', 'history', 'insights', 'warehouse', 'products'];

     showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Tier'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text('Tier ID: ${tier.id}', style: const TextStyle(color: Colors.grey)),
                   const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tier Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Allow Updates'),
                    value: allowUpdates,
                    onChanged: (val) => setDialogState(() => allowUpdates = val),
                  ),
                  SwitchListTile(
                    title: const Text('Immune to Blocking'),
                    value: immuneToBlocking,
                    onChanged: (val) => setDialogState(() => immuneToBlocking = val),
                  ),
                  const Divider(),
                   const Text('Enabled Features', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   ...availableFeatures.map((feature) {
                    final isEnabled = enabledFeatures.contains(feature);
                    return CheckboxListTile(
                      title: Text(feature),
                      value: isEnabled,
                      contentPadding: EdgeInsets.zero,
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
                final updatedTier = tier.copyWith(
                  name: nameController.text,
                  description: descController.text,
                  enabledFeatures: enabledFeatures,
                  allowUpdates: allowUpdates,
                  immuneToBlocking: immuneToBlocking,
                );
                _tenantService.updateTier(updatedTier).then((_) {
                  if (mounted) setState(() {}); // Refresh Tier List
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
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
                    Expanded(
                      child: Text(tenant.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
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
                    if (tenant.tierId == 'premium')
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
                    if (tenant.tierId == 'alone')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        
                      ),
                    // Override Indicators
                    if (tenant.immuneToBlocking == true)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield, size: 12, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('IMMUNE',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                    if (tenant.allowUpdate == false)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                         padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.system_update_alt, size: 12, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('NO UPDATES',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                    if (tenant.tierId == 'alone')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield, size: 12, color: Colors.teal),
                            SizedBox(width: 4),
                            Text('ALONE',
                                style: TextStyle(
                                    color: Colors.teal,
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
                case 'branches':
                  _showManageBranchesDialog(tenant);
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(tenant);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Details')),
              const PopupMenuItem(value: 'edit', child: Text('Edit Tenant')),
              if (tenant.tierId == 'enterprise')
                const PopupMenuItem(value: 'branches', child: Text('Manage Branches')),
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
              .take(3)
              .toList()
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
            _buildSettingsTile(
              'Enterprise Dashboard',
              _tenantService.isModuleUnderMaintenance('enterprise_dashboard'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('enterprise_dashboard', val)),
            ),
            _buildSettingsTile(
              'Product Management',
              _tenantService.isModuleUnderMaintenance('products'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('products', val)),
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
    String selectedTierId = 'standard';
    List<String> enabledFeatures = ['orders', 'history', 'insights', 'warehouse'];
    final List<String> availableFeatures = ['orders', 'history', 'insights', 'warehouse', 'products'];
    
    // Get available tiers
    final tiers = _tenantService.getTiers();
    if (tiers.isNotEmpty) {
      selectedTierId = tiers.first.id;
    }
    
    // Override flags (null = inherit)
    bool? allowUpdate; 
    bool? immuneToBlocking;

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
                  DropdownButtonFormField<String>(
                    initialValue: selectedTierId,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Tier',
                      border: OutlineInputBorder(),
                    ),
                    items: tiers
                        .map((t) => DropdownMenuItem(
                            value: t.id,
                            child:
                                Text(t.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedTierId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                   const Text('Overrides (Default: Inherit from Tier)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                   const SizedBox(height: 8),
                   DropdownButtonFormField<bool?>(
                    initialValue: allowUpdate,
                    decoration: const InputDecoration(
                      labelText: 'Allow Updates',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                       DropdownMenuItem(value: null, child: Text('Inherit (Default)')),
                       DropdownMenuItem(value: true, child: Text('Yes (Force Allow)')),
                       DropdownMenuItem(value: false, child: Text('No (Force Block)')),
                    ],
                    onChanged: (value) => setDialogState(() => allowUpdate = value),
                  ),
                  const SizedBox(height: 12),
                   DropdownButtonFormField<bool?>(
                    value: immuneToBlocking,
                    decoration: const InputDecoration(
                      labelText: 'Immune to Blocking',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                       DropdownMenuItem(value: null, child: Text('Inherit (Default)')),
                       DropdownMenuItem(value: true, child: Text('Yes (Immune)')),
                       DropdownMenuItem(value: false, child: Text('No (Not Immune)')),
                    ],
                    onChanged: (value) => setDialogState(() => immuneToBlocking = value),
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
                    tierId: selectedTierId,
                    createdDate: DateTime.now(),
                    enabledFeatures: enabledFeatures,
                    allowUpdate: allowUpdate,
                    immuneToBlocking: immuneToBlocking,
                  );

                _tenantService.addTenant(newTenant).then((_) {
                  _loadTenants(); // Refresh UI
                });
                
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
    String tierId = tenant.tierId; // Changed to String
    bool isMaintenanceMode = tenant.isMaintenanceMode;
    List<String> enabledFeatures = List.from(tenant.enabledFeatures);
    
    // Override flags
    bool? allowUpdate = tenant.allowUpdate;
    bool? immuneToBlocking = tenant.immuneToBlocking;
    
    final List<String> availableFeatures = ['orders', 'history', 'insights', 'warehouse', 'products'];

    // Get Tiers
    final tiers = _tenantService.getTiers();

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
                  DropdownButtonFormField<String>(
                    initialValue: tierId,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Tier',
                      border: OutlineInputBorder(),
                    ),
                    items: tiers
                        .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tierId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Maintenance Mode'),
                    subtitle: const Text('Restrict system access'),
                    value: isMaintenanceMode,
                    activeThumbColor: Colors.red,
                    onChanged: (value) =>
                        setDialogState(() => isMaintenanceMode = value),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                   const Text('Overrides (Default: Inherit from Tier)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                   const SizedBox(height: 8),
                   DropdownButtonFormField<bool?>(
                    initialValue: allowUpdate,
                    decoration: const InputDecoration(
                      labelText: 'Allow Updates',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                       DropdownMenuItem(value: null, child: Text('Inherit (Default)')),
                       DropdownMenuItem(value: true, child: Text('Yes (Force Allow)')),
                       DropdownMenuItem(value: false, child: Text('No (Force Block)')),
                    ],
                    onChanged: (value) => setDialogState(() => allowUpdate = value),
                  ),
                  const SizedBox(height: 12),
                   DropdownButtonFormField<bool?>(
                    value: immuneToBlocking,
                    decoration: const InputDecoration(
                      labelText: 'Immune to Blocking',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                       DropdownMenuItem(value: null, child: Text('Inherit (Default)')),
                       DropdownMenuItem(value: true, child: Text('Yes (Immune)')),
                       DropdownMenuItem(value: false, child: Text('No (Not Immune)')),
                    ],
                    onChanged: (value) => setDialogState(() => immuneToBlocking = value),
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
                  tierId: tierId,
                  isMaintenanceMode: isMaintenanceMode,
                  enabledFeatures: enabledFeatures,
                  allowUpdate: allowUpdate,
                  immuneToBlocking: immuneToBlocking,
                );

                _tenantService.updateTenant(updatedTenant).then((_) {
                  _loadTenants(); // Refresh UI
                });
 
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
              _buildDetailRow('Tier', _tenantService.getTierById(tenant.tierId)?.name ?? tenant.tierId),
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
              _tenantService.deleteTenant(tenant.id).then((_) {
                _loadTenants(); // Refresh UI
              });
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

  void _showManageBranchesDialog(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Manage Branches - ${tenant.businessName}'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: [
                       ElevatedButton.icon(
                         onPressed: () {
                           _showAddEditBranchDialog(context, tenant, setDialogState);
                         },
                         icon: const Icon(Icons.add),
                         label: const Text('Add Branch'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF1a237e),
                           foregroundColor: Colors.white,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Branch>>(
                      future: _tenantService.getBranchesForTenant(tenant.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final branches = snapshot.data ?? [];
                        
                        return branches.isEmpty
                            ? const Center(child: Text('No branches found.'))
                            : ListView.builder(
                                itemCount: branches.length,
                                itemBuilder: (context, index) {
                                  final branch = branches[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: branch.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                        child: Icon(Icons.store, color: branch.isActive ? Colors.green : Colors.red, size: 20),
                                      ),
                                      title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${branch.location} • ${branch.managerName}'),
                                          const SizedBox(height: 8),
                                          FutureBuilder<List<entity.Warehouse>>(
                                            future: getIt<WarehouseService>().getWarehousesForBranch(branch.id),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                              }
                                              final warehouses = snapshot.data ?? [];
                                              if (warehouses.isEmpty) {
                                                return Text('No warehouses assigned', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic));
                                              }
                                              return Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: warehouses.map((w) => GestureDetector(
                                                  onTap: () => _showWarehouseDetailsDialog(w),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.warehouse_outlined, size: 10, color: Colors.blue),
                                                        const SizedBox(width: 4),
                                                        Text(w.name, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ),
                                                )).toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {
                                              _showAddEditBranchDialog(context, tenant, setDialogState, branch: branch);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              // Confirm delete
                                              showDialog(context: context, builder: (ctx) => AlertDialog(
                                                title: const Text('Delete Branch?'),
                                                content: Text('Are you sure you want to delete ${branch.name}?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                    onPressed: () {
                                                      _tenantService.deleteBranch(branch.id);
                                                      setDialogState(() {});
                                                      Navigator.pop(ctx);
                                                    },
                                                    child: const Text('Delete'),
                                                  )
                                                ],
                                              ));
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWarehouseDetailsDialog(entity.Warehouse warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warehouse, color: Color(0xFF1a237e)),
            const SizedBox(width: 12),
            Expanded(child: Text('Warehouse: ${warehouse.name}')),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarehouseDetailRow('ID', warehouse.id),
              _buildWarehouseDetailRow('Status', warehouse.isActive ? 'Active' : 'Inactive', 
                  valueColor: warehouse.isActive ? Colors.green : Colors.red),
              const Divider(height: 24),
              const Text('Access Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildWarehouseDetailRow('Username', warehouse.loginUsername),
              const Divider(height: 24),
              const Text('Assigned Warehouse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (warehouse.categories.isEmpty)
                Text('No categories assigned', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: warehouse.categories.map((cat) => Chip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey[200],
                  )).toList(),
                ),
            ],
          ),
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

  Widget _buildWarehouseDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditBranchDialog(BuildContext parentContext, Tenant tenant, StateSetter parentSetState, {Branch? branch}) {
    final isEditing = branch != null;
    final nameController = TextEditingController(text: branch?.name);
    final locationController = TextEditingController(text: branch?.location);
    final phoneController = TextEditingController(text: branch?.contactPhone);
    final managerController = TextEditingController(text: branch?.managerName);
    final usernameController = TextEditingController(text: branch?.loginUsername);
    final passwordController = TextEditingController(text: branch?.loginPassword);
    bool isActive = branch?.isActive ?? true;

    showDialog(
      context: parentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Branch' : 'Add Branch'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Branch Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location / Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: managerController,
                    decoration: const InputDecoration(labelText: 'Manager Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Manager Credentials', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Login Username', border: OutlineInputBorder(), helperText: 'Unique username for manager login'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Login Password (ID)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active Status'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username and Password are required')));
                  return;
                }

                final newBranch = Branch(
                  id: isEditing ? branch.id : 'BR${DateTime.now().millisecondsSinceEpoch}',
                  tenantId: tenant.id,
                  name: nameController.text,
                  location: locationController.text,
                  contactPhone: phoneController.text,
                  managerName: managerController.text,
                  loginUsername: usernameController.text,
                  loginPassword: passwordController.text,
                  isActive: isActive,
                  totalOrders: branch?.totalOrders ?? 0,
                  revenue: branch?.revenue ?? 0.0,
                );

                if (isEditing) {
                  _tenantService.updateBranch(newBranch);
                } else {
                  _tenantService.addBranch(newBranch);
                }
                
                // Refresh parent dialog
                parentSetState(() {});
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('License Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Generate license keys for tenants to activate their kiosk terminals.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Container(
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
                const Text('Generate New License',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildLicenseGeneratorForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseGeneratorForm() {
    return StatefulBuilder(
      builder: (context, setState) {
        // Local state for the form
        return _LicenseGeneratorForm(tenants: _tenants);
      },
    );
  }
}

class _LicenseGeneratorForm extends StatefulWidget {
  final List<Tenant> tenants;
  const _LicenseGeneratorForm({required this.tenants});

  @override
  State<_LicenseGeneratorForm> createState() => _LicenseGeneratorFormState();
}

class _LicenseGeneratorFormState extends State<_LicenseGeneratorForm> {
  Tenant? selectedTenant;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
  String? generatedKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Tenant>(
          decoration: const InputDecoration(
            labelText: 'Select Tenant',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          items: widget.tenants.map((tenant) {
            return DropdownMenuItem(
              value: tenant,
              child: Text('${tenant.businessName} (${tenant.name})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => selectedTenant = value);
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Expiration Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              DateFormat('yyyy-MM-dd').format(selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: selectedTenant == null
                ? null
                : () {
                    final licenseService = getIt<LicenseService>();
                    final key = licenseService.generateLicense(
                      tenantId: selectedTenant!.id,
                      expiresAt: selectedDate,
                    );
                    setState(() => generatedKey = key);
                  },
            icon: const Icon(Icons.vpn_key),
            label: const Text('Generate Key'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (generatedKey != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text('License Key Generated Successfully',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        generatedKey!,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: generatedKey!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Key copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expires on: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

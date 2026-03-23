import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sss/features/auth/domain/entities/tenant.dart';
import 'package:sss/features/auth/domain/entities/tier.dart';
import 'package:sss/features/auth/domain/entities/branch.dart';
import 'package:flutter/services.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/core/services/license_service.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';
import 'package:sss/features/warehouse/domain/services/warehouse_service.dart';
import 'package:sss/features/warehouse/domain/entities/warehouse.dart' as entity;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sss/features/auth/presentation/screens/login_screen.dart';

import 'package:sss/core/models/update_info.dart';
import 'package:sss/core/models/terminal_info.dart';

import '../../../../core/services/firebase_rest_service.dart';
import '../../../../core/services/github_update_service.dart';

class SuperAdminMobile extends StatefulWidget {
  const SuperAdminMobile({super.key});

  @override
  State<SuperAdminMobile> createState() => _SuperAdminMobileState();
}

class _SuperAdminMobileState extends State<SuperAdminMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TenantService _tenantService = TenantService();
  String _searchQuery = '';
  List<Tenant> _tenants = [];
  UpdateInfo? _currentUpdateManifest;
  bool _isLoadingUpdate = false;
  bool _isPublishingUpdate = false;

  final _versionController = TextEditingController();
  final _urlController = TextEditingController();
  final _checksumController = TextEditingController();
  final _notesController = TextEditingController();
  final _minVersionController = TextEditingController();
  final _githubOwnerController = TextEditingController();
  final _githubRepoController = TextEditingController();
  final _githubTokenController = TextEditingController();

  bool _isMandatory = false;
  bool _isMaintenance = false;
  List<String> _allowedFlavors = [];
  List<String> _allowedTenants = [];
  List<String> _allowedPlatforms = [];
  List<UpdateInfo> _manifestHistory = [];

  bool _isLoadingTerminals = false;
  List<TerminalInfo> _terminals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadTenants();
    _loadUpdateManifest();
    _loadTerminals();
    _tenantService.syncGlobalConfig().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _loadTerminals() async {
    setState(() => _isLoadingTerminals = true);
    try {
      final terminals = await _tenantService.getAllTerminals();
      if (mounted) {
        setState(() {
          _terminals = terminals;
          _isLoadingTerminals = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTerminals = false);
    }
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a237e),
        elevation: 0,
        title: const Text('Super Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTenantDialog(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildMobileHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTenantListTab(true),
                _buildTierListTab(true),
                _buildLicensesTab(true),
                _buildUpdatesTab(true),
                _buildTerminalsTab(),
                _buildAnalyticsTab(true),
                _buildSettingsTab(true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a237e), Color(0xFF283593)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text('Super Admin Panel',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(0, Icons.people_outline, 'Tenants'),
                _buildDrawerItem(1, Icons.layers_outlined, 'Tiers'),
                _buildDrawerItem(2, Icons.vpn_key_outlined, 'Licenses'),
                _buildDrawerItem(3, Icons.system_update_alt, 'Updates'),
                _buildDrawerItem(4, Icons.devices, 'Terminals'),
                _buildDrawerItem(5, Icons.analytics_outlined, 'Analytics'),
                _buildDrawerItem(6, Icons.settings_outlined, 'Settings'),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of the Super Admin Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF1a237e) : Colors.grey[600]),
      title: Text(label,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1a237e) : Colors.grey[700])),
      selected: isSelected,
      selectedTileColor: const Color(0xFF1a237e).withValues(alpha: 0.1),
      onTap: () {
        setState(() => _tabController.animateTo(index));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a237e),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildHeaderStat('Tenants', '${_tenants.length}', Icons.people)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildHeaderStat(
                'Active',
                '${_tenants.where((t) => t.status == 'Active').length}',
                Icons.check_circle),
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




  Widget _buildTenantListTab(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredTenants.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Text('Tenants',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                );
              }
              return _buildTenantCard(_filteredTenants[index - 1], true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTierListTab(bool isMobile) {
    final tiers = _tenantService.getTiers();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tiers.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage Tiers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showAddTierDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1a237e),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildTierCard(tiers[index - 1]);
      },
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

  Widget _buildTenantCard(Tenant tenant, bool isMobile) {
    final statusColor = tenant.status == 'Active'
        ? Colors.green
        : tenant.status == 'Pending'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a237e)))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tenant.businessName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(tenant.id,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tenant.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: Text('Delete Tenant', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(tenant.email, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(tenant.phone, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KSh ${NumberFormat('#,###').format(tenant.revenue)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e))),
                  Text('${tenant.ordersCount} orders',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAnalyticsTab(bool isMobile) {
    final stats = _tenantService.getStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Stack analytics cards vertically for mobile or use a grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
               _buildAnalyticsCard('Revenue',
                      'KSh ${NumberFormat('#,###').format(stats['totalRevenue'])}', Icons.attach_money, Colors.green, true),
               _buildAnalyticsCard('Orders', '${stats['totalOrders']}',
                      Icons.shopping_cart, Colors.blue, true),
               _buildAnalyticsCard('Tenants',
                      '${stats['activeTenants']}', Icons.people, Colors.purple, true),
               _buildAnalyticsCard(
                      'Avg/Tenant',
                      'KSh ${NumberFormat('#,###').format(stats['avgRevenue'])}',
                      Icons.trending_up,
                      Colors.orange, true),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Top Performing Tenants',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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
      String title, String value, IconData icon, Color color, bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              constraints: const BoxConstraints(maxHeight: 150),
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
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

  Widget _buildSettingsTab(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSettingsCard('General', [
            _buildSettingsTile('Auto-approve Tenants', true),
            _buildSettingsTile('Send Welcome Emails', true),
          ]),
          const SizedBox(height: 12),
          _buildSettingsCard('Maintenance Mode', [
            _buildSettingsTile(
              'System Maintenance',
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
          const SizedBox(height: 12),
          _buildSettingsCard('Module Status', [
            _buildSettingsTile(
              'Orders Module',
              _tenantService.isModuleUnderMaintenance('orders'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('orders', val)),
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
              'Products Module',
              _tenantService.isModuleUnderMaintenance('products'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('products', val)),
            ),
            _buildSettingsTile(
              'Order History',
              _tenantService.isModuleUnderMaintenance('history'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('history', val)),
            ),
            _buildSettingsTile(
              'System Settings',
              _tenantService.isModuleUnderMaintenance('settings'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('settings', val)),
            ),
            _buildSettingsTile(
              'Enterprise Dashboard',
              _tenantService.isModuleUnderMaintenance('enterprise_dashboard'),
              onChanged: (val) => setState(() => _tenantService.setModuleMaintenance('enterprise_dashboard', val)),
            ),
          ]),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Cloud Synchronization',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Seed local data to Firestore for the first-time setup.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => _syncAllToCloud(),
              icon: const Icon(Icons.cloud_upload, size: 18),
              label: const Text('Push Data to Cloud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: () => _pullAllFromCloud(),
              icon: const Icon(Icons.cloud_download, size: 18),
              label: const Text('Pull Data from Cloud'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _pullAllFromCloud() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Pulling from cloud...'),
          ],
        ),
      ),
    );

    try {
      await _tenantService.pullTiersFromCloud();
      await _tenantService.pullTenantsFromCloud();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _loadTenants(); // Refresh UI list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully pulled all data from cloud'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pulling from cloud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncAllToCloud() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Synchronizing to cloud...'),
          ],
        ),
      ),
    );

    try {
      // 1. Sync Tiers
      final tiers = _tenantService.getTiers();
      for (final tier in tiers) {
        await _tenantService.syncTierToCloud(tier);
      }

      // 2. Sync Tenants
      for (final tenant in _tenants) {
        if (tenant.id != 'SUPER_ADMIN') {
           await _tenantService.syncTenantToCloud(tenant);
        }
      }

      // 3. Sync Maintenance Modes (Trigger setters)
      _tenantService.setMaintenanceMode(_tenantService.isMaintenanceMode);
      for (final module in ['orders', 'history', 'insights', 'warehouse', 'settings', 'enterprise_dashboard', 'products']) {
         _tenantService.setModuleMaintenance(module, _tenantService.isModuleUnderMaintenance(module));
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Initial cloud data seeded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                    initialValue: immuneToBlocking,
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
                    initialValue: immuneToBlocking,
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

  Widget _buildLicensesTab(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('License Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Generate license keys for kiosk terminals.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLicenseGeneratorForm(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                const Text('Active & Pending Licenses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLicenseList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseList() {
    if (Platform.isLinux) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: getIt<FirebaseRestService>().getCollection('licenses'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data ?? [];
          if (docs.isEmpty) return const Center(child: Text('No licenses generated yet.'));

          // Sort by createdAt descending
          docs.sort((a, b) {
             final aDate = a['createdAt'] is DateTime ? a['createdAt'] as DateTime : DateTime.now();
             final bDate = b['createdAt'] is DateTime ? b['createdAt'] as DateTime : DateTime.now();
             return bDate.compareTo(aDate);
          });

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index];
              final tenantId = data['tenantId'] as String? ?? 'Unknown';
              final tenant = _tenants.firstWhere((t) => t.id == tenantId, orElse: () => Tenant(id: tenantId, name: 'Unknown', businessName: 'Unknown Tenant', email: '', phone: '', status: '', tierId: '', createdDate: DateTime.now(), lastLogin: DateTime.now(), ordersCount: 0, revenue: 0, isMaintenanceMode: false, enabledFeatures: []));
              
              final expiresAt = data['expiresAt'];
              final expiry = expiresAt is DateTime ? expiresAt : DateTime.now();
              final status = data['status'] as String? ?? 'unknown';
              final key = data['key'] as String? ?? '';

              return ListTile(
                title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                subtitle: Text('${tenant.businessName} • Expires: ${DateFormat('yyyy-MM-dd').format(expiry)}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'active' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status == 'active' ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                   Clipboard.setData(ClipboardData(text: key));
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key copied')));
                },
              );
            },
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('licenses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No licenses generated yet.'));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final tenantId = data['tenantId'] as String;
            
            // Fixed lookup: use case-insensitive ID match and ensure we check both id and tenantId fields if necessary
            final tenant = _tenants.firstWhere(
              (t) => t.id.toLowerCase() == tenantId.toLowerCase(),
              orElse: () => Tenant(
                id: tenantId, 
                name: 'Unknown', 
                businessName: 'Tenant ($tenantId)', 
                email: '', 
                phone: '', 
                status: '', 
                tierId: '', 
                createdDate: DateTime.now(), 
                lastLogin: DateTime.now(), 
                ordersCount: 0, 
                revenue: 0, 
                isMaintenanceMode: false, 
                enabledFeatures: []
              )
            );
            
            final expiry = (data['expiresAt'] as Timestamp).toDate();
            final status = data['status'] as String;
            final key = data['key'] as String;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)),
              subtitle: Text(
                '${tenant.businessName} • Expires: ${DateFormat('yyyy-MM-dd').format(expiry)}',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'active' ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                 Clipboard.setData(ClipboardData(text: key));
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key copied')));
              },
            );
          },
        );
      },
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

  Future<void> _loadUpdateManifest() async {
    setState(() => _isLoadingUpdate = true);
    try {
      final manifest = await _tenantService.getLatestUpdateManifest();
      setState(() {
        _currentUpdateManifest = manifest;
        if (manifest != null) {
          _versionController.text = manifest.latestVersion;
          _urlController.text = manifest.updateUrl ?? '';
          _checksumController.text = manifest.checksum ?? '';
          _notesController.text = manifest.releaseNotes;
          _minVersionController.text = manifest.minimumSupportedVersion ?? '';
          _githubOwnerController.text = manifest.githubOwner ?? '';
          _githubRepoController.text = manifest.githubRepo ?? '';
          _githubTokenController.text = manifest.githubToken ?? '';
          _isMandatory = manifest.isMandatory;
          _isMaintenance = manifest.isMaintenanceMode;
          _allowedFlavors = List.from(manifest.allowedFlavors);
          _allowedPlatforms = List.from(manifest.allowedPlatforms);
        }
        _isLoadingUpdate = false;
      });

      // Load history
      final history = await _tenantService.getLatestUpdateManifests();
      setState(() {
        _manifestHistory = history;
      });
    } catch (e) {
      debugPrint('SuperAdmin: Error loading update manifest: $e');
      setState(() => _isLoadingUpdate = false);
    }
  }

  Widget _buildUpdatesTab(bool isMobile) {
    if (_isLoadingUpdate) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<String> availableFlavors = ['kiosk', 'staff', 'manager', 'warehouse', 'dashboard', 'superadmin'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Update Management',
                        style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold)),
                    Text('Control global app versions and targeting',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (_currentUpdateManifest != null)
                Chip(
                  label: Text('v${_currentUpdateManifest!.latestVersion}'),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUpdateCard('Version Information', [
            TextField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'Latest Version (e.g., 1.1.0)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.history, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minVersionController,
              decoration: const InputDecoration(
                labelText: 'Min Supported (e.g., 1.0.0)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security_update_warning, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildUpdateCard('Update History', [
            _buildManifestHistory(),
          ]),
          const SizedBox(height: 20),
          _buildUpdateCard('Strategy', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mandatory Update'),
              value: _isMandatory,
              onChanged: (val) => setState(() => _isMandatory = val),
            ),
            // SwitchListTile(
            //   contentPadding: EdgeInsets.zero,
            //   title: const Text('Maintenance Mode'),
            //   value: _isMaintenance,
            //   onChanged: (val) => setState(() => _isMaintenance = val),
            // ),
          ]),
          // const SizedBox(height: 20),
          // _buildUpdateCard('GitHub Configuration (Optional)', [
          //    TextField(
          //      controller: _githubOwnerController,
          //      decoration: const InputDecoration(
          //        labelText: 'GitHub Owner (Default if blank)',
          //        border: OutlineInputBorder(),
          //      ),
          //    ),
          //    const SizedBox(height: 12),
          //    TextField(
          //      controller: _githubRepoController,
          //      decoration: const InputDecoration(
          //        labelText: 'GitHub Repo (Default if blank)',
          //        border: OutlineInputBorder(),
          //      ),
          //    ),
          //    const SizedBox(height: 12),
          //    TextField(
          //      controller: _githubTokenController,
          //      decoration: const InputDecoration(
          //        labelText: 'GitHub Token (Optional)',
          //        border: OutlineInputBorder(),
          //      ),
          //      obscureText: true,
          //    ),
          // ]),
          // const SizedBox(height: 20),
          // _buildUpdateCard('Release Notes', [
          //   TextField(
          //     controller: _notesController,
          //     maxLines: 4,
          //     decoration: const InputDecoration(
          //       labelText: 'Notes (Markdown supported)',
          //       border: OutlineInputBorder(),
          //     ),
          //   ),
          // ]),
          const SizedBox(height: 20),
          _buildUpdateCard('Targeting', [
            const Text('App Flavors (None = ALL Apps)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: availableFlavors.map((flavor) {
                final isSelected = _allowedFlavors.contains(flavor);
                return FilterChip(
                  label: Text(flavor.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _allowedFlavors.add(flavor);
                      } else {
                        _allowedFlavors.remove(flavor);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('App Platforms (None = ALL Platforms)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['android', 'ios', 'windows', 'linux', 'macos'].map((platform) {
                final isSelected = _allowedPlatforms.contains(platform);
                return FilterChip(
                  label: Text(platform.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _allowedPlatforms.add(platform);
                      } else {
                        _allowedPlatforms.remove(platform);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Targeting Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _allowedTenants.isEmpty ? 'all' : 'specific',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Tenants')),
                DropdownMenuItem(value: 'specific', child: Text('Specific Tenants')),
              ],
              onChanged: (val) {
                setState(() {
                  if (val == 'all') {
                    _allowedTenants = [];
                  }
                });
              },
            ),
            if (_allowedTenants.isNotEmpty || true) ...[
              const SizedBox(height: 16),
              // Use plain DropdownButton (not FormField) so value: null is fully
              // controlled and never persists across rebuilds via FormFieldState.
              InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: DropdownButton<String>(
                  value: null,
                  hint: const Text('Add Tenant...', style: TextStyle(fontSize: 12)),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: _tenants
                      .where((t) => !_allowedTenants.contains(t.id))
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        if (!_allowedTenants.contains(val)) {
                          _allowedTenants.add(val);
                        }
                      });
                    }
                  },
                ),
              ),
              if (_allowedTenants.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _allowedTenants.map((id) {
                    final tenant = _tenants.firstWhere((t) => t.id == id, orElse: () => _tenants.first);
                    return InputChip(
                      label: Text(tenant.name, style: const TextStyle(fontSize: 10)),
                      onDeleted: () => setState(() => _allowedTenants.remove(id)),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      deleteIcon: const Icon(Icons.close, size: 14),
                    );
                  }).toList(),
                ),
              ],
            ],
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isPublishingUpdate ? null : _handlePublishUpdate,
              icon: _isPublishingUpdate 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.publish),
              label: Text(_isPublishingUpdate ? 'Publishing...' : 'Publish Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a237e),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1a237e))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildManifestHistory() {
    if (_manifestHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.history_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text('No publish history available', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _manifestHistory.map((manifest) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1a237e).withValues(alpha: 0.1),
              child: const Icon(Icons.cloud_done, color: Color(0xFF1a237e), size: 16),
            ),
            title: Row(
              children: [
                Text('v${manifest.latestVersion}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                if (manifest.isMandatory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('MANDATORY', style: TextStyle(color: Colors.red, fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(manifest.releaseNotes, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(DateFormat('MMM dd, HH:mm').format(manifest.releaseDate ?? DateTime.now()), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, scrollController) => SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(height: 20),
                          Text('Release v${manifest.latestVersion} Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _buildDetailItem('Release Date', DateFormat('yyyy-MM-dd HH:mm:ss').format(manifest.releaseDate ?? DateTime.now())),
                          _buildDetailItem('Min Supported', manifest.minimumSupportedVersion ?? 'None'),
                          _buildDetailItem('Platforms', manifest.allowedPlatforms.join(', ')),
                          _buildDetailItem('Flavors', manifest.allowedFlavors.join(', ')),
                          _buildDetailItem('Release Notes', manifest.releaseNotes),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _handlePublishUpdate() async {
    if (_versionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Version required'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        title: const Text('Confirm Update'),
        content: Text('Publish v${_versionController.text} globally?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPublishingUpdate = true);
    try {
      final manifest = UpdateInfo(
        requiresUpdate: true,
        isMandatory: _isMandatory,
        isMaintenanceMode: _isMaintenance,
        updateUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
        currentVersion: _currentUpdateManifest?.latestVersion ?? '1.0.0',
        latestVersion: _versionController.text,
        releaseNotes: _notesController.text,
        checksum: _checksumController.text.isEmpty ? null : _checksumController.text,
        minimumSupportedVersion: _minVersionController.text.isNotEmpty ? _minVersionController.text : null,
        allowedFlavors: _allowedFlavors,
        allowedTenants: _allowedTenants,
        allowedPlatforms: _allowedPlatforms,
        githubOwner: _githubOwnerController.text.isNotEmpty 
            ? _githubOwnerController.text 
            : GitHubUpdateService.defaultOwner,
        githubRepo: _githubOwnerController.text.isNotEmpty 
            ? _githubRepoController.text 
            : GitHubUpdateService.defaultRepo,
        githubToken: _githubTokenController.text.isNotEmpty ? _githubTokenController.text : null,
        releaseDate: DateTime.now(),
      );

      await _tenantService.pushUpdateManifest(manifest);
      await _loadUpdateManifest();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Published!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishingUpdate = false);
    }
  }

  Widget _buildTerminalsTab() {
    if (_isLoadingTerminals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_terminals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No active terminals found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Terminals report status during heartbeat', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTerminals,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Sort by last seen
    final sortedTerminals = List<TerminalInfo>.from(_terminals)
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

    return RefreshIndicator(
      onRefresh: () async => _loadTerminals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedTerminals.length,
        itemBuilder: (context, index) {
          final terminal = sortedTerminals[index];
          final lastSeenStr = DateFormat('MMM dd, HH:mm').format(terminal.lastSeen);
          final tenant = _tenants.firstWhere((t) => t.id == terminal.tenantId, 
              orElse: () => Tenant(id: terminal.tenantId, name: 'Unknown Tenant', businessName: '', email: '', phone: '', status: '', createdDate: DateTime.now()));

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: _getPlatformIcon(terminal.platform),
              title: Text(tenant.businessName.isNotEmpty ? tenant.businessName : tenant.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('v${terminal.version} • ${terminal.flavor}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(lastSeenStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  _getStatusIndicator(terminal.lastSeen),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Device ID', terminal.id),
                      _buildDetailRow('Platform', terminal.platform),
                      _buildDetailRow('Flavor', terminal.flavor),
                      _buildDetailRow('App Version', terminal.version),
                      if (terminal.deviceName != null) _buildDetailRow('Device Name', terminal.deviceName!),
                      if (terminal.publicIp != null) _buildDetailRow('Public IP', terminal.publicIp!),
                      _buildDetailRow('Last Heartbeat', DateFormat('yyyy-MM-dd HH:mm:ss').format(terminal.lastSeen)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android': return const Icon(Icons.android, color: Colors.green);
      case 'ios': return const Icon(Icons.apple, color: Colors.grey);
      case 'windows': return const Icon(Icons.window, color: Colors.blue);
      case 'macos': return const Icon(Icons.laptop_mac, color: Colors.grey);
      case 'linux': return const Icon(Icons.terminal, color: Colors.orange);
      default: return const Icon(Icons.device_unknown);
    }
  }

  Widget _getStatusIndicator(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen).inMinutes;
    Color color = Colors.green;
    String label = 'Online';

    if (diff > 30) {
      color = Colors.orange;
      label = 'Idle';
    }
    if (diff > 1440) { // 24 hours
      color = Colors.red;
      label = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
  bool isSaving = false;
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Tenant>(
          isExpanded: true, // Added to fix overflow
          decoration: const InputDecoration(
            labelText: 'Select Tenant',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          items: widget.tenants.map((tenant) {
            return DropdownMenuItem(
              value: tenant,
              child: Text(
                '${tenant.businessName} (${tenant.name})',
                overflow: TextOverflow.ellipsis, // Added to fix overflow
              ),
            );
          }).toList(),
          initialValue: selectedTenant,
          onChanged: (Tenant? value) {
            setState(() {
              selectedTenant = value;
            });
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
            onPressed: (selectedTenant == null || isSaving)
                ? null
                : () async {
                    setState(() => isSaving = true);
                    final licenseService = getIt<LicenseService>();
                    final key = licenseService.generateLicense();
                    
                    if (!Platform.isLinux) {
                      try {
                        // 1. Save to licenses collection
                        await _firestore.collection('licenses').add({
                          'key': key,
                          'tenantId': selectedTenant!.id,
                          'status': 'pending',
                          'expiresAt': Timestamp.fromDate(selectedDate),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        // 2. Update tenant's record with pending license info (optional, for visibility)
                        await _firestore.collection('tenants').doc(selectedTenant!.id).set({
                          'licenseStatus': 'active', // Pre-emptively set to active or leave till activation
                          'licenseExpiry': Timestamp.fromDate(selectedDate),
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        setState(() {
                          generatedKey = key;
                          isSaving = false;
                        });
                      } catch (e) {
                         debugPrint('SuperAdmin: Error generating license: $e');
                         setState(() => isSaving = false);
                      }
                    } else {
                       // Mock for Linux
                       setState(() {
                          generatedKey = key;
                          isSaving = false;
                       });
                    }
                  },
            icon: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.vpn_key),
            label: Text(isSaving ? 'Saving...' : 'Generate Key'),
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

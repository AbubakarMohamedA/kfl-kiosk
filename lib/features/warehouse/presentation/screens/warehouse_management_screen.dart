import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/warehouse/domain/entities/warehouse.dart';
import 'package:sss/features/warehouse/domain/services/warehouse_service.dart';
import 'package:sss/features/warehouse/presentation/screens/staff_panel_warehouse.dart';
import 'package:sss/di/injection.dart';

class WarehouseManagementScreen extends StatefulWidget {
  const WarehouseManagementScreen({super.key});

  @override
  State<WarehouseManagementScreen> createState() => _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState extends State<WarehouseManagementScreen> {
  final WarehouseService _warehouseService = getIt<WarehouseService>();
  List<Warehouse> _warehouses = [];
  bool _isLoading = true;
  String? _branchId;
  String? _tenantId;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final config = await context.read<OrderBloc>().configurationRepository.getConfiguration();
      _branchId = config.branchId;
      _tenantId = config.tenantId;
      
      if (_branchId != null && _tenantId != null) {
        await _warehouseService.syncWarehousesFromProducts(_tenantId!, _branchId!);
        _warehouses = await _warehouseService.getWarehousesForBranch(_branchId!);
      }
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showWarehouseDialog([Warehouse? warehouse]) async {
    final nameController = TextEditingController(text: warehouse?.name);
    final usernameController = TextEditingController(text: warehouse?.loginUsername);
    final passwordController = TextEditingController(text: warehouse?.loginPassword);
    
    // Default categories hint
    if (warehouse == null) {
      return; // Add should not be possible anymore
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Warehouse Credentials/Name'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Warehouse Name', hintText: 'e.g. Flour Warehouse'),
              ),
              const SizedBox(height: 16),
              // Categories are now read-only and automatically assigned
              Text('Assigned Warehouse: ${warehouse.categories.join(', ')}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const Text('Staff Credentials', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Login Username'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Login Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || usernameController.text.isEmpty || passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final newWarehouse = Warehouse(
                id: warehouse.id,
                tenantId: _tenantId!,
                branchId: _branchId!,
                name: nameController.text,
                categories: warehouse.categories, // Keep original categories
                loginUsername: usernameController.text,
                loginPassword: passwordController.text,
                isActive: true,
              );

              await _warehouseService.saveWarehouse(newWarehouse);
              if (context.mounted) {
                Navigator.pop(context);
                _loadWarehouses();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWarehouse(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warehouse?'),
        content: const Text('Are you sure you want to delete this warehouse? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _warehouseService.deleteWarehouse(id);
      if (context.mounted) {
        _loadWarehouses();
      }
    }
  }

  void _navigateToWarehousePanel(Warehouse warehouse) async {
    // Navigate to warehouse dashboard
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StaffPanelWarehouse(warehouse: warehouse),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_branchId == null && !_isLoading) {
      return const Center(child: Text('Error: No Branch ID found in configuration.'));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Match dashboard background
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _warehouses.isEmpty
                      ? _buildEmptyState()
                      : _buildWarehouseGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warehouse_rounded, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehouse Management',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Create and manage warehouse stations for your branch',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warehouse_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Warehouses Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Warehouses are generated automatically based on your product categories.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: _warehouses.length,
      itemBuilder: (context, index) {
        final warehouse = _warehouses[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        warehouse.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _showWarehouseDialog(warehouse);
                        if (value == 'delete') _deleteWarehouse(warehouse.id);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: warehouse.categories.map((c) => Chip(
                    label: Text(c, style: const TextStyle(fontSize: 10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.grey[100],
                  )).toList(),
                ),
                 const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _navigateToWarehousePanel(warehouse),
                    child: const Text('Access Warehouse Panel'),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Staff: ${warehouse.loginUsername}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

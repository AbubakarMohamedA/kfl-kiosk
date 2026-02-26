import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/features/warehouse/domain/entities/warehouse.dart';
import 'package:kfm_kiosk/features/warehouse/domain/services/warehouse_service.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/staff_panel_warehouse.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';


/// Callback type so StaffPanelDesktop can switch its own _currentScreen
/// without this widget doing a Navigator.push.
typedef OnWarehouseSelected = void Function(Warehouse warehouse);

class WarehouseSelectorScreen extends StatefulWidget {
  /// When provided, selecting a warehouse calls this instead of pushing a route.
  /// StaffPanelDesktop passes its own setState-based switcher here.
  final OnWarehouseSelected? onWarehouseSelected;
  final String? branchId;

  const WarehouseSelectorScreen({
    super.key,
    this.onWarehouseSelected,
    this.branchId,
  });

  @override
  State<WarehouseSelectorScreen> createState() => _WarehouseSelectorScreenState();
}

class _WarehouseSelectorScreenState extends State<WarehouseSelectorScreen> {
  late Future<List<Warehouse>> _warehousesFuture;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  void _loadWarehouses() {
    if (widget.branchId != null) {
      _warehousesFuture = _fetchAndSyncWarehouses();
    } else {
      _warehousesFuture = Future.value([]);
    }
  }

  Future<List<Warehouse>> _fetchAndSyncWarehouses() async {
    final configRepo = getIt<ConfigurationRepository>();
    final config = await configRepo.getConfiguration();
    final tenantId = config.tenantId;
    
    final warehouseService = getIt<WarehouseService>();
    if (tenantId != null) {
      await warehouseService.syncWarehousesFromProducts(tenantId, widget.branchId!);
    }
    return warehouseService.getWarehousesForBranch(widget.branchId!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branchId == null) {
      return Center(child: Text('No Branch ID configured.'));
    }

    return Column(
      children: [
        // ─── Header (matches AnalyticsScreen._buildHeader style) ───
        _buildHeader(context),

        // ─── Body: sidebar + main grid ───
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildSidebar(context), // Sidebar might be redundant if list is dynamic?
              // Let's keep a simplified sidebar or just expand the content
              Expanded(
                child: FutureBuilder<List<Warehouse>>(
                  future: _warehousesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final warehouses = snapshot.data ?? [];

                    if (warehouses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No Warehouses Found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a warehouse in "Warehouse Management" to get started.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Warehouse Stations'),
                          const SizedBox(height: 8),
                          Text(
                            'Select a station to view and manage its pickups',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ─── Dynamic warehouse grid ───
                          _buildWarehouseGrid(context, warehouses),

                          const SizedBox(height: 32),
                          // Stats could be fetched properly, placeholder for now
                          // _buildSectionHeader('Station Summary'),
                          // const SizedBox(height: 16),
                          // _buildSummaryCards(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // HEADER  – mirrors AnalyticsScreen._buildHeader exactly
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppColors.primaryBlue),
            const Color(0xFF0A6F38),
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
            child: const Icon(
              Icons.warehouse,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Warehouse Stations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Monitor and access warehouse dashboards',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WAREHOUSE GRID
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildWarehouseGrid(BuildContext context, List<Warehouse> warehouses) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: warehouses.length,
      itemBuilder: (context, index) {
        return _buildWarehouseCard(context, warehouses[index]);
      },
    );
  }

  Widget _buildWarehouseCard(BuildContext context, Warehouse warehouse) {
    final color = _getWarehouseColor(warehouse);
    final icon = _getWarehouseIcon(warehouse);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (widget.onWarehouseSelected != null) {
              // ✅ Just calls back – StaffPanelDesktop switches screen internally
              widget.onWarehouseSelected!(warehouse);
            } else {
              // Fallback
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffPanelWarehouse(warehouse: warehouse),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Top row: icon + status badge ───
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Spacer(),
                    // "Active" badge
                    if (warehouse.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ─── Title ───
                Text(
                  warehouse.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  warehouse.categories.join(', '),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // ─── "Open Station" action row ───
                Row(
                  children: [
                    Text(
                      'Open Station',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Helper to generate consistent colors/icons
  Color _getWarehouseColor(Warehouse warehouse) {
    final palette = [Colors.brown, Colors.amber, Colors.orange, Colors.purple];
    final hash = warehouse.id.hashCode;
    return palette[hash.abs() % palette.length];
  }

  IconData _getWarehouseIcon(Warehouse warehouse) {
    // Simple heuristic
    final name = warehouse.name.toLowerCase();
    if (name.contains('flour')) return Icons.grain;
    if (name.contains('oil')) return Icons.water_drop;
    if (name.contains('bakery') || name.contains('bread')) return Icons.bakery_dining;
    return Icons.warehouse;
  }
}
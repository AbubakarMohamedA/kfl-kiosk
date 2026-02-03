import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/staff_panel_warehouse.dart';

/// Callback type so StaffPanelDesktop can switch its own _currentScreen
/// without this widget doing a Navigator.push.
typedef OnWarehouseSelected = void Function(Warehouse warehouse);

class WarehouseSelectorScreen extends StatelessWidget {
  /// When provided, selecting a warehouse calls this instead of pushing a route.
  /// StaffPanelDesktop passes its own setState-based switcher here.
  final OnWarehouseSelected? onWarehouseSelected;

  const WarehouseSelectorScreen({
    super.key,
    this.onWarehouseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Header (matches AnalyticsScreen._buildHeader style) ───
        _buildHeader(context),

        // ─── Body: sidebar + main grid ───
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebar(context),
              Expanded(
                child: SingleChildScrollView(
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

                      // ─── 2-column warehouse grid ───
                      _buildWarehouseGrid(context),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Station Summary'),
                      const SizedBox(height: 16),
                      _buildSummaryCards(),
                    ],
                  ),
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
                'Manage and monitor all stations',
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
  // SIDEBAR – matches AnalyticsScreen._buildSidebar layout & style
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Quick-info cards stacked vertically, like Analytics sidebar items
          _buildSidebarInfoItem(
            Icons.grain,
            'Flour',
            'Standard products',
            Colors.brown,
          ),
          _buildSidebarInfoItem(
            Icons.grade,
            'Premium Flour',
            'Specialty products',
            Colors.amber,
          ),
          _buildSidebarInfoItem(
            Icons.bakery_dining,
            'Baker Flour',
            'Commercial flour',
            Colors.orange,
          ),
          _buildSidebarInfoItem(
            Icons.water_drop,
            'Cooking Oil',
            'Oil products',
            Colors.yellow.shade700,
          ),
          const Spacer(),
          // ─── Period-style info box at the bottom (matches Analytics) ───
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Stations',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '4 Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All stations operational',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
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

  Widget _buildSidebarInfoItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: color,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WAREHOUSE GRID – cards styled like Analytics KPI cards with shadows
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildWarehouseGrid(BuildContext context) {
    final warehouses = [
      _WarehouseInfo(
        warehouse: Warehouse.flour,
        title: 'Flour',
        description: 'Standard flour products',
        icon: Icons.grain,
        color: Colors.brown,
      ),
      _WarehouseInfo(
        warehouse: Warehouse.premiumFlour,
        title: 'Premium Flour',
        description: 'Premium & specialty flour',
        icon: Icons.grade,
        color: Colors.amber,
      ),
      _WarehouseInfo(
        warehouse: Warehouse.bakerFlour,
        title: 'Baker Flour',
        description: 'Commercial baker flour',
        icon: Icons.bakery_dining,
        color: Colors.orange,
      ),
      _WarehouseInfo(
        warehouse: Warehouse.cookingOil,
        title: 'Cooking Oil',
        description: 'Cooking oil products',
        icon: Icons.water_drop,
        color: Colors.yellow.shade700,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: warehouses.map((info) => _buildWarehouseCard(context, info)).toList(),
    );
  }

  Widget _buildWarehouseCard(BuildContext context, _WarehouseInfo info) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
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
            if (onWarehouseSelected != null) {
              // ✅ Just calls back – StaffPanelDesktop switches screen internally
              onWarehouseSelected!(info.warehouse);
            } else {
              // Fallback for standalone use (should not happen in Staff Panel)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffPanelWarehouse(warehouse: info.warehouse),
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
                        color: info.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(info.icon, color: info.color, size: 28),
                    ),
                    const Spacer(),
                    // "Active" badge – mirrors Analytics change badges
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
                  info.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
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
                        color: info.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: info.color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SUMMARY CARDS – row of 4 small stat cards (like KPI cards in Analytics)
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard(
            'Total Stations',
            '4',
            Icons.warehouse,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStatCard(
            'Active Now',
            '4',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStatCard(
            'Pending Pickups',
            '12',
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStatCard(
            'Completed Today',
            '38',
            Icons.check_circle_outline,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
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
}

/// Simple data holder – not exported, used only inside this file.
class _WarehouseInfo {
  final Warehouse warehouse;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _WarehouseInfo({
    required this.warehouse,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
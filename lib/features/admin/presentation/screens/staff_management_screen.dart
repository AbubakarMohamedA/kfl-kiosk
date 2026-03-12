import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/features/orders/domain/entities/order.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_state.dart';
import 'package:sss/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:intl/intl.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _staffMembers = [
    {
      'id': 'STF001',
      'name': 'John Kamau',
      'role': 'Manager',
      'email': 'john.kamau@kfm.co.ke',
      'phone': '+254712345678',
      'status': 'Active',
      'hireDate': DateTime(2022, 3, 15),
      'avatar': 'JK',
      'permissions': ['orders', 'history', 'insights', 'warehouse'],
      'shift': 'Morning (6AM - 2PM)',
      'performance': 95.0,
      'ordersCompleted': 1250,
      'avgCompletionTime': 8.5,
      'attendance': 98.5,
    },
    {
      'id': 'STF002',
      'name': 'Mary Wanjiku',
      'role': 'Cashier',
      'email': 'mary.wanjiku@kfm.co.ke',
      'phone': '+254723456789',
      'status': 'Active',
      'hireDate': DateTime(2023, 1, 10),
      'avatar': 'MW',
      'permissions': ['orders', 'history'],
      'shift': 'Afternoon (2PM - 10PM)',
      'performance': 92.0,
      'ordersCompleted': 980,
      'avgCompletionTime': 9.2,
      'attendance': 96.0,
    },
    {
      'id': 'STF003',
      'name': 'Peter Ochieng',
      'role': 'Cashier',
      'email': 'peter.ochieng@kfm.co.ke',
      'phone': '+254734567890',
      'status': 'Active',
      'hireDate': DateTime(2023, 6, 20),
      'avatar': 'PO',
      'permissions': ['orders', 'history'],
      'shift': 'Morning (6AM - 2PM)',
      'performance': 88.0,
      'ordersCompleted': 750,
      'avgCompletionTime': 10.1,
      'attendance': 94.5,
    },
    {
      'id': 'STF004',
      'name': 'Grace Akinyi',
      'role': 'Kitchen Staff',
      'email': 'grace.akinyi@kfm.co.ke',
      'phone': '+254745678901',
      'status': 'Active',
      'hireDate': DateTime(2022, 9, 5),
      'avatar': 'GA',
      'permissions': ['orders'],
      'shift': 'Morning (6AM - 2PM)',
      'performance': 90.0,
      'ordersCompleted': 1100,
      'avgCompletionTime': 8.8,
      'attendance': 97.0,
    },
    {
      'id': 'STF005',
      'name': 'David Kiprop',
      'role': 'Kitchen Staff',
      'email': 'david.kiprop@kfm.co.ke',
      'phone': '+254756789012',
      'status': 'On Leave',
      'hireDate': DateTime(2023, 2, 14),
      'avatar': 'DK',
      'permissions': ['orders'],
      'shift': 'Afternoon (2PM - 10PM)',
      'performance': 85.0,
      'ordersCompleted': 650,
      'avgCompletionTime': 11.0,
      'attendance': 91.0,
    },
  ];

  final List<Map<String, dynamic>> _attendanceRecords = [
    {
      'date': DateTime.now(),
      'staffId': 'STF001',
      'checkIn': DateTime.now().subtract(const Duration(hours: 6)),
      'checkOut': null,
      'status': 'Present',
    },
    {
      'date': DateTime.now(),
      'staffId': 'STF002',
      'checkIn': DateTime.now().subtract(const Duration(hours: 2)),
      'checkOut': null,
      'status': 'Present',
    },
    {
      'date': DateTime.now(),
      'staffId': 'STF003',
      'checkIn': DateTime.now().subtract(const Duration(hours: 6)),
      'checkOut': null,
      'status': 'Present',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── ORDER / WAREHOUSE HELPERS ────────────────────────────────────────────

  List<String> _getOrderWarehouseCategories(Order order) {
    return order.items.map((i) => i.product.category).toSet().toList();
  }

  double _getOrderCompletionPercent(Order order) {
    if (order.items.isEmpty) return 0.0;
    final fulfilled = order.items.where((i) => i.status == AppConstants.statusFulfilled).length;
    return (fulfilled / order.items.length) * 100.0;
  }

  double _getWarehouseCompletionPercent(Order order, String category) {
    final items = order.items.where((i) => i.product.category == category).toList();
    if (items.isEmpty) return 0.0;
    final fulfilled = items.where((i) => i.status == AppConstants.statusFulfilled).length;
    return (fulfilled / items.length) * 100.0;
  }

  String _getWarehouseStatus(Order order, String category) {
    final items = order.items.where((i) => i.product.category == category).toList();
    if (items.isEmpty) return AppConstants.statusFulfilled;
    final statuses = items.map((i) => i.status).toSet();
    if (statuses.contains(AppConstants.statusPaid)) return AppConstants.statusPaid;
    if (statuses.contains(AppConstants.statusPreparing)) return AppConstants.statusPreparing;
    if (statuses.contains(AppConstants.statusReadyForPickup)) return AppConstants.statusReadyForPickup;
    return AppConstants.statusFulfilled;
  }

  bool _isOrderActive(Order order) {
    return order.items.any((i) => i.status != AppConstants.statusFulfilled);
  }

  Color _warehouseColor(String category) {
    switch (category) {
      case 'Flour': return Colors.brown;
      case 'Premium Flour': return Colors.amber;
      case 'Bakers Flour': return Colors.orange;
      case 'Cooking Oil': return Colors.yellow.shade700;
      default: return Colors.blueGrey;
    }
  }

  IconData _warehouseIcon(String category) {
    switch (category) {
      case 'Flour': return Icons.grain;
      case 'Premium Flour': return Icons.grade;
      case 'Bakers Flour': return Icons.bakery_dining;
      case 'Cooking Oil': return Icons.water_drop;
      default: return Icons.inventory_2;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.statusPaid: return Colors.blue;
      case AppConstants.statusPreparing: return Colors.orange;
      case AppConstants.statusReadyForPickup: return Colors.purple;
      case AppConstants.statusFulfilled: return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case AppConstants.statusPaid: return Icons.payment;
      case AppConstants.statusPreparing: return Icons.autorenew;
      case AppConstants.statusReadyForPickup: return Icons.inventory_2;
      case AppConstants.statusFulfilled: return Icons.check_circle;
      default: return Icons.circle;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusPaid: return 'PAID';
      case AppConstants.statusPreparing: return 'PREPARING';
      case AppConstants.statusReadyForPickup: return 'READY';
      case AppConstants.statusFulfilled: return 'PICKED UP';
      default: return status.toUpperCase();
    }
  }

  Color _getPerformanceColor(double performance) {
    if (performance >= 90) return Colors.green;
    if (performance >= 75) return Colors.blue;
    if (performance >= 60) return Colors.orange;
    return Colors.red;
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
                      _buildStaffRosterTab(),
                      _buildAttendanceTab(),
                      _buildPerformanceTab(),
                      _buildSchedulingTab(),
                      _buildActiveOrdersTab(),
                      _buildOrderHistoryTab(),
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
            child: const Icon(Icons.people_outline, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Staff Management', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${_staffMembers.where((s) => s['status'] == 'Active').length} active staff members', style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddStaffDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final activeStaff = _staffMembers.where((s) => s['status'] == 'Active').length;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          _buildSidebarItem(0, Icons.badge_outlined, 'Staff Roster'),
          _buildSidebarItem(1, Icons.access_time, 'Attendance'),
          _buildSidebarItem(2, Icons.bar_chart, 'Performance'),
          _buildSidebarItem(3, Icons.calendar_month, 'Scheduling'),
          const Divider(indent: 16, endIndent: 16),
          _buildSidebarItem(4, Icons.shopping_basket, 'Active Orders'),
          _buildSidebarItem(5, Icons.history, 'Order History'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                _buildQuickStat('Active Staff', '$activeStaff', Icons.people, Colors.green),
                // const SizedBox(height: 12),
                // _buildQuickStat('On Leave', '$onLeave', Icons.beach_access, Colors.orange),
                // const SizedBox(height: 12),
                // _buildQuickStat('Present Today', '$presentToday', Icons.check_circle, Colors.blue),
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
          color: isSelected ? const Color(AppColors.primaryBlue).withValues(alpha: 0.1) : Colors.transparent,
          border: Border(left: BorderSide(color: isSelected ? const Color(AppColors.primaryBlue) : Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(AppColors.primaryBlue) : Colors.grey[600], size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? const Color(AppColors.primaryBlue) : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
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
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffRosterTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search staff by name, ID, or role...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                child: DropdownButton<String>(
                  value: 'All Roles',
                  underline: const SizedBox.shrink(),
                  items: ['All Roles', 'Manager', 'Cashier', 'Kitchen Staff'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
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
                const Text('Staff Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._staffMembers.map((staff) => _buildStaffCard(staff)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(AppColors.primaryBlue).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text(staff['avatar'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(AppColors.primaryBlue)))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(staff['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: staff['status'] == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(staff['status'], style: TextStyle(color: staff['status'] == 'Active' ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${staff['role']} • ${staff['id']}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(staff['email'], style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 16),
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(staff['phone'], style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${staff['performance'].toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(AppColors.primaryBlue))),
              Text('Performance', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(width: 24),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'edit': _showEditStaffDialog(staff); break;
                case 'permissions': _showPermissionsDialog(staff); break;
                case 'deactivate': _showDeactivateDialog(staff); break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
              const PopupMenuItem(value: 'permissions', child: Text('Manage Permissions')),
              const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAttendanceCard('Present Today', '${_attendanceRecords.where((r) => r['status'] == 'Present').length}', Icons.check_circle, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildAttendanceCard('On Leave', '${_staffMembers.where((s) => s['status'] == 'On Leave').length}', Icons.beach_access, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildAttendanceCard('Absent', '0', Icons.cancel, Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _buildAttendanceCard('Late Check-ins', '0', Icons.access_time_filled, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Attendance Records', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_today), label: Text(DateFormat('MMMM dd, yyyy').format(DateTime.now()))),
            ],
          ),
          const SizedBox(height: 16),
          _buildAttendanceTable(),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(
              children: [
                _buildTableHeader('Staff ID', flex: 1),
                _buildTableHeader('Name', flex: 2),
                _buildTableHeader('Check In', flex: 2),
                _buildTableHeader('Check Out', flex: 2),
                _buildTableHeader('Hours', flex: 1),
                _buildTableHeader('Status', flex: 1),
              ],
            ),
          ),
          ..._attendanceRecords.map((record) {
            final staff = _staffMembers.firstWhere((s) => s['id'] == record['staffId']);
            final hours = record['checkOut'] != null ? record['checkOut'].difference(record['checkIn']).inHours : DateTime.now().difference(record['checkIn']).inHours;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text(staff['id'], style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(staff['name'], style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(DateFormat('HH:mm').format(record['checkIn']), style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text(record['checkOut'] != null ? DateFormat('HH:mm').format(record['checkOut']) : 'In Progress', style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 1, child: Text('${hours}h', style: const TextStyle(fontSize: 13))),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(record['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {required int flex}) {
    return Expanded(flex: flex, child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)));
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff Performance Metrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._staffMembers.where((s) => s['status'] == 'Active').toList().asMap().entries.map((entry) {
            return _buildPerformanceCard(entry.value, entry.key + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> staff, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey[400]! : rank == 3 ? Colors.orange[300]! : Colors.grey[200]!, width: rank <= 3 ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey[400] : rank == 3 ? Colors.orange[300] : const Color(AppColors.primaryBlue).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text('#$rank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.white : const Color(AppColors.primaryBlue)))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(staff['role'], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          _buildMetricChip(Icons.shopping_cart, '${staff['ordersCompleted']}', 'Orders'),
          const SizedBox(width: 12),
          _buildMetricChip(Icons.timer, '${staff['avgCompletionTime']}m', 'Avg Time'),
          const SizedBox(width: 12),
          _buildMetricChip(Icons.calendar_today, '${staff['attendance'].toStringAsFixed(1)}%', 'Attendance'),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: _getPerformanceColor(staff['performance']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Text('${staff['performance'].toStringAsFixed(1)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getPerformanceColor(staff['performance']))),
                Text('Score', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSchedulingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Work Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Shift'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppColors.primaryBlue), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScheduleGrid(),
          const SizedBox(height: 24),
          _buildShiftLegend(),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(
              children: [
                const SizedBox(width: 150),
                ...List.generate(7, (index) {
                  final date = DateTime.now().add(Duration(days: index));
                  return Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(DateFormat('EEE').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          ..._staffMembers.where((s) => s['status'] == 'Active').map((staff) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: [
                        Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(color: const Color(AppColors.primaryBlue).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Center(child: Text(staff['avatar'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(AppColors.primaryBlue)))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(staff['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  ...List.generate(7, (index) => Expanded(child: Center(child: _buildShiftChip(staff['shift'])))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShiftChip(String shift) {
    Color color;
    if (shift.contains('Morning')) {
      color = Colors.blue;
    } else if (shift.contains('Afternoon')) {
      color = Colors.orange;
    } else if (shift.contains('Night')) {
      color = Colors.purple;
    } else {
      color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(shift.split('(')[0].trim(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _buildShiftLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shift Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildShiftLegendItem('Morning (6AM - 2PM)', Colors.blue),
              _buildShiftLegendItem('Afternoon (2PM - 10PM)', Colors.orange),
              _buildShiftLegendItem('Night (10PM - 6AM)', Colors.purple),
              _buildShiftLegendItem('Full Day (6AM - 6PM)', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildActiveOrdersTab() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final activeOrders = state.orders.where((o) => _isOrderActive(o)).toList();
          if (activeOrders.isEmpty) {
            return _buildEmptyState(Icons.check_circle_outline, 'No Active Orders', 'All orders have been fully picked up');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final order = activeOrders[activeOrders.length - 1 - index];
              return _buildActiveOrderCard(order);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildActiveOrderCard(Order order) {
    final percent = _getOrderCompletionPercent(order);
    final categories = _getOrderWarehouseCategories(order);
    return GestureDetector(
      onTap: () => _showOrderDetailBottomSheet(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(AppColors.primaryBlue).withValues(alpha: 0.18)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Padding(
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
                        decoration: BoxDecoration(color: const Color(AppColors.primaryBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_long, color: Color(AppColors.primaryBlue), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Phone: ${order.phone}  •  ${DateFormat('dd MMM, HH:mm').format(order.timestamp)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  _buildCompletionRing(percent, 48),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final whPercent = _getWarehouseCompletionPercent(order, cat);
                  final whColor = _warehouseColor(cat);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: whColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: whColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_warehouseIcon(cat), size: 14, color: whColor),
                        const SizedBox(width: 6),
                        Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: whColor)),
                        const SizedBox(width: 6),
                        Text('${whPercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: whColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent / 100.0,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(percent >= 100 ? Colors.green : const Color(AppColors.primaryBlue)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${percent.toStringAsFixed(0)}% picked up  •  KSh ${order.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                  Row(
                    children: [
                      // const Icon(Icons.tap, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Tap for details', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailBottomSheet(Order order) {
    final categories = _getOrderWarehouseCategories(order);
    final totalPercent = _getOrderCompletionPercent(order);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Phone: ${order.phone}  •  KSh ${order.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('Ordered: ${DateFormat('EEEE, MMMM d, yyyy HH:mm').format(order.timestamp)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  _buildCompletionRing(totalPercent, 56),
                ],
              ),
              const SizedBox(height: 24),
              ...categories.map((category) {
                final whStatus = _getWarehouseStatus(order, category);
                final whPercent = _getWarehouseCompletionPercent(order, category);
                final whItems = order.items.where((i) => i.product.category == category).toList();
                final whTotal = whItems.fold<double>(0.0, (sum, item) => sum + item.subtotal);
                final color = _warehouseColor(category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(_warehouseIcon(category), color: color, size: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(category, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                                    Text('${whItems.length} item${whItems.length > 1 ? 's' : ''}  •  KSh ${whTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(whStatus),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(value: whPercent / 100.0, minHeight: 6, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(whPercent >= 100 ? Colors.green : color)),
                              ),
                              const SizedBox(height: 6),
                              Text('${whPercent.toStringAsFixed(0)}% picked up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...whItems.map((item) => _buildItemRow(item)),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(CartItem item) {
    final sColor = _statusColor(item.status);
    final sIcon = _statusIcon(item.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Icon(sIcon, size: 18, color: sColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(item.product.size, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Text('x${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 14),
          Text('KSh ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          _buildStatusBadge(item.status),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryTab() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoaded) {
          final historyOrders = state.orders.where((o) => !_isOrderActive(o)).toList();
          if (historyOrders.isEmpty) {
            return _buildEmptyState(Icons.history, 'No Order History', 'Completed orders will appear here');
          }
          final grouped = <String, List<Order>>{};
          for (var order in historyOrders) {
            final key = DateFormat('yyyy-MM-dd').format(order.timestamp);
            grouped.putIfAbsent(key, () => []).add(order);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.toList()[grouped.length - 1 - index];
              final ordersForDate = grouped[dateKey]!;
              final date = DateTime.parse(dateKey);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateDivider(date, ordersForDate.length),
                  const SizedBox(height: 12),
                  ...ordersForDate.map((order) => _buildHistoryOrderCard(order)),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDateDivider(DateTime date, int count) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
    final label = isToday ? 'Today' : isYesterday ? 'Yesterday' : DateFormat('EEEE, MMMM d, yyyy').format(date);
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey[300])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
          child: Text('$count order${count > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildHistoryOrderCard(Order order) {
    final categories = _getOrderWarehouseCategories(order);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Order #${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
                            child: const Text('COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                      ),
                      Text('Phone: ${order.phone}  •  ${DateFormat('dd MMM yyyy, HH:mm').format(order.timestamp)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('KSh ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(AppColors.primaryBlue))),
                    Text('${order.items.length} item${order.items.length > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...categories.map((category) {
              final whItems = order.items.where((i) => i.product.category == category).toList();
              final whTotal = whItems.fold<double>(0.0, (sum, item) => sum + item.subtotal);
              final color = _warehouseColor(category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_warehouseIcon(category), size: 18, color: color),
                            const SizedBox(width: 8),
                            Text(category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            const Text('All picked up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                            const SizedBox(width: 12),
                            Text('KSh ${whTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...whItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(child: Text('${item.product.name} (${item.product.size})', style: const TextStyle(fontSize: 14))),
                              Text('x${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 16),
                              Text('KSh ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRing(double percent, double size) {
    final color = percent >= 100 ? Colors.green : percent >= 50 ? Colors.orange : const Color(AppColors.primaryBlue);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(value: percent / 100.0, strokeWidth: 5, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(color)),
          Center(child: Text('${percent.toStringAsFixed(0)}%', style: TextStyle(fontSize: size > 50 ? 14 : 11, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(icon, size: 60, color: Colors.grey[400])),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Role')),
              const SizedBox(height: 16),
              const Divider(),
              const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    final tenantFeatures = state.tenant.enabledFeatures;
                    // Mock state for new staff permissions
                    final selectedPermissions = <String>{};
                    
                    return StatefulBuilder(
                      builder: (context, setInnerState) {
                        return Column(
                          children: tenantFeatures.map((feature) {
                            final isSelected = selectedPermissions.contains(feature);
                            return CheckboxListTile(
                              title: Text(feature[0].toUpperCase() + feature.substring(1)),
                              value: isSelected,
                              activeColor: const Color(AppColors.primaryBlue),
                              onChanged: (value) {
                                setInnerState(() {
                                  if (value == true) {
                                    selectedPermissions.add(feature);
                                  } else {
                                    selectedPermissions.remove(feature);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      }
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member added successfully')));
            },
            child: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${staff['name']}'),
        content: const Text('Edit staff dialog coming soon...'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showPermissionsDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) {
        // Create a modifiable list of staff permissions
        final List<String> staffPermissions = List<String>.from(staff['permissions']);

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            List<String> tenantFeatures = [];
            if (state is AuthAuthenticated) {
              tenantFeatures = state.tenant.enabledFeatures;
            }

            return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: Text('Manage Permissions - ${staff['name']}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (tenantFeatures.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No features enabled for this tenant.'),
                        ),
                      ...tenantFeatures.map((feature) {
                        final isEnabled = staffPermissions.contains(feature);
                        return CheckboxListTile(
                          title: Text(feature[0].toUpperCase() + feature.substring(1)),
                          value: isEnabled,
                          activeColor: const Color(AppColors.primaryBlue),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                staffPermissions.add(feature);
                              } else {
                                staffPermissions.remove(feature);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        staff['permissions'] = staffPermissions;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permissions updated successfully')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeactivateDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Staff Member'),
        content: Text('Are you sure you want to deactivate ${staff['name']}? They will no longer have access to the system.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member deactivated')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
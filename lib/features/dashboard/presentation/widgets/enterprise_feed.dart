import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sss/features/orders/domain/entities/order.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/auth/domain/entities/branch.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_state.dart';

class EnterpriseFeed extends StatefulWidget {
  final bool isDarkMode;
  final DateTime selectedDate;
  final List<Branch> branches;

  const EnterpriseFeed({super.key, required this.isDarkMode, required this.selectedDate, required this.branches});

  @override
  State<EnterpriseFeed> createState() => _EnterpriseFeedState();
}

class _EnterpriseFeedState extends State<EnterpriseFeed> {
  String? _selectedBranchId; // null = All Branches

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is OrdersLoaded) {
          // Filter by date
          var orders = List<Order>.from(state.orders)
            .where((o) => o.timestamp.year == widget.selectedDate.year &&
                          o.timestamp.month == widget.selectedDate.month &&
                          o.timestamp.day == widget.selectedDate.day)
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Filter by branch if selected
          if (_selectedBranchId != null) {
            orders = orders.where((o) => o.branchId == _selectedBranchId).toList();
          }

          final latestOrders = orders.take(50).toList();

          return Column(
            children: [
              // Branch Filter Bar
              if (widget.branches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All Branches', style: TextStyle(fontSize: 12)),
                            selected: _selectedBranchId == null,
                            onSelected: (_) => setState(() => _selectedBranchId = null),
                            selectedColor: const Color(0xFF1a237e),
                            labelStyle: TextStyle(
                              color: _selectedBranchId == null ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Per-branch chips
                        ...widget.branches.map((b) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(b.name, style: const TextStyle(fontSize: 12)),
                            selected: _selectedBranchId == b.id,
                            onSelected: (_) => setState(() => _selectedBranchId = b.id),
                            selectedColor: const Color(0xFF1a237e),
                            labelStyle: TextStyle(
                              color: _selectedBranchId == b.id ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                              fontSize: 12,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              // Orders list
              Expanded(
                child: latestOrders.isEmpty
                    ? Center(child: Text(
                        _selectedBranchId != null ? 'No orders for this branch' : 'No recent activity',
                        style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.grey),
                      ))
                    : ListView.separated(
                        itemCount: latestOrders.length,
                        separatorBuilder: (c, i) => Divider(height: 1, color: widget.isDarkMode ? Colors.white10 : Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final order = latestOrders[index];
                          String branchName = order.branchId ?? 'Unknown Branch';
                          try {
                            if (order.branchId != null) {
                              branchName = widget.branches.firstWhere((b) => b.id == order.branchId).name;
                            }
                          } catch (_) {}

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.2),
                              child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 16),
                            ),
                            title: Text(
                              'Order #${order.id}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${order.phone} • $branchName',
                              style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.grey[600], fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'KSh ${order.total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                ),
                                Text(
                                  _formatTime(order.timestamp),
                                  style: TextStyle(fontSize: 10, color: widget.isDarkMode ? Colors.white38 : Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(time);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return Colors.blue;
      case 'preparing': return Colors.orange;
      case 'ready': return Colors.green;
      case 'completed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return Icons.payment;
      case 'preparing': return Icons.soup_kitchen;
      case 'ready': return Icons.check_circle;
      case 'completed': return Icons.done_all;
      default: return Icons.info;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_state.dart';

class EnterpriseFeed extends StatelessWidget {
  final bool isDarkMode;

  const EnterpriseFeed({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is OrdersLoaded) {
          // Flatten latest orders
          final orders = List<Order>.from(state.orders)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
          final latestOrders = orders.take(20).toList(); // Show last 20
          
          if (latestOrders.isEmpty) {
             return Center(child: Text('No recent activity', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey)));
          }

          return ListView.separated(
            itemCount: latestOrders.length,
            separatorBuilder: (c, i) => Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.grey[200]),
            itemBuilder: (context, index) {
              final order = latestOrders[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.2),
                  child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 16),
                ),
                title: Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '${order.phone} • ${order.branchId ?? "Unknown Branch"}',
                  style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey[600], fontSize: 12),
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
                      style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white38 : Colors.grey[400]),
                    ),
                  ],
                ),
              );
            },
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

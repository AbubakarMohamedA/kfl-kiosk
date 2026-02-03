import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/staff_panel_warehouse.dart';

class WarehouseOrderCard extends StatelessWidget {
  final Order order;
  final List<CartItem> warehouseItems;
  final Warehouse warehouse;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onMarkReady;
  final VoidCallback? onMarkFulfilled;

  const WarehouseOrderCard({
    super.key,
    required this.order,
    required this.warehouseItems,
    required this.warehouse,
    this.onStartPreparing,
    this.onMarkReady,
    this.onMarkFulfilled,
  });

  // ✅ FIXED: Derive status from the actual item statuses, not order.status
  String get _currentWarehouseStatus {
    if (warehouseItems.isEmpty) return AppConstants.statusFulfilled;

    final statuses = warehouseItems.map((item) => item.status).toSet();

    if (statuses.contains(AppConstants.statusPaid)) {
      return AppConstants.statusPaid;
    }
    if (statuses.contains(AppConstants.statusPreparing)) {
      return AppConstants.statusPreparing;
    }
    if (statuses.contains(AppConstants.statusReadyForPickup)) {
      return AppConstants.statusReadyForPickup;
    }
    return AppConstants.statusFulfilled;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use computed warehouse status everywhere
    final currentStatus = _currentWarehouseStatus;

    final warehouseTotal = warehouseItems.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: warehouse.color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            warehouse.icon,
                            color: warehouse.color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: warehouse.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(order.timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        order.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Container(
                        // padding: const EdgeInsets.symmetric(
                        //     horizontal: 12, vertical: 6),
                        // decoration: BoxDecoration(
                        //   color: warehouse.color.withValues(alpha: 0.1),
                        //   borderRadius: BorderRadius.circular(8),
                        //   border: Border.all(
                        //     color: warehouse.color.withValues(alpha: 0.3),
                        //   ),
                        // ),
                        // child: Text(
                        //   warehouse.category,
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.bold,
                        //     color: warehouse.color,
                        //   ),
                        // ),
                      // ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   'Items Total',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: Colors.grey[600],
                      //   ),
                      // ),
                      Text(
                        'KSh ${warehouseTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: warehouse.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ FIXED: Pass currentStatus instead of order.status
                      _buildStatusBadge(currentStatus),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Warehouse-specific items
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warehouse.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: warehouse.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: warehouse.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Items to Prepare (${warehouseItems.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: warehouse.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...warehouseItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // ✅ Per-item status dot color
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusDotColor(item.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${item.product.name} (${item.product.size})',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: warehouse.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'x${item.quantity}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: warehouse.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'KSh ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ FIXED: Pass currentStatus instead of reading order.status
              _buildActionButtons(currentStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusInfo['borderColor'],
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            size: 16,
            color: statusInfo['textColor'],
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusInfo['textColor'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return {
          'color': Colors.blue[50],
          'borderColor': Colors.blue[300],
          'textColor': Colors.blue[900],
          'icon': Icons.payment,
        };
      case AppConstants.statusPreparing:
        return {
          'color': Colors.orange[50],
          'borderColor': Colors.orange[300],
          'textColor': Colors.orange[900],
          'icon': Icons.autorenew,
        };
      case AppConstants.statusReadyForPickup:
        return {
          'color': Colors.purple[50],
          'borderColor': Colors.purple[300],
          'textColor': Colors.purple[900],
          'icon': Icons.inventory_2,
        };
      case AppConstants.statusFulfilled:
        return {
          'color': Colors.green[50],
          'borderColor': Colors.green[300],
          'textColor': Colors.green[900],
          'icon': Icons.check_circle,
        };
      default:
        return {
          'color': Colors.grey[50],
          'borderColor': Colors.grey[300],
          'textColor': Colors.grey[900],
          'icon': Icons.help_outline,
        };
    }
  }

  // ✅ FIXED: Accepts currentStatus as parameter instead of reading order.status
  Widget _buildActionButtons(String currentStatus) {
    if (currentStatus == AppConstants.statusPaid) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onStartPreparing,
          icon: const Icon(Icons.autorenew),
          label: Text(
            'Start Preparing ${warehouse.category} Items',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (currentStatus == AppConstants.statusPreparing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onMarkReady,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            'Mark ${warehouse.category} Items as Ready',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (currentStatus == AppConstants.statusReadyForPickup) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[300]!, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Customer will present Order ID #${order.id} to collect these items.',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onMarkFulfilled,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Items Picked Up by Customer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // FULFILLED
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              'Items Picked Up',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _statusDotColor(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return Colors.blue;
      case AppConstants.statusPreparing:
        return Colors.orange;
      case AppConstants.statusReadyForPickup:
        return Colors.purple;
      case AppConstants.statusFulfilled:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
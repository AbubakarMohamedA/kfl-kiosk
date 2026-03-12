// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
// import 'package:sss/core/constants/app_constants.dart';
// import 'package:sss/features/orders/domain/entities/order.dart';
// import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
// import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';
// import 'package:sss/features/orders/presentation/widgets/order_status_badge.dart';
// import 'package:sss/core/widgets/desktop/staff_order_card.dart';
// import 'package:sss/core/widgets/desktop/warehouse_order_card.dart';
// import 'package:sss/features/warehouse/domain/entities/warehouse.dart';
// import 'package:sss/features/warehouse/presentation/screens/staff_panel_warehouse.dart';

// class ConfigurableOrderCard extends StatelessWidget {
//   final Order order;
//   final Warehouse? warehouse; // For item-level mode
  
//   const ConfigurableOrderCard({
//     super.key,
//     required this.order,
//     this.warehouse,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<AppConfiguration>(
//       future: context.read<OrderBloc>().configurationRepository.getConfiguration(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const SizedBox.shrink();
//         }
        
//         final config = snapshot.data!;
        
//         // SHOW DIFFERENT CARD BASED ON MODE
//         if (config.statusTrackingMode == StatusTrackingMode.orderLevel) {
//           return StaffOrderCard(
//             order: order,
//             onStartPreparing: () => _updateOrderStatus(context, AppConstants.statusPreparing),
//             onMarkReady: () => _updateOrderStatus(context, AppConstants.statusReadyForPickup),
//             onMarkFulfilled: () => _updateOrderStatus(context, AppConstants.statusFulfilled),
//           );
//         } else {
//           // ITEM-LEVEL MODE: Show warehouse-specific card if warehouse provided
//           if (warehouse != null) {
//             final warehouseItems = order.getItemsForWarehouse(warehouse!.category);
//             if (warehouseItems.isEmpty) return const SizedBox.shrink();
            
//             return WarehouseOrderCard(
//               order: order,
//               warehouseItems: warehouseItems,
//               warehouse: warehouse!,
//               onStartPreparing: () => _updateWarehouseStatus(
//                 context, 
//                 warehouse!.category, 
//                 AppConstants.statusPreparing
//               ),
//               onMarkReady: () => _updateWarehouseStatus(
//                 context, 
//                 warehouse!.category, 
//                 AppConstants.statusReadyForPickup
//               ),
//               onMarkFulfilled: () => _updateWarehouseStatus(
//                 context, 
//                 warehouse!.category, 
//                 AppConstants.statusFulfilled
//               ),
//             );
//           } else {
//             // Fallback: Show simplified card for item-level mode without warehouse context
//             return _buildItemLevelCard(context, order, config);
//           }
//         }
//       },
//     );
//   }

//   Widget _buildItemLevelCard(BuildContext context, Order order, AppConfiguration config) {
//     final effectiveStatus = order.getEffectiveStatus(config);
    
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   Text(order.id, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 4),
//                   Text(order.phone, style: TextStyle(color: Colors.grey[600])),
//                 ]),
//                 Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
//                   Text('KSh ${order.total.toStringAsFixed(2)}', 
//                     style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B8843))),
//                   const SizedBox(height: 8),
//                   OrderStatusBadge(status: effectiveStatus),
//                 ]),
//               ],
//             ),
//             const SizedBox(height: 16),
//             const Divider(),
//             const SizedBox(height: 12),
//             // Show item categories with their statuses
//             Wrap(
//               spacing: 8,
//               children: order.items
//                 .map((item) => item.product.category)
//                 .toSet()
//                 .map((category) {
//                   final categoryItems = order.items.where((i) => i.product.category == category);
//                   final categoryStatus = categoryItems.map((i) => i.status).toSet().singleWhere(
//                     (s) => true,
//                     orElse: () => categoryItems.first.status,
//                   );
                  
//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(categoryStatus).withValues(alpha:0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: _getStatusColor(categoryStatus).withValues(alpha:0.3)),
//                     ),
//                     child: Text(
//                       '$category: ${categoryStatus.split('_').map((w) => w[0] + w.substring(1).toLowerCase()).join(' ')}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: _getStatusColor(categoryStatus),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _updateOrderStatus(BuildContext context, String newStatus) {
//     context.read<OrderBloc>().add(UpdateOrderStatus(
//       orderId: order.id,
//       status: newStatus,
//     ));
//   }

//   void _updateWarehouseStatus(BuildContext context, String category, String newStatus) {
//     context.read<OrderBloc>().add(UpdateWarehouseItemsStatus(
//       orderId: order.id,
//       warehouseCategory: category,
//       newStatus: newStatus,
//     ));
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case AppConstants.statusPaid: return Colors.blue;
//       case AppConstants.statusPreparing: return Colors.orange;
//       case AppConstants.statusReadyForPickup: return Colors.purple;
//       case AppConstants.statusFulfilled: return Colors.green;
//       default: return Colors.grey;
//     }
//   }
// }
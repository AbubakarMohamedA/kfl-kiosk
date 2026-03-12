import 'package:equatable/equatable.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';

class Order extends Equatable {
  final String id;
  final List<CartItem> items;
  final double total;
  final String phone;
  final DateTime timestamp;
  final String status; // Keep for backward compatibility
  final String? tenantId; // Nullable for legacy orders
  final String? branchId; // Nullable for non-enterprise or legacy
  final String? terminalId;


  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.phone,
    required this.timestamp,
    required this.status,
    this.tenantId,
    this.branchId,
    this.terminalId,
  });

  @override
  List<Object?> get props => [id, items, total, phone, timestamp, status, tenantId, branchId, terminalId];

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? total,
    String? phone,
    DateTime? timestamp,
    String? status,
    String? tenantId,
    String? branchId,
    String? terminalId,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      phone: phone ?? this.phone,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      terminalId: terminalId ?? this.terminalId,
    );
  }

  // ✅ NEW: Set ALL items to the same status (for order-level mode)
  Order setAllItemsStatus(String newStatus) {
    final updatedItems = items
        .map((item) => item.copyWith(status: newStatus))
        .toList();
    return copyWith(
      items: updatedItems,
      // Also update top-level status for consistency
      status: newStatus,
    );
  }

  // ✅ NEW: Get items for specific warehouse categories
  List<CartItem> getItemsForWarehouse(List<String> warehouseCategories) {
    return items
        .where((item) => warehouseCategories.contains(item.product.category))
        .toList();
  }

  // ✅ NEW: Get warehouse-specific status
  String getWarehouseStatus(List<String> warehouseCategories) {
    final warehouseItems = getItemsForWarehouse(warehouseCategories);
    if (warehouseItems.isEmpty) {
      return AppConstants.statusFulfilled; // No items = already done
    }
    final statuses = warehouseItems.map((item) => item.status).toSet();
    // Return the "lowest" status (earliest in workflow)
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

  // ✅ NEW: Check if all warehouse items have a specific status
  bool warehouseItemsHaveStatus(List<String> warehouseCategories, String status) {
    final warehouseItems = getItemsForWarehouse(warehouseCategories);
    return warehouseItems.isNotEmpty &&
        warehouseItems.every((item) => item.status == status);
  }

  // ✅ NEW: Check if warehouse has any items in specific status
  bool warehouseHasItemsInStatus(List<String> warehouseCategories, String status) {
    final warehouseItems = getItemsForWarehouse(warehouseCategories);
    return warehouseItems.any((item) => item.status == status);
  }

  // ✅ NEW: Update items status for a specific warehouse
  Order updateWarehouseItemsStatus(List<String> warehouseCategories, String newStatus) {
    final updatedItems = items.map((item) {
      if (warehouseCategories.contains(item.product.category)) {
        return item.copyWith(status: newStatus);
      }
      return item;
    }).toList();
    return copyWith(items: updatedItems);
  }

  // ✅ NEW: Get overall order status based on all item statuses
  String get overallStatus {
    if (items.isEmpty) return status; // Fallback to old status
    final itemStatuses = items.map((item) => item.status).toSet();
    // If ANY item is still paid, order is PAID
    if (itemStatuses.contains(AppConstants.statusPaid)) {
      return AppConstants.statusPaid;
    }
    // If ANY item is preparing, order is PREPARING
    if (itemStatuses.contains(AppConstants.statusPreparing)) {
      return AppConstants.statusPreparing;
    }
    // If ANY item is ready, order is READY
    if (itemStatuses.contains(AppConstants.statusReadyForPickup)) {
      return AppConstants.statusReadyForPickup;
    }
    // If ALL items are fulfilled, order is FULFILLED
    if (itemStatuses.every((s) => s == AppConstants.statusFulfilled)) {
      return AppConstants.statusFulfilled;
    }
    return status; // Fallback
  }

  // ✅ NEW: Get effective status based on configuration mode
  String getEffectiveStatus(AppConfiguration config) {
    if (config.statusTrackingMode == StatusTrackingMode.orderLevel) {
      return status; // Use top-level status
    }
    return overallStatus; // Use computed status from items
  }

  // ✅ NEW: Check if order is active based on configuration mode
  bool isActive(AppConfiguration config) {
    final effectiveStatus = getEffectiveStatus(config);
    return effectiveStatus != AppConstants.statusFulfilled &&
        effectiveStatus != 'CANCELLED';
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'phone': phone,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'tenantId': tenantId,
      'branchId': branchId,
      'terminalId': terminalId,
    };
  }

  // Create from Firestore map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] ?? 0).toDouble(),
      phone: map['phone'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? AppConstants.statusPaid,
      tenantId: map['tenantId'],
      branchId: map['branchId'],
      terminalId: map['terminalId'],
    );
  }
}
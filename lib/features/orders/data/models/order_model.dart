import 'package:json_annotation/json_annotation.dart';
import 'package:sss/features/cart/data/models/cart_item_model.dart';
import 'package:sss/features/orders/domain/entities/order.dart';

part 'order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderModel {
  @JsonKey(fromJson: _idToString)
  final String id;
  
  @JsonKey(name: 'items')
  final List<CartItemModel> cartItems;
  
  final double total;
  final String phone;
  final DateTime timestamp;
  final String status;
  
  @JsonKey(fromJson: _nullableIdToString)
  final String? tenantId;
  
  final String? branchId;
  final String? terminalId;
  final String sapSyncStatus;
  final int? sapDocEntry;
  final String? sapCardCode;

  const OrderModel({
    required this.id,
    required this.cartItems,
    required this.total,
    required this.phone,
    required this.timestamp,
    required this.status,
    this.tenantId,
    this.branchId,
    this.terminalId,
    this.sapSyncStatus = 'pending',
    this.sapDocEntry,
    this.sapCardCode,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  // Create OrderModel from Order entity
  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      cartItems: order.items.map((e) => CartItemModel.fromEntity(e)).toList(),
      total: order.total,
      phone: order.phone,
      timestamp: order.timestamp,
      status: order.status,
      tenantId: order.tenantId,
      branchId: order.branchId,
      terminalId: order.terminalId,
      sapSyncStatus: order.sapSyncStatus,
      sapDocEntry: order.sapDocEntry,
      sapCardCode: order.sapCardCode,
    );
  }

  // Convert OrderModel to Order entity
  Order toEntity() {
    return Order(
      id: id,
      items: cartItems.map((e) => e.toEntity()).toList(),
      total: total,
      phone: phone,
      timestamp: timestamp,
      status: status,
      tenantId: tenantId,
      branchId: branchId,
      terminalId: terminalId,
      sapSyncStatus: sapSyncStatus,
      sapDocEntry: sapDocEntry,
      sapCardCode: sapCardCode,
    );
  }

  // CopyWith method
  OrderModel copyWith({
    String? id,
    List<CartItemModel>? cartItems,
    double? total,
    String? phone,
    DateTime? timestamp,
    String? status,
    String? tenantId,
    String? branchId,
    String? terminalId,
    String? sapSyncStatus,
    int? sapDocEntry,
    String? sapCardCode,
  }) {
    return OrderModel(
      id: id ?? this.id,
      cartItems: cartItems ?? this.cartItems,
      total: total ?? this.total,
      phone: phone ?? this.phone,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      terminalId: terminalId ?? this.terminalId,
      sapSyncStatus: sapSyncStatus ?? this.sapSyncStatus,
      sapDocEntry: sapDocEntry ?? this.sapDocEntry,
      sapCardCode: sapCardCode ?? this.sapCardCode,
    );
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, items: ${cartItems.length}, total: $total, phone: $phone, status: $status, sapSyncStatus: $sapSyncStatus, sapDocEntry: $sapDocEntry)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderModel &&
        other.id == id &&
        other.total == total &&
        other.phone == phone &&
        other.status == status &&
        other.tenantId == tenantId &&
        other.branchId == branchId &&
        other.terminalId == terminalId &&
        other.sapSyncStatus == sapSyncStatus &&
        other.sapDocEntry == sapDocEntry &&
        other.sapCardCode == sapCardCode;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        total.hashCode ^
        phone.hashCode ^
        timestamp.hashCode ^
        status.hashCode ^
        tenantId.hashCode ^
        branchId.hashCode ^
        terminalId.hashCode ^
        sapSyncStatus.hashCode ^
        sapDocEntry.hashCode ^
        sapCardCode.hashCode;
  }
}

// Resilient converters
String _idToString(dynamic value) => value.toString();
String? _nullableIdToString(dynamic value) => value?.toString();
import 'package:json_annotation/json_annotation.dart';
import 'package:kfm_kiosk/features/cart/data/models/cart_item_model.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';

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

  const OrderModel({
    required this.id,
    required this.cartItems,
    required this.total,
    required this.phone,
    required this.timestamp,
    required this.status,
    this.tenantId,
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
  }) {
    return OrderModel(
      id: id ?? this.id,
      cartItems: cartItems ?? this.cartItems,
      total: total ?? this.total,
      phone: phone ?? this.phone,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, items: ${cartItems.length}, total: $total, phone: $phone, status: $status, tenantId: $tenantId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderModel &&
        other.id == id &&
        other.total == total &&
        other.phone == phone &&
        other.status == status &&
        other.tenantId == tenantId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        total.hashCode ^
        phone.hashCode ^
        timestamp.hashCode ^
        status.hashCode ^
        tenantId.hashCode;
  }
}

// Resilient converters
String _idToString(dynamic value) => value.toString();
String? _nullableIdToString(dynamic value) => value?.toString();
import 'package:json_annotation/json_annotation.dart';
import 'package:kfm_kiosk/data/models/cart_item_model.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel extends Order {
  @JsonKey(fromJson: _itemsFromJson, toJson: _itemsToJson)
  final List<CartItemModel> _items;

  @override
  List<CartItemModel> get items => _items;

  const OrderModel({
    required super.id,
    required List<CartItemModel> items,
    required super.total,
    required super.phone,
    required super.timestamp,
    required super.status,
  }) : _items = items,
       super(items: items);

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  static List<CartItemModel> _itemsFromJson(List<dynamic> json) =>
      json.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> _itemsToJson(List<CartItemModel> items) =>
      items.map((e) => e.toJson()).toList();

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      items: order.items.map((e) => CartItemModel.fromEntity(e)).toList(),
      total: order.total,
      phone: order.phone,
      timestamp: order.timestamp,
      status: order.status,
    );
  }

  Order toEntity() {
    return Order(
      id: id,
      items: items.map((e) => e.toEntity()).toList(),
      total: total,
      phone: phone,
      timestamp: timestamp,
      status: status,
    );
  }
}
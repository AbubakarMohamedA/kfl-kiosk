// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String,
  items: OrderModel._itemsFromJson(json['items'] as List),
  total: (json['total'] as num).toDouble(),
  phone: json['phone'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'total': instance.total,
      'phone': instance.phone,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': instance.status,
      'items': OrderModel._itemsToJson(instance.items),
    };

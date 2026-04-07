// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: _idToString(json['id']),
  cartItems: (json['items'] as List<dynamic>)
      .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  phone: json['phone'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  status: json['status'] as String,
  tenantId: _nullableIdToString(json['tenantId']),
  branchId: json['branchId'] as String?,
  terminalId: json['terminalId'] as String?,
  sapSyncStatus: json['sapSyncStatus'] as String? ?? 'pending',
  sapDocEntry: (json['sapDocEntry'] as num?)?.toInt(),
  sapCardCode: json['sapCardCode'] as String?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.cartItems.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'phone': instance.phone,
      'timestamp': instance.timestamp.toIso8601String(),
      'status': instance.status,
      'tenantId': instance.tenantId,
      'branchId': instance.branchId,
      'terminalId': instance.terminalId,
      'sapSyncStatus': instance.sapSyncStatus,
      'sapDocEntry': instance.sapDocEntry,
      'sapCardCode': instance.sapCardCode,
    };

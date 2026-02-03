// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// ****
// JsonSerializableGenerator
// ****

CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    CartItemModel(
      productModel:
          ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      status: json['status'] as String? ?? 'PAID',
    );

Map<String, dynamic> _$CartItemModelToJson(CartItemModel instance) =>
    <String, dynamic>{
      'product': instance.productModel.toJson(),
      'quantity': instance.quantity,
      'status': instance.status,
    };
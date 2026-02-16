// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItemModel _$CartItemModelFromJson(Map<String, dynamic> json) =>
    CartItemModel(
      productModel: ProductModel.fromJson(
        json['productModel'] as Map<String, dynamic>,
      ),
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String? ?? AppConstants.statusPaid,
    );

Map<String, dynamic> _$CartItemModelToJson(CartItemModel instance) =>
    <String, dynamic>{
      'productModel': instance.productModel,
      'quantity': instance.quantity,
      'status': instance.status,
    };

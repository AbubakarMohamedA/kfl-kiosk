// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['id'] as String,
  name: json['name'] as String,
  brand: json['brand'] as String,
  price: (json['price'] as num).toDouble(),
  size: json['size'] as String,
  category: json['category'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String,
  salesVatGroup: json['salesVatGroup'] as String?,
  itemPrices:
      (json['itemPrices'] as List<dynamic>?)
          ?.map((e) => PriceModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tenantId: json['tenantId'] as String?,
  branchId: json['branchId'] as String?,
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'price': instance.price,
      'size': instance.size,
      'category': instance.category,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'salesVatGroup': instance.salesVatGroup,
      'itemPrices': instance.itemPrices,
      'tenantId': instance.tenantId,
      'branchId': instance.branchId,
    };

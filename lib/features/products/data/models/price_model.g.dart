// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceModel _$PriceModelFromJson(Map<String, dynamic> json) => PriceModel(
  priceList: (json['priceList'] as num).toInt(),
  price: (json['price'] as num).toDouble(),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$PriceModelToJson(PriceModel instance) =>
    <String, dynamic>{
      'priceList': instance.priceList,
      'price': instance.price,
      'currency': instance.currency,
    };

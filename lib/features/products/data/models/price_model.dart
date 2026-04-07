import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'price_model.g.dart';

@JsonSerializable()
class PriceModel extends Equatable {
  final int priceList;
  final double price;
  final String? currency;

  const PriceModel({
    required this.priceList,
    required this.price,
    this.currency,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) => _$PriceModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceModelToJson(this);

  @override
  List<Object?> get props => [priceList, price, currency];
}

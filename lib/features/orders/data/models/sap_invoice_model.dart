import 'package:json_annotation/json_annotation.dart';

part 'sap_invoice_model.g.dart';

@JsonSerializable()
class SapInvoiceModel {
  @JsonKey(name: 'DocEntry')
  final int docEntry;

  @JsonKey(name: 'DocNum')
  final int docNum;

  @JsonKey(name: 'CardCode')
  final String cardCode;

  @JsonKey(name: 'CardName')
  final String? cardName;

  @JsonKey(name: 'DocDate')
  final String docDate;

  @JsonKey(name: 'DocTotal')
  final double docTotal;

  @JsonKey(name: 'DocumentStatus')
  final String documentStatus;

  const SapInvoiceModel({
    required this.docEntry,
    required this.docNum,
    required this.cardCode,
    this.cardName,
    required this.docDate,
    required this.docTotal,
    required this.documentStatus,
  });

  factory SapInvoiceModel.fromJson(Map<String, dynamic> json) =>
      _$SapInvoiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$SapInvoiceModelToJson(this);
}

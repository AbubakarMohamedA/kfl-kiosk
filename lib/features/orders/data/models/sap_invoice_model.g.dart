// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sap_invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SapInvoiceModel _$SapInvoiceModelFromJson(Map<String, dynamic> json) =>
    SapInvoiceModel(
      docEntry: (json['DocEntry'] as num).toInt(),
      docNum: (json['DocNum'] as num).toInt(),
      cardCode: json['CardCode'] as String,
      cardName: json['CardName'] as String?,
      docDate: json['DocDate'] as String,
      docTotal: (json['DocTotal'] as num).toDouble(),
      documentStatus: json['DocumentStatus'] as String,
    );

Map<String, dynamic> _$SapInvoiceModelToJson(SapInvoiceModel instance) =>
    <String, dynamic>{
      'DocEntry': instance.docEntry,
      'DocNum': instance.docNum,
      'CardCode': instance.cardCode,
      'CardName': instance.cardName,
      'DocDate': instance.docDate,
      'DocTotal': instance.docTotal,
      'DocumentStatus': instance.documentStatus,
    };

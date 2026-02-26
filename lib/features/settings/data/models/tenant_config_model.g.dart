// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TenantConfigModel _$TenantConfigModelFromJson(Map<String, dynamic> json) =>
    TenantConfigModel(
      tenantId: json['tenantId'] as String,
      logoPath: json['logoPath'] as String?,
      primaryColor: (json['primaryColor'] as num?)?.toInt(),
      secondaryColor: (json['secondaryColor'] as num?)?.toInt(),
      backgroundPath: json['backgroundPath'] as String?,
      appName: json['appName'] as String?,
      welcomeMessage: json['welcomeMessage'] as String?,
    );

Map<String, dynamic> _$TenantConfigModelToJson(TenantConfigModel instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'logoPath': instance.logoPath,
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'backgroundPath': instance.backgroundPath,
      'appName': instance.appName,
      'welcomeMessage': instance.welcomeMessage,
    };

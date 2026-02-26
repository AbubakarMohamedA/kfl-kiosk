import 'package:json_annotation/json_annotation.dart';
import 'package:kfm_kiosk/features/settings/domain/entities/tenant_config.dart';

part 'tenant_config_model.g.dart';

@JsonSerializable()
class TenantConfigModel extends TenantConfig {
  const TenantConfigModel({
    required super.tenantId,
    super.logoPath,
    super.primaryColor,
    super.secondaryColor,
    super.backgroundPath,
    super.appName,
    super.welcomeMessage,
  });

  factory TenantConfigModel.fromJson(Map<String, dynamic> json) =>
      _$TenantConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$TenantConfigModelToJson(this);

  factory TenantConfigModel.fromEntity(TenantConfig config) {
    return TenantConfigModel(
      tenantId: config.tenantId,
      logoPath: config.logoPath,
      primaryColor: config.primaryColor,
      secondaryColor: config.secondaryColor,
      backgroundPath: config.backgroundPath,
      appName: config.appName,
      welcomeMessage: config.welcomeMessage,
    );
  }

  TenantConfig toEntity() {
    return TenantConfig(
      tenantId: tenantId,
      logoPath: logoPath,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      backgroundPath: backgroundPath,
      appName: appName,
      welcomeMessage: welcomeMessage,
    );
  }
}

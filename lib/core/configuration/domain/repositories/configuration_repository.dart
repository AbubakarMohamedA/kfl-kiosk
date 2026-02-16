import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';

abstract class ConfigurationRepository {
  Future<AppConfiguration> getConfiguration();
  Future<void> saveConfiguration(AppConfiguration configuration);
}

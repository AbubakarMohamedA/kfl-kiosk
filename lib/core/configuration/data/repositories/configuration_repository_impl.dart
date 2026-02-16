import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/configuration/data/datasources/local_configuration_datasource.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';

class ConfigurationRepositoryImpl implements ConfigurationRepository {
  final LocalConfigurationDataSource dataSource;

  ConfigurationRepositoryImpl(this.dataSource);

  @override
  Future<AppConfiguration> getConfiguration() async {
    return dataSource.getConfiguration();
  }

  @override
  Future<void> saveConfiguration(AppConfiguration configuration) async {
    await dataSource.saveConfiguration(configuration);
  }
}
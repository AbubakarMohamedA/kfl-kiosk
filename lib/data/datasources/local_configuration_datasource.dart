import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/core/configuration/app_configuration.dart';

class LocalConfigurationDataSource {
  static const _configKey = 'app_configuration';

  Future<AppConfiguration> getConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    
    if (configJson != null) {
      try {
        return AppConfiguration.fromJson(jsonDecode(configJson));
      } catch (e) {
        // Return default on error
      }
    }
    return AppConfiguration();
  }

  Future<void> saveConfiguration(AppConfiguration configuration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(configuration.toJson()));
  }
}
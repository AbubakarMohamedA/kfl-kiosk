import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalConfigurationDataSource {
  static const _configKey = 'app_configuration';
  static const _migrationDoneKey = 'config_persistence_migration_done';
  
  final AppDatabase _db;

  LocalConfigurationDataSource(this._db);

  Future<AppConfiguration> getConfiguration() async {
    // Check for migration
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool(_migrationDoneKey) ?? false;
    
    if (!migrationDone) {
      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        try {
          final config = AppConfiguration.fromJson(jsonDecode(configJson));
          await saveConfiguration(config);
          await prefs.setBool(_migrationDoneKey, true);
          return config;
        } catch (e) {}
      }
      await prefs.setBool(_migrationDoneKey, true);
    }

    final row = await (_db.select(_db.appConfig)..where((tbl) => tbl.key.equals(_configKey))).getSingleOrNull();
    
    if (row != null) {
      try {
        return AppConfiguration.fromJson(jsonDecode(row.value));
      } catch (e) {}
    }
    return AppConfiguration();
  }

  Future<void> saveConfiguration(AppConfiguration configuration) async {
    await _db.into(_db.appConfig).insertOnConflictUpdate(
      AppConfigCompanion(
        key: Value(_configKey),
        value: Value(jsonEncode(configuration.toJson())),
      ),
    );
  }
}
import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';

part 'app_config_dao.g.dart';

@DriftAccessor(tables: [AppConfig])
class AppConfigDao extends DatabaseAccessor<AppDatabase> with _$AppConfigDaoMixin {
  final AppDatabase db;

  AppConfigDao(this.db) : super(db);

  Future<String?> getValue(String key) async {
    final row = await (select(appConfig)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) async {
    await into(appConfig).insertOnConflictUpdate(
      AppConfigCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final val = await getValue(key);
    return int.tryParse(val ?? '') ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await setValue(key, value.toString());
  }
}

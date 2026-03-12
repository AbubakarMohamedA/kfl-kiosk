import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';

part 'tenant_config_dao.g.dart';

@DriftAccessor(tables: [TenantConfigs])
class TenantConfigDao extends DatabaseAccessor<AppDatabase> with _$TenantConfigDaoMixin {
  final AppDatabase db;

  TenantConfigDao(this.db) : super(db);

  Future<TenantConfig?> getConfig(String tenantId) {
    return (select(tenantConfigs)..where((t) => t.tenantId.equals(tenantId))).getSingleOrNull();
  }

  Stream<TenantConfig?> watchConfig(String tenantId) {
    return (select(tenantConfigs)..where((t) => t.tenantId.equals(tenantId))).watchSingleOrNull();
  }

  Future<void> saveConfig(TenantConfigsCompanion config) async {
    await into(tenantConfigs).insertOnConflictUpdate(config);
  }
}

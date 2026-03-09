import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart' as entity;

part 'tenants_dao.g.dart';

@DriftAccessor(tables: [Tenants])
class TenantsDao extends DatabaseAccessor<AppDatabase> with _$TenantsDaoMixin {
  TenantsDao(super.db);

  Future<List<entity.Tenant>> getAllTenants() async {
    final query = select(tenants);
    final result = await query.get();
    return result.map((row) => _mapToEntity(row)).toList();
  }

  Future<entity.Tenant?> getTenantById(String id) async {
    final query = select(tenants)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapToEntity(row);
  }

  Future<void> saveTenant(entity.Tenant tenant) async {
    await into(tenants).insertOnConflictUpdate(TenantsCompanion.insert(
      id: tenant.id,
      name: tenant.name,
      businessName: tenant.businessName,
      email: tenant.email,
      phone: tenant.phone,
      status: tenant.status,
      tierId: Value(tenant.tierId),
      createdDate: tenant.createdDate,
      lastLogin: Value(tenant.lastLogin),
      ordersCount: Value(tenant.ordersCount),
      revenue: Value(tenant.revenue),
      isMaintenanceMode: Value(tenant.isMaintenanceMode),
      enabledFeatures: jsonEncode(tenant.enabledFeatures),
      allowUpdate: Value(tenant.allowUpdate),
      immuneToBlocking: Value(tenant.immuneToBlocking),
    ));
  }

  Future<void> deleteTenant(String id) async {
    await (delete(tenants)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteAllTenants() async {
    await delete(tenants).go();
  }

  entity.Tenant _mapToEntity(Tenant row) {
    return entity.Tenant(
      id: row.id,
      name: row.name,
      businessName: row.businessName,
      email: row.email,
      phone: row.phone,
      status: row.status,
      tierId: row.tierId,
      createdDate: row.createdDate,
      lastLogin: row.lastLogin,
      ordersCount: row.ordersCount,
      revenue: row.revenue,
      isMaintenanceMode: row.isMaintenanceMode,
      enabledFeatures: List<String>.from(jsonDecode(row.enabledFeatures)),
      allowUpdate: row.allowUpdate,
      immuneToBlocking: row.immuneToBlocking,
    );
  }
}

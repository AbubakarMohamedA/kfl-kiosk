import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';
import 'package:sss/features/warehouse/domain/entities/warehouse.dart' as entity;

part 'warehouses_dao.g.dart';

@DriftAccessor(tables: [Warehouses])
class WarehousesDao extends DatabaseAccessor<AppDatabase> with _$WarehousesDaoMixin {
  WarehousesDao(super.db);

  // Insert or Update Warehouse
  Future<void> saveWarehouse(entity.Warehouse warehouse) async {
    await into(warehouses).insertOnConflictUpdate(Warehouse(
      id: warehouse.id,
      tenantId: warehouse.tenantId,
      branchId: warehouse.branchId,
      name: warehouse.name,
      categories: jsonEncode(warehouse.categories),
      loginUsername: warehouse.loginUsername,
      loginPassword: warehouse.loginPassword,
      isActive: warehouse.isActive,
    ));
  }
  
  // Get all warehouses for a branch
  Future<List<entity.Warehouse>> getWarehousesForBranch(String branchId) async {
    final query = select(warehouses)..where((tbl) => tbl.branchId.equals(branchId));
    final result = await query.get();
    
    return result.map((row) => entity.Warehouse(
      id: row.id,
      tenantId: row.tenantId ?? '',
      branchId: row.branchId,
      name: row.name,
      categories: List<String>.from(jsonDecode(row.categories)),
      loginUsername: row.loginUsername,
      loginPassword: row.loginPassword,
      isActive: row.isActive,
    )).toList();
  }

  // Get specific warehouse
  Future<entity.Warehouse?> getWarehouseById(String id) async {
    final query = select(warehouses)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    
    if (row == null) return null;
    
    return entity.Warehouse(
      id: row.id,
      tenantId: row.tenantId ?? '',
      branchId: row.branchId,
      name: row.name,
      categories: List<String>.from(jsonDecode(row.categories)),
      loginUsername: row.loginUsername,
      loginPassword: row.loginPassword,
      isActive: row.isActive,
    );
  }

  // Authenticate staff
  Future<entity.Warehouse?> authenticate(String username, String password) async {
    final query = select(warehouses)..where((tbl) => 
      tbl.loginUsername.equals(username) & 
      tbl.loginPassword.equals(password) &
      tbl.isActive.equals(true)
    );
    
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    
    return entity.Warehouse(
      id: row.id,
      tenantId: row.tenantId ?? '',
      branchId: row.branchId,
      name: row.name,
      categories: List<String>.from(jsonDecode(row.categories)),
      loginUsername: row.loginUsername,
      loginPassword: row.loginPassword,
      isActive: row.isActive,
    );
  }

  // Delete Warehouse
  Future<void> deleteWarehouse(String id) async {
    await (delete(warehouses)..where((tbl) => tbl.id.equals(id))).go();
  }
}

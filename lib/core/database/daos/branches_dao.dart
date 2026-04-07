import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';
import 'package:sss/features/auth/domain/entities/branch.dart';

part 'branches_dao.g.dart';

@DriftAccessor(tables: [Branches])
class BranchesDao extends DatabaseAccessor<AppDatabase> with _$BranchesDaoMixin {
  BranchesDao(super.db);

  // Get all branches for a specific tenant
  Future<List<Branch>> getBranchesForTenant(String tenantId) async {
    final query = select(branches)..where((tbl) => tbl.tenantId.equals(tenantId));
    final result = await query.get();
    
    return result.map((row) => Branch(
      id: row.id,
      tenantId: row.tenantId,
      name: row.name,
      location: row.location,
      contactPhone: row.contactPhone,
      managerName: row.managerName,
      loginUsername: row.loginUsername,
      loginPassword: row.loginPassword,
      isActive: row.isActive,
      sapServerIp: row.sapServerIp,
      sapCompanyDb: row.sapCompanyDb,
      sapUsername: row.sapUsername,
      sapPassword: row.sapPassword,
      // Default metrics for now
      totalOrders: 0,
      revenue: 0.0,
    )).toList();
  }

  // Save or Update Branch
  Future<void> saveBranch(Branch branch) async {
    await into(branches).insertOnConflictUpdate(BranchesCompanion(
      id: Value(branch.id),
      tenantId: Value(branch.tenantId),
      name: Value(branch.name),
      location: Value(branch.location),
      contactPhone: Value(branch.contactPhone),
      managerName: Value(branch.managerName),
      loginUsername: Value(branch.loginUsername),
      loginPassword: Value(branch.loginPassword),
      isActive: Value(branch.isActive),
      sapServerIp: Value(branch.sapServerIp),
      sapCompanyDb: Value(branch.sapCompanyDb),
      sapUsername: Value(branch.sapUsername),
      sapPassword: Value(branch.sapPassword),
    ));
  }

  // Delete Branch
  Future<void> deleteBranch(String id) async {
    await (delete(branches)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Get single branch by ID
  Future<Branch?> getBranchById(String id) async {
    final query = select(branches)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    
    if (row == null) return null;
    
    return Branch(
      id: row.id,
      tenantId: row.tenantId,
      name: row.name,
      location: row.location,
      contactPhone: row.contactPhone,
      managerName: row.managerName,
      loginUsername: row.loginUsername,
      loginPassword: row.loginPassword,
      isActive: row.isActive,
      sapServerIp: row.sapServerIp,
      sapCompanyDb: row.sapCompanyDb,
      sapUsername: row.sapUsername,
      sapPassword: row.sapPassword,
      totalOrders: 0, // Snapshot
      revenue: 0.0,
    );
  }
}

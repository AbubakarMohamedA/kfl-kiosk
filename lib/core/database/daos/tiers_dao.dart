import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tier.dart' as entity;

part 'tiers_dao.g.dart';

@DriftAccessor(tables: [Tiers])
class TiersDao extends DatabaseAccessor<AppDatabase> with _$TiersDaoMixin {
  TiersDao(super.db);

  Future<List<entity.Tier>> getAllTiers() async {
    final query = select(tiers);
    final result = await query.get();
    return result.map((row) => _mapToEntity(row)).toList();
  }

  Future<entity.Tier?> getTierById(String id) async {
    final query = select(tiers)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapToEntity(row);
  }

  Future<void> saveTier(entity.Tier tier) async {
    await into(tiers).insertOnConflictUpdate(TiersCompanion.insert(
      id: tier.id,
      name: tier.name,
      enabledFeatures: jsonEncode(tier.enabledFeatures),
      allowUpdates: Value(tier.allowUpdates),
      immuneToBlocking: Value(tier.immuneToBlocking),
      description: Value(tier.description),
    ));
  }

  Future<void> deleteTier(String id) async {
    await (delete(tiers)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> deleteAllTiers() async {
    await delete(tiers).go();
  }

  entity.Tier _mapToEntity(Tier row) {
    return entity.Tier(
      id: row.id,
      name: row.name,
      enabledFeatures: List<String>.from(jsonDecode(row.enabledFeatures)),
      allowUpdates: row.allowUpdates,
      immuneToBlocking: row.immuneToBlocking,
      description: row.description,
    );
  }
}

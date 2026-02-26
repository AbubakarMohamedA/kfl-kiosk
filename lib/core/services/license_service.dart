import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';

class LicenseService {
  final AppDatabase db;

  LicenseService(this.db);

  /// Check if the app is licensed
  Future<bool> isLicensed() async {
    final status = await (db.select(db.appConfig)
      ..where((tbl) => tbl.key.equals(AppConfigKeys.licenseStatus)))
      .getSingleOrNull();

    return status?.value == 'active';
  }
  
  /// Check if current license is expired
  Future<bool> isExpired() async {
     final expiryStr = await (db.select(db.appConfig)
      ..where((tbl) => tbl.key.equals('license_expiry')))
      .getSingleOrNull();
      
    if (expiryStr == null || expiryStr.value.isEmpty) return false;
    
    final expiry = DateTime.parse(expiryStr.value);
    return DateTime.now().isAfter(expiry);
  }

  /// Verify license key (Simulated Backend Validation)
  /// Key Format: KFL-{TenantIdBase64}-{ExpiryEpoch}
  Future<bool> verifyLicense(String key) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network
    
    // 1. Basic Format Check
    if (!key.startsWith('KFL-')) return false;
    
    final parts = key.split('-');
    if (parts.length != 3) return false;
    
    try {
      // 2. Decode Expiry & Tenant
      final tenantId = utf8.decode(base64.decode(parts[1]));
      final expiryEpoch = int.parse(utf8.decode(base64.decode(parts[2])));
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryEpoch);
      
      // 3. Check Expiration
      if (DateTime.now().isAfter(expiryDate)) {
        return false; // Key is already expired
      }

      // 4. Save License & Expiry & Tenant
      await saveLicense(key, expiryDate, tenantId);
      return true;
    } catch (e) {
      return false; // Parsing failed
    }
  }

  /// Generate a new license key (Admin Function)
  String generateLicense({required String tenantId, required DateTime expiresAt}) {
    final tenantEncoded = base64.encode(utf8.encode(tenantId));
    final expiryEncoded = base64.encode(utf8.encode(expiresAt.millisecondsSinceEpoch.toString()));
    
    return 'KFL-$tenantEncoded-$expiryEncoded';
  }

  /// Save license info to database
  Future<void> saveLicense(String key, DateTime expiryDate, String tenantId) async {
    await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
      key: const Value(AppConfigKeys.licenseKey),
      value: Value(key),
    ));
    
    await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
      key: const Value(AppConfigKeys.licenseStatus),
      value: const Value('active'),
    ));

    await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
      key: const Value(AppConfigKeys.lastVerified),
      value: Value(DateTime.now().toIso8601String()),
    ));
    
    await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
      key: const Value('license_expiry'),
      value: Value(expiryDate.toIso8601String()),
    ));
    
    await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
      key: const Value('tenant_id'),
      value: Value(tenantId),
    ));
  }
  
  /// Clear license (for debugging/reset)
  Future<void> clearLicense() async {
    await (db.delete(db.appConfig)..where((tbl) => tbl.key.isIn([
      AppConfigKeys.licenseKey, 
      AppConfigKeys.licenseStatus,
      AppConfigKeys.lastVerified,
      'license_expiry'
    ]))).go();
  }
}

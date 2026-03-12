import 'package:drift/drift.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sss/core/database/app_database.dart';

import '../../di/injection.dart';
import 'firebase_rest_service.dart';

class LicenseService {
  final AppDatabase db;

  LicenseService(this.db);
  
  FirebaseRestService get _restService => getIt<FirebaseRestService>();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

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

  /// Verify license key against Cloud (Firestore)
  Future<bool> verifyLicense(String key) async {
    if (Platform.isLinux) {
       try {
         final queryResults = await _restService.runQuery('licenses', [
           {
             'fieldFilter': {
               'field': {'fieldPath': 'key'},
               'op': 'EQUAL',
               'value': {'stringValue': key}
             }
           },
           {
             'fieldFilter': {
               'field': {'fieldPath': 'status'},
               'op': 'EQUAL',
               'value': {'stringValue': 'pending'}
             }
           }
         ]);

         if (queryResults.isEmpty) return false;

         final data = queryResults.first;
         final tenantId = data['tenantId'] as String;
         final expiresAt = data['expiresAt'] is DateTime 
             ? data['expiresAt'] 
             : DateTime.now().add(const Duration(days: 365));

         // 3. Save locally
         await saveLicense(key, expiresAt, tenantId);
         return true;
       } catch (e) {
         debugPrint('LicenseService (REST): Error verifying license: $e');
         return false;
       }
    }

    try {
      // 1. Query Firestore for this key
      final query = await _firestore
          .collection('licenses')
          .where('key', isEqualTo: key)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      final doc = query.docs.first;
      final data = doc.data();
      final tenantId = data['tenantId'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      // 2. Mark as active in cloud (Can't be reused)
      await doc.reference.update({
        'status': 'active',
        'activatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Save locally
      await saveLicense(key, expiresAt, tenantId);
      return true;
    } catch (e) {
      debugPrint('LicenseService: Error verifying license: $e');
      return false;
    }
  }

  /// Check Cloud for license updates or remote blocks
  Future<void> checkCloudLicenseStatus(String tenantId) async {
    if (Platform.isLinux) {
      try {
        final data = await _restService.getDocument('tenants/$tenantId');
        if (data != null) {
          final expiry = data['licenseExpiry'] as DateTime?;
          final status = data['licenseStatus'] as String?;

          if (expiry != null) {
            await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
              key: const Value('license_expiry'),
              value: Value(expiry.toIso8601String()),
            ));
          }

          if (status != null) {
            await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
              key: const Value(AppConfigKeys.licenseStatus),
              value: Value(status),
            ));
          }
        }
      } catch (e) {
        debugPrint('LicenseService (REST): Error checking cloud license: $e');
      }
      return;
    }

    try {
      final doc = await _firestore.collection('tenants').doc(tenantId).get();
      if (doc.exists) {
        final data = doc.data();
        final expiry = (data?['licenseExpiry'] as Timestamp?)?.toDate();
        final status = data?['licenseStatus'] as String?;

        if (expiry != null) {
          await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
            key: const Value('license_expiry'),
            value: Value(expiry.toIso8601String()),
          ));
        }

        if (status != null) {
          await db.into(db.appConfig).insertOnConflictUpdate(AppConfigCompanion(
            key: const Value(AppConfigKeys.licenseStatus),
            value: Value(status),
          ));
        }
      }
    } catch (e) {
      debugPrint('LicenseService: Error checking cloud license: $e');
    }
  }

  /// Generate a new unique license key
  String generateLicense() {
     const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O, 0, I, 1
     final random = DateTime.now().microsecondsSinceEpoch.toString();
     String key = 'KFL-';
     for (int i = 0; i < 12; i++) {
        key += chars[DateTime.now().microsecondsSinceEpoch % chars.length];
     }
     return key;
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

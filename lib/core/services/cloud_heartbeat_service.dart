import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kfm_kiosk/core/database/app_database.dart' hide Tier;
import 'package:kfm_kiosk/features/auth/domain/entities/tier.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/services/license_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';
import 'package:kfm_kiosk/core/services/local_server_service.dart';
import 'package:kfm_kiosk/main.dart'; // For globalNavigatorKey
import 'package:kfm_kiosk/features/auth/presentation/screens/login_screen.dart';

class CloudHeartbeatService {
  final ConfigurationRepository _configRepo;
  final TenantService _tenantService;
  final LicenseService _licenseService;
  final AuthRepository _authRepository;
  final LocalServerService _localServerService;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CloudHeartbeatService(
    this._configRepo, 
    this._tenantService, 
    this._licenseService,
    this._authRepository,
    this._localServerService,
  );

  /// Performs a remote status check for the current tenant using Firebase Firestore.
  /// Updates local storage and locks the app if the tenant is inactive.
  Future<void> checkTenantStatus() async {
    if (Platform.isLinux) return;
    final config = await _configRepo.getConfiguration();
    final tenantId = config.tenantId;

    // Sync Global Tiers (Feature Gating Rules)
    try {
      final tiersSnapshot = await _firestore.collection('tiers').get();
      for (final doc in tiersSnapshot.docs) {
        final data = doc.data();
        final tierId = doc.id;
        final tier = Tier(
          id: tierId,
          name: data['name'] as String? ?? tierId,
          enabledFeatures: (data['enabledFeatures'] as List<dynamic>?)?.cast<String>() ?? [],
          allowUpdates: data['allowUpdates'] as bool? ?? true,
          immuneToBlocking: data['immuneToBlocking'] as bool? ?? false,
          description: data['description'] as String? ?? '',
        );
        await _tenantService.updateTier(tier as Tier);
      }
    } catch (e) {
      debugPrint('CloudHeartbeatService: Error syncing tiers: $e');
    }

    try {
      // Fetch status from Firestore 'tenants' collection
      final doc = await _firestore.collection('tenants').doc(tenantId).get();

        if (doc.exists) {
          final data = doc.data()!;
          final status = data['status'] as String? ?? 'Active';
          final tierId = data['tierId'] as String?;
          final isMaintenanceMode = data['isMaintenanceMode'] as bool? ?? false;
          final enabledFeatures = (data['enabledFeatures'] as List<dynamic>?)?.cast<String>() ?? [];
          final allowUpdate = data['allowUpdate'] as bool?;
          final immuneToBlocking = data['immuneToBlocking'] as bool?;
          
          // License Data
          final licenseExpiry = (data['licenseExpiry'] as Timestamp?)?.toDate();

          // Update local memory and DB maintenance state
          _tenantService.setTenantMaintenanceMode(tenantId!, isMaintenanceMode);
          
          // Check for license expiration (Skip for 'alone' tier as requested)
          if (tierId != 'alone') {
             if (licenseExpiry != null && DateTime.now().isAfter(licenseExpiry)) {
                // Fetch and update local license status in DB
                await _licenseService.checkCloudLicenseStatus(tenantId); 
                debugPrint('Firebase Heartbeat: License EXPIRED for $tenantId. System Lock Imminent.');
             }
          }

          // Fetch current local tenant state
          final tenants = _tenantService.getTenants();
          final index = tenants.indexWhere((t) => t.id == tenantId);
          if (index == -1) {
            debugPrint('Firebase Heartbeat: Tenant $tenantId not registered locally yet.');
            return;
          }
          final currentTenant = tenants[index];
        
        // Check if any critical field changed
        final hasChanged = currentTenant.status != status || 
                           currentTenant.tierId != tierId ||
                           currentTenant.isMaintenanceMode != isMaintenanceMode ||
                           !listEquals(currentTenant.enabledFeatures, enabledFeatures) ||
                           currentTenant.allowUpdate != allowUpdate ||
                           currentTenant.immuneToBlocking != immuneToBlocking;

        if (hasChanged) {
           final updatedTenant = currentTenant.copyWith(
             status: status,
             tierId: tierId ?? currentTenant.tierId,
             isMaintenanceMode: isMaintenanceMode,
             enabledFeatures: enabledFeatures,
             allowUpdate: allowUpdate,
             immuneToBlocking: immuneToBlocking,
           );
           await _tenantService.updateTenant(updatedTenant);
           
           // If tier changed, update global config
           if (tierId != null && tierId != config.tierId) {
             await _configRepo.saveConfiguration(config.copyWith(tierId: tierId));
           }

           debugPrint('Firebase Heartbeat: Synced $tenantId with all cloud settings');
        }

        // Save last successful heartbeat time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_cloud_heartbeat', DateTime.now().millisecondsSinceEpoch);
      } else {
        debugPrint('Firebase Heartbeat: Tenant $tenantId not found in cloud.');
      }
    } catch (e) {
      debugPrint('Firebase Heartbeat Error: $e');
      await _checkGracePeriod();
    }
  }

  /// Verification logic for offline scenarios.
  /// If internet is down, allow access for 7 days before blocking.
  Future<void> _checkGracePeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final lastHeartbeat = prefs.getInt('last_cloud_heartbeat') ?? 0;
    
    if (lastHeartbeat == 0) return; // Never synced, rely on local state

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastHeartbeat);
    final diff = DateTime.now().difference(lastDate).inDays;

    if (diff > 7) {
      debugPrint('Firebase Heartbeat: Offline Grace Period Expired ($diff days)');
      
      // Logout the user
      await _authRepository.logout();
      _localServerService.setActiveTenantId('');

      // Navigate to LoginScreen using global navigator key
      if (globalNavigatorKey.currentContext != null) {
        Navigator.of(globalNavigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

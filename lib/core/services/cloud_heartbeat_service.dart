import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sss/core/database/app_database.dart' hide Tier;
import 'package:sss/features/auth/domain/entities/tier.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:sss/core/services/license_service.dart';
import 'package:sss/features/auth/domain/repositories/auth_repository.dart';
import 'package:sss/core/services/local_server_service.dart' hide TerminalInfo;
import 'package:sss/main.dart'; // For globalNavigatorKey
import 'package:sss/features/auth/presentation/screens/login_screen.dart';
import 'package:sss/core/config/app_role.dart';
import 'package:sss/core/models/terminal_info.dart';
import 'package:sss/core/services/platform_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class CloudHeartbeatService {
  final ConfigurationRepository _configRepo;
  final TenantService _tenantService;
  final LicenseService _licenseService;
  final AuthRepository _authRepository;
  final LocalServerService _localServerService;
  final RoleConfig _roleConfig;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CloudHeartbeatService(
    this._configRepo, 
    this._tenantService, 
    this._licenseService,
    this._authRepository,
    this._localServerService,
    this._roleConfig,
  );
  
  static Timer? _heartbeatTimer;

  /// Starts the periodic heartbeat (every 10 minutes)
  void start() {
    stop(); // Avoid duplicates
    checkTenantStatus(); // Immediate Check
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 10), (_) => checkTenantStatus());
    debugPrint('CloudHeartbeatService: Periodic monitoring started (10m interval)');
  }

  /// Stops the periodic heartbeat
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    debugPrint('CloudHeartbeatService: Periodic monitoring stopped');
  }

  /// Performs a remote status check for the current tenant using Firebase Firestore (or REST on Linux).
  /// Updates local storage and locks the app if the tenant is inactive.
  Future<void> checkTenantStatus() async {
    final config = await _configRepo.getConfiguration();
    final tenantId = config.tenantId;
    if (tenantId == null) return;

    // Sync Global Tiers & Config
    await _tenantService.pullTiersFromCloud();
    await _tenantService.syncGlobalConfig();

    // Report Terminal Status
    await _reportTerminalStatus(tenantId);

    try {
      // Fetch status from Cloud (Handles Firestore/REST split internally)
      await _tenantService.syncTenantWithCloud(tenantId);
      
      // Fetch specific tenant status after sync for local checks
      final tenant = _tenantService.getTenants().firstWhere((t) => t.id == tenantId);
      final tierId = tenant.status; // status? No, tierId.
      
      // Check for license expiration (Skip for 'alone' tier)
      if (tenant.tierId != 'alone') {
         // License data is often synced via the tenant doc or a separate collection.
         // For now, we rely on the LicenseService to check cloud status.
         await _licenseService.checkCloudLicenseStatus(tenantId); 
      }

      // Save last successful heartbeat time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_cloud_heartbeat', DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      debugPrint('CloudHeartbeatService Error: $e');
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

  /// Reports current terminal info to the cloud
  Future<void> _reportTerminalStatus(String tenantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Get or create unique terminal ID
      String? terminalId = prefs.getString('terminal_id');
      if (terminalId == null) {
        terminalId = const Uuid().v4();
        await prefs.setString('terminal_id', terminalId);
      }

      // 2. Gather information
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = PlatformService.platformName;
      final flavor = _roleConfig.role.name;
      final version = packageInfo.version;

      // 3. Create TerminalInfo
      final info = TerminalInfo(
        id: terminalId,
        tenantId: tenantId,
        flavor: flavor,
        platform: platform,
        version: version,
        lastSeen: DateTime.now(),
      );

      // 4. Report to service
      await _tenantService.reportTerminalStatus(info);
    } catch (e) {
      debugPrint('CloudHeartbeatService: Error reporting terminal status: $e');
    }
  }
}

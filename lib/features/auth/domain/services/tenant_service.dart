import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tier.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart';
import 'package:kfm_kiosk/core/database/daos/tenants_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tiers_dao.dart';
import 'package:kfm_kiosk/core/database/daos/branches_dao.dart';

import 'package:kfm_kiosk/features/warehouse/domain/entities/warehouse.dart';
import 'package:kfm_kiosk/core/config/app_role.dart';

import 'package:kfm_kiosk/core/models/update_info.dart';

class TenantService {
  // Singleton pattern for simple state management in this phase
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  TenantsDao? _tenantsDao;
  TiersDao? _tiersDao;
  BranchesDao? _branchesDao;

  void setTenantsDao(TenantsDao dao) => _tenantsDao = dao;
  void setTiersDao(TiersDao dao) => _tiersDao = dao;
  void setBranchesDao(BranchesDao dao) => _branchesDao = dao;

  final List<Tier> _cacheTiers = [];
  final List<Tenant> _cacheTenants = [];

  Future<void> initialize() async {
    if (_tenantsDao == null || _tiersDao == null) return;

    // Clear caches to prevent duplicates on multiple initializations
    _cacheTiers.clear();
    _cacheTenants.clear();

    // Load Tiers
    final dbTiers = await _tiersDao!.getAllTiers();
    if (dbTiers.isEmpty) {
      // Seed default tiers
      final defaults = [
        const Tier(
          id: 'standard',
          name: 'Standard',
          enabledFeatures: ['orders', 'history', 'products'],
          description: 'Basic access for small businesses',
        ),
        const Tier(
          id: 'premium',
          name: 'Premium',
          enabledFeatures: ['orders', 'history', 'insights', 'warehouse', 'products'],
          description: 'Full access for enterprise clients',
        ),
        const Tier(
          id: 'alone',
          name: 'Alone',
          enabledFeatures: ['orders', 'history', 'products'],
          allowUpdates: false,
          immuneToBlocking: true,
          description: 'Offline-like mode: No updates, immune to blocking',
        ),
        const Tier(
          id: 'enterprise',
          name: 'Enterprise',
          enabledFeatures: ['orders', 'history', 'insights', 'warehouse', 'branches', 'products'],
          description: 'Multi-branch management with dedicated dashboards',
        ),
      ];
      for (final t in defaults) {
        await _tiersDao!.saveTier(t);
      }
      _cacheTiers.addAll(defaults);
    } else {
      _cacheTiers.addAll(dbTiers);
      
      // Migration: Ensure 'products' feature is added to standard/premium/enterprise tiers if missing
      // This handles the case where DB was seeded before 'products' feature was added
      bool needsMigration = false;
      for (var i = 0; i < _cacheTiers.length; i++) {
        final tier = _cacheTiers[i];
        if (['standard', 'premium', 'enterprise', 'alone'].contains(tier.id)) {
          if (!tier.enabledFeatures.contains('products')) {
            final updatedFeatures = List<String>.from(tier.enabledFeatures)..add('products');
            final updatedTier = tier.copyWith(enabledFeatures: updatedFeatures);
            _cacheTiers[i] = updatedTier;
            await _tiersDao!.saveTier(updatedTier); // Persist update
            needsMigration = true;
          }
        }
      }
      if (needsMigration) {
        debugPrint('TenantService: Migrated tiers to include products feature');
      }
    }

    // Load Tenants
    final dbTenants = await _tenantsDao!.getAllTenants();
    if (dbTenants.isEmpty) {
      // Seed Super Admin
      final admin = Tenant(
        id: 'SUPER_ADMIN',
        name: 'System Administrator',
        businessName: 'SSS Kiosk System',
        email: 'admin@sss.com',
        phone: '+254000000000',
        status: 'Active',
        tierId: 'premium',
        createdDate: DateTime(2023, 1, 1),
        lastLogin: DateTime.now(),
        ordersCount: 0,
        revenue: 0.0,
        isMaintenanceMode: false,
        enabledFeatures: ['orders', 'history', 'insights', 'warehouse', 'products'],
      );
      await _tenantsDao!.saveTenant(admin);
      _cacheTenants.add(admin);
    } else {
      _cacheTenants.addAll(dbTenants);
      
      // Migration: Ensure existing tenants (especially admin) have 'products'
      for (var i = 0; i < _cacheTenants.length; i++) {
        final tenant = _cacheTenants[i];
        // For Super Admin, ensure they have it
        if (tenant.id == 'SUPER_ADMIN' && !tenant.enabledFeatures.contains('products')) {
           final updatedFeatures = List<String>.from(tenant.enabledFeatures)..add('products');
           final updatedTenant = tenant.copyWith(enabledFeatures: updatedFeatures);
           _cacheTenants[i] = updatedTenant;
           await _tenantsDao!.saveTenant(updatedTenant);
        }
      }
    }
  }

  List<Tenant> getTenants() => List.unmodifiable(_cacheTenants);

  Future<void> addTenant(Tenant tenant) async {
    if (_tenantsDao != null) {
      await _tenantsDao!.saveTenant(tenant);
      _cacheTenants.add(tenant);
      await syncTenantToCloud(tenant);
    }
  }

  Future<void> updateTenant(Tenant updatedTenant) async {
    if (_tenantsDao != null) {
      await _tenantsDao!.saveTenant(updatedTenant);
      final index = _cacheTenants.indexWhere((t) => t.id == updatedTenant.id);
      if (index != -1) {
        _cacheTenants[index] = updatedTenant;
      }
      await syncTenantToCloud(updatedTenant);
    }
  }

  Future<void> syncTenantToCloud(Tenant tenant) async {
    if (Platform.isLinux) return;
    try {
      await _firestore.collection('tenants').doc(tenant.id).set({
        'name': tenant.name,
        'businessName': tenant.businessName,
        'email': tenant.email,
        'phone': tenant.phone,
        'status': tenant.status,
        'tierId': tenant.tierId,
        'isMaintenanceMode': tenant.isMaintenanceMode,
        'enabledFeatures': tenant.enabledFeatures,
        'allowUpdate': tenant.allowUpdate,
        'immuneToBlocking': tenant.immuneToBlocking,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('TenantService: Synced tenant ${tenant.id} to cloud');
    } catch (e) {
      debugPrint('TenantService: Error syncing tenant ${tenant.id} to cloud: $e');
    }
  }

  Future<void> deleteTenant(String id) async {
    if (_tenantsDao != null) {
      await _tenantsDao!.deleteTenant(id);
      _cacheTenants.removeWhere((t) => t.id == id);
    }
  }

  // Tier Management
  List<Tier> getTiers() => List.unmodifiable(_cacheTiers);

  Tier? getTierById(String id) {
    try {
      return _cacheTiers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
  Future<void> addTier(Tier tier) async {
    if (_tiersDao != null && !_cacheTiers.any((t) => t.id == tier.id)) {
      await _tiersDao!.saveTier(tier);
      _cacheTiers.add(tier);
      await syncTierToCloud(tier);
    }
  }

  Future<void> updateTier(Tier tier) async {
    if (_tiersDao != null) {
      await _tiersDao!.saveTier(tier);
      final index = _cacheTiers.indexWhere((t) => t.id == tier.id);
      if (index != -1) {
        _cacheTiers[index] = tier;
      }
      await syncTierToCloud(tier);
    }
  }

  Future<void> deleteTier(String id) async {
    if (_tiersDao != null) {
      await _tiersDao!.deleteTier(id);
      _cacheTiers.removeWhere((t) => t.id == id);
      if (!Platform.isLinux) {
        try {
          await _firestore.collection('tiers').doc(id).delete();
        } catch (e) {
          debugPrint('TenantService: Error deleting tier $id from cloud: $e');
        }
      }
    }
  }

  Future<void> syncTierToCloud(Tier tier) async {
    if (Platform.isLinux) return;
    try {
      await _firestore.collection('tiers').doc(tier.id).set({
        'name': tier.name,
        'enabledFeatures': tier.enabledFeatures,
        'allowUpdates': tier.allowUpdates,
        'immuneToBlocking': tier.immuneToBlocking,
        'description': tier.description,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('TenantService: Synced tier ${tier.id} to cloud');
    } catch (e) {
      debugPrint('TenantService: Error syncing tier ${tier.id} to cloud: $e');
    }
  }

  /// Pull all tiers from Firestore and merge into local DB
  Future<void> pullTiersFromCloud() async {
    if (Platform.isLinux) return;
    try {
      final snapshot = await _firestore.collection('tiers').get();
      
      // Full Refresh: Clear local DB table first
      if (_tiersDao != null) {
        await _tiersDao!.deleteAllTiers();
      }
      
      _cacheTiers.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tier = Tier(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          enabledFeatures: List<String>.from(data['enabledFeatures'] ?? []),
          allowUpdates: data['allowUpdates'] ?? true,
          immuneToBlocking: data['immuneToBlocking'] ?? false,
        );
        if (_tiersDao != null) {
          await _tiersDao!.saveTier(tier);
        }
        _cacheTiers.add(tier);
      }
      debugPrint('TenantService: Full Sync: Pulled ${snapshot.docs.length} tiers from cloud');
    } catch (e) {
      debugPrint('TenantService: Error pulling tiers from cloud: $e');
      rethrow;
    }
  }

  /// Pull all tenants from Firestore and merge into local DB
  Future<void> pullTenantsFromCloud() async {
    if (Platform.isLinux) return;
    try {
      final snapshot = await _firestore.collection('tenants').get();
      
      // Full Refresh: Clear local DB table first
      if (_tenantsDao != null) {
        await _tenantsDao!.deleteAllTenants();
      }
      
      _cacheTenants.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tenant = Tenant(
          id: doc.id,
          name: data['name'] ?? '',
          businessName: data['businessName'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          status: data['status'] ?? 'Active',
          tierId: data['tierId'] ?? 'standard',
          createdDate: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          lastLogin: data['updatedAt'] != null 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : null,
          ordersCount: data['ordersCount'] ?? 0,
          revenue: (data['revenue'] ?? 0.0).toDouble(),
          isMaintenanceMode: data['isMaintenanceMode'] ?? false,
          enabledFeatures: List<String>.from(data['enabledFeatures'] ?? []),
          allowUpdate: data['allowUpdate'],
          immuneToBlocking: data['immuneToBlocking'],
        );
        if (_tenantsDao != null) {
          await _tenantsDao!.saveTenant(tenant);
        }
        _cacheTenants.add(tenant);
      }
      debugPrint('TenantService: Full Sync: Pulled ${snapshot.docs.length} tenants from cloud');
    } catch (e) {
      debugPrint('TenantService: Error pulling tenants from cloud: $e');
      rethrow;
    }
  }

  Map<String, dynamic> getStats() {
    final totalRevenue = _cacheTenants.fold<double>(0, (sum, t) => sum + t.revenue);
    final totalOrders = _cacheTenants.fold<int>(0, (sum, t) => sum + t.ordersCount);
    final activeTenants = _cacheTenants.where((t) => t.status == 'Active').length;
    
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'activeTenants': activeTenants,
      'avgRevenue': _cacheTenants.isEmpty ? 0.0 : totalRevenue / _cacheTenants.length,
    };
  }

  // Feature Gating Logic
  bool canAccessFeature(String tenantId, String feature) {
    try {
      final tenant = _cacheTenants.firstWhere((t) => t.id == tenantId);
      
      // Check specific enabled features on tenant level first
      if (tenant.enabledFeatures.contains(feature)) {
        return true;
      }

      // Check tenant tier
      final tier = getTierById(tenant.tierId);
      if (tier != null && tier.enabledFeatures.contains(feature)) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Maintenance Mode
  bool _isMaintenanceMode = false;
  
  // Module-specific maintenance
  final Map<String, bool> _moduleMaintenance = {
    'orders': false,
    'history': false,
    'insights': false,
    'warehouse': false,
    'settings': false,
    'enterprise_dashboard': false,
    'products': false,
  };
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get isMaintenanceMode => _isMaintenanceMode;

  void setTenantMaintenanceMode(String tenantId, bool enabled) async {
     final index = _cacheTenants.indexWhere((t) => t.id == tenantId);
     if (index != -1) {
       final updated = _cacheTenants[index].copyWith(isMaintenanceMode: enabled);
       _cacheTenants[index] = updated;
       if (_tenantsDao != null) {
         await _tenantsDao!.saveTenant(updated);
       }
     }
  }

  void setMaintenanceMode(bool enabled) async {
    _isMaintenanceMode = enabled;
    if (Platform.isLinux) return;
    try {
      await _firestore.collection('system_config').doc('global').set({
        'isMaintenanceMode': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('TenantService: Error syncing maintenance mode: $e');
    }
  }
  
  void setModuleMaintenance(String module, bool enabled) async {
    if (_moduleMaintenance.containsKey(module)) {
      _moduleMaintenance[module] = enabled;
      if (Platform.isLinux) return;
      try {
        await _firestore.collection('system_config').doc('modules').set({
          module: enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('TenantService: Error syncing module maintenance ($module): $e');
      }
    }
  }
  
  bool isModuleUnderMaintenance(String module) {
    return _moduleMaintenance[module] ?? false;
  }

  /// Initial fetch for global settings from cloud
  Future<void> syncGlobalConfig() async {
    if (Platform.isLinux) return;
    try {
      final globalDoc = await _firestore.collection('system_config').doc('global').get();
      if (globalDoc.exists) {
        _isMaintenanceMode = globalDoc.data()?['isMaintenanceMode'] as bool? ?? false;
      }

      final modulesDoc = await _firestore.collection('system_config').doc('modules').get();
      if (modulesDoc.exists) {
        final data = modulesDoc.data();
        if (data != null) {
          data.forEach((key, value) {
            if (_moduleMaintenance.containsKey(key) && value is bool) {
              _moduleMaintenance[key] = value;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('TenantService: Error fetching global config: $e');
    }
  }

  /// Push update manifest to Firestore for real-time update management
  Future<void> pushUpdateManifest(UpdateInfo updateInfo) async {
    if (Platform.isLinux) return;
    try {
      await _firestore.collection('system_config').doc('updates').set({
        ...updateInfo.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('TenantService: Pushed update manifest to cloud');
    } catch (e) {
      debugPrint('TenantService: Error pushing update manifest: $e');
      rethrow;
    }
  }

  /// Get latest update manifest from Firestore
  Future<UpdateInfo?> getLatestUpdateManifest() async {
    if (Platform.isLinux) return null;
    try {
      final doc = await _firestore.collection('system_config').doc('updates').get();
      if (doc.exists && doc.data() != null) {
        return UpdateInfo.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('TenantService: Error fetching update manifest: $e');
      return null;
    }
  }

  /// Check if a tenant has immunity to blocking
  bool isTenantImmune(String tenantId, {String? fallbackTierId}) {
    try {
      // Try to find tenant in cache
      try {
        final tenant = _cacheTenants.firstWhere((t) => t.id == tenantId);
        
        // 1. Tenant Override
        if (tenant.immuneToBlocking != null) {
          return tenant.immuneToBlocking!;
        }

        // 2. Fallback to Tier
        final tier = getTierById(tenant.tierId);
        return tier?.immuneToBlocking ?? false;
      } catch (e) {
        // Tenant not found in cache
        if (fallbackTierId != null) {
          final tier = getTierById(fallbackTierId);
          return tier?.immuneToBlocking ?? false;
        }
        rethrow;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if a tenant can receive updates
  bool isTenantAllowedUpdates(String tenantId) {
    try {
      final tenant = _cacheTenants.firstWhere((t) => t.id == tenantId);
      
      // 1. Tenant Override
      if (tenant.allowUpdate != null) {
        return tenant.allowUpdate!;
      }

      // 2. Fallback to Tier
      final tier = getTierById(tenant.tierId);
      return tier?.allowUpdates ?? true; // Default true if not specified
    } catch (e) {
      return true; // Default to allow updates if check fails
    }
  }

  /// Check if a user/tenant can access the system
  /// [tenantId] - The ID of the tenant trying to access
  /// [isSuperAdmin] - Whether the user is a super admin (bypasses maintenance)
  /// [fallbackTierId] - Optional tier ID to use if tenant is not found in memory
  /// Returns [true] if access is allowed, [false] otherwise.
  bool canAccessSystem(String tenantId, {bool isSuperAdmin = false, String? fallbackTierId}) {
    // 0. Super Admin always has access
    if (isSuperAdmin) return true;

    try {
      // Check immunity
      bool isImmune = isTenantImmune(tenantId, fallbackTierId: fallbackTierId);

      // 1. Global Maintenance Mode Check
      if (_isMaintenanceMode && !isImmune) {
        return false; 
      }
      
      // Try to get tenant for status check
      try {
        final tenant = _cacheTenants.firstWhere((t) => t.id == tenantId);
        
        // 2. Tenant Specific Maintenance Check (Overrides Global if immune? No, distinct)
        // If tenant is manually set to maintenance, they should be blocked unless immune?
        // Usually, manual tenant maintenance blocks THAT tenant regardless of global state.
        // Immunity usually applies to GLOBAL blocks.
        if (tenant.isMaintenanceMode && !isImmune) return false; 
        
        // 3. Tenant Status Check
        if (tenant.status != 'Active' && !isImmune) {
          return false;
        }
      } catch (_) {
        // If tenant not found, we can't check status/maintenance mode of tenant
        // But if global maintenance is ON and they are NOT immune, we already returned false above.
        // If global maintenance is OFF, or they ARE immune, we continue.
      }

      return true;
    } catch (e) {
      // Default allow if completely failed
      return true; 
    }
  }

  bool isTenantEnabled(String tenantId) {
     try {
       final tenant = _cacheTenants.firstWhere((t) => t.id == tenantId);
       final tier = getTierById(tenant.tierId);
       
       if (tier?.immuneToBlocking == true) return true;

       return tenant.status == 'Active';
     } catch (e) {
       return true; 
     }
  }

  // Authentication Methods
  Tenant? login(String email, String password) {
    try {
      // Password is treated as Tenant ID for clients
      // Super Admin uses specific ID
      final tenant = _cacheTenants.firstWhere(
        (t) => t.email.toLowerCase() == email.toLowerCase() && t.id == password,
      );
      return tenant;
    } catch (e) {
      return null;
    }
  }

  bool isSuperAdmin(String tenantId) {
    return tenantId == 'SUPER_ADMIN';
  }

  void completeLogin(String tenantId) async {
    final index = _cacheTenants.indexWhere((t) => t.id == tenantId);
    if (index != -1) {
      final updated = _cacheTenants[index].copyWith(lastLogin: DateTime.now());
      _cacheTenants[index] = updated;
      if (_tenantsDao != null) {
        await _tenantsDao!.saveTenant(updated);
      }
    }
  }

  bool isFirstLogin(String tenantId) {
    try {
      final tenant = _cacheTenants.firstWhere((t) => t.id == tenantId);
      return tenant.lastLogin == null;
    } catch (e) {
      return false;
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _cacheTiers.clear();
    _cacheTiers.addAll([
      const Tier(
        id: 'standard',
        name: 'Standard',
        enabledFeatures: ['orders', 'history'],
        description: 'Basic access for small businesses',
      ),
      const Tier(
        id: 'premium',
        name: 'Premium',
        enabledFeatures: ['orders', 'history', 'insights', 'warehouse'],
        description: 'Full access for enterprise clients',
      ),
      const Tier(
        id: 'alone',
        name: 'Alone',
        enabledFeatures: ['orders', 'history'],
        allowUpdates: false,
        immuneToBlocking: true,
        description: 'Offline-like mode: No updates, immune to blocking',
      ),
      const Tier(
        id: 'enterprise',
        name: 'Enterprise',
        enabledFeatures: ['orders', 'history', 'insights', 'warehouse', 'branches'],
        description: 'Multi-branch management with dedicated dashboards',
      ),
    ]);
    
    _cacheTenants.clear();
    _cacheTenants.add(
      Tenant(
        id: 'SUPER_ADMIN',
        name: 'System Administrator',
        businessName: 'SSS Kiosk System',
        email: 'admin@sss.com',
        phone: '+254000000000',
        status: 'Active',
        tierId: 'premium',
        createdDate: DateTime(2023, 1, 1),
        lastLogin: DateTime.now(),
        ordersCount: 0,
        revenue: 0.0,
        isMaintenanceMode: false,
        enabledFeatures: ['orders', 'history', 'insights', 'warehouse'],
      ),
    );
  }
  // Branch Management

  Future<List<Branch>> getBranchesForTenant(String tenantId) async {
    if (_branchesDao != null) {
      return await _branchesDao!.getBranchesForTenant(tenantId);
    }
    return [];
  }
  
  Future<void> updateBranch(Branch branch) async {
    // Save handles update on conflict
    if (_branchesDao != null) {
      await _branchesDao!.saveBranch(branch);
      await _syncBranchToCloud(branch);
    }
  }

  Future<void> addBranch(Branch branch) async {
    if (_branchesDao != null) {
      await _branchesDao!.saveBranch(branch);
      await _syncBranchToCloud(branch);
    }
  }

  Future<void> _syncBranchToCloud(Branch branch) async {
    if (Platform.isLinux) return;
    try {
      await _firestore
          .collection('tenants')
          .doc(branch.tenantId)
          .collection('branches')
          .doc(branch.id)
          .set({
        'name': branch.name,
        'location': branch.location,
        'contactPhone': branch.contactPhone,
        'managerName': branch.managerName,
        'loginUsername': branch.loginUsername,
        'loginPassword': branch.loginPassword,
        'isActive': branch.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('TenantService: Synced branch ${branch.id} to cloud');
    } catch (e) {
      debugPrint('TenantService: Error syncing branch ${branch.id}: $e');
    }
  }

  Future<void> syncWarehouseToCloud(Warehouse warehouse) async {
    if (Platform.isLinux) return;
    try {
      await _firestore
          .collection('tenants')
          .doc(warehouse.tenantId)
          .collection('branches')
          .doc(warehouse.branchId)
          .collection('warehouses')
          .doc(warehouse.id)
          .set({
        'name': warehouse.name,
        'categories': warehouse.categories,
        'loginUsername': warehouse.loginUsername,
        'loginPassword': warehouse.loginPassword,
        'isActive': warehouse.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('TenantService: Synced warehouse ${warehouse.id} to cloud');
    } catch (e) {
      debugPrint('TenantService: Error syncing warehouse ${warehouse.id}: $e');
    }
  }

  /// Unified Cloud Login
  Future<Map<String, dynamic>?> cloudLogin(
      String identifier, String password, AppRole role) async {
    if (Platform.isLinux) return null;

    try {
      // 1. Primary Tenant/SuperAdmin Login Check (Universal)
      // This allows the Business Owner to log into any app (Kiosk, Staff, Dashboard)
      final tenantDoc = await _firestore.collection('tenants').doc(password).get();
      if (tenantDoc.exists) {
        final data = tenantDoc.data()!;
        if (data['email'].toString().toLowerCase() == identifier.toLowerCase()) {
           return {'type': 'tenant', 'data': data, 'id': password};
        }
      }

      // 2. Branch Manager / Staff Login (Role Restricted)
      if (role == AppRole.staff || role == AppRole.manager) {
        final tenantsSnapshot = await _firestore.collection('tenants').get();
        for (final tDoc in tenantsSnapshot.docs) {
          final branchesSnapshot = await tDoc.reference.collection('branches')
              .where('loginUsername', isEqualTo: identifier)
              .where('loginPassword', isEqualTo: password)
              .get();
              
          if (branchesSnapshot.docs.isNotEmpty) {
             final bDoc = branchesSnapshot.docs.first;
             return {
               'type': 'branch', 
               'data': bDoc.data(), 
               'id': bDoc.id, 
               'tenantId': tDoc.id, 
               'tenantData': tDoc.data()
             };
          }
        }
      }

      // 3. Warehouse Staff Login
      if (role == AppRole.warehouse) {
        final tenantsSnapshot = await _firestore.collection('tenants').get();
        for (final tDoc in tenantsSnapshot.docs) {
          final branchesSnapshot = await tDoc.reference.collection('branches').get();
          for (final bDoc in branchesSnapshot.docs) {
             final whSnapshot = await bDoc.reference.collection('warehouses')
                 .where('loginUsername', isEqualTo: identifier)
                 .where('loginPassword', isEqualTo: password)
                 .get();
             if (whSnapshot.docs.isNotEmpty) {
                final whDoc = whSnapshot.docs.first;
                return {
                  'type': 'warehouse', 
                  'data': whDoc.data(), 
                  'id': whDoc.id, 
                  'tenantId': tDoc.id, 
                  'tenantData': tDoc.data(),
                  'branchId': bDoc.id,
                  'branchData': bDoc.data()
                };
             }
          }
        }
      }
    } catch (e) {
      debugPrint('TenantService: Cloud login error: $e');
    }
    return null;
  }

  Future<void> deleteBranch(String branchId) async {
    if (_branchesDao != null) {
      await _branchesDao!.deleteBranch(branchId);
    }
  }

  // Helper to find branch by ID - This becomes async
  Future<Branch?> getBranchById(String branchId) async {
    if (_branchesDao != null) {
      return await _branchesDao!.getBranchById(branchId);
    }
    return null; 
  }

  // Helper to find tenant for a branch
  Future<Tenant?> getTenantForBranch(String branchId) async {
    final branch = await getBranchById(branchId);
    if (branch == null) return null;
    
    try {
      return _cacheTenants.firstWhere((t) => t.id == branch.tenantId);
    } catch (_) {
      return null;
    }
  }

  /// Unified Local Login Fallback
  Future<Map<String, dynamic>?> localLogin(String identifier, String password, AppRole role) async {
    // 1. Primary Tenant/SuperAdmin Login
    try {
      final tenant = _cacheTenants.firstWhere(
        (t) => t.email.toLowerCase() == identifier.toLowerCase() && t.id == password,
      );
      return {
        'type': 'tenant',
        'id': tenant.id,
        'data': {
          'email': tenant.email,
          'businessName': tenant.businessName,
          'phone': tenant.phone,
          'status': tenant.status,
          'tierId': tenant.tierId,
        }
      };
    } catch (_) {}

    // 2. Branch Login
    if (role == AppRole.staff || role == AppRole.manager) {
      if (_branchesDao != null) {
        for (final tenant in _cacheTenants) {
          final branches = await _branchesDao!.getBranchesForTenant(tenant.id);
          try {
            final branch = branches.firstWhere(
              (b) => b.loginUsername == identifier && b.loginPassword == password
            );
            return {
               'type': 'branch', 
               'data': {
                  'name': branch.name,
                  'location': branch.location,
                  'contactPhone': branch.contactPhone,
                  'managerName': branch.managerName,
                  'loginUsername': branch.loginUsername,
                  'loginPassword': branch.loginPassword,
               }, 
               'id': branch.id, 
               'tenantId': tenant.id
            };
          } catch (_) {}
        }
      }
    }
    
    return null;
  }
}


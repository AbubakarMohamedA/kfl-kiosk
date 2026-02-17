import 'package:flutter/foundation.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tier.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart';

class TenantService {
  // Singleton pattern for simple state management in this phase
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  final List<Tier> _tiers = [
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
  ];

  final List<Tenant> _tenants = [
    // Super Admin Account
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
    Tenant(
      id: 'TEN001',
      name: 'John Mwangi',
      businessName: 'Mwangi Flour Distributors',
      email: 'client1@gmail.com',
      phone: '+254712345678',
      status: 'Active',
      tierId: 'enterprise',
      createdDate: DateTime(2024, 1, 15),
      lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
      ordersCount: 156,
      revenue: 2500000.0,
      isMaintenanceMode: false,
    ),
    Tenant(
      id: 'TEN002',
      name: 'Mary Wanjiru',
      businessName: 'Wanjiru General Store',
      email: 'client2@gmail.com',
      phone: '+254723456789',
      status: 'Active',
      tierId: 'standard',
      createdDate: DateTime(2024, 2, 20),
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
      ordersCount: 89,
      revenue: 1200000.0,
      isMaintenanceMode: false,
    ),
    Tenant(
      id: 'TEN003',
      name: 'Peter Ochieng',
      businessName: 'Ochieng Bakery Supplies',
      email: 'client3@gmail.com',
      phone: '+254734567890',
      status: 'Inactive',
      tierId: 'standard',
      createdDate: DateTime(2024, 3, 10),
      lastLogin: DateTime.now().subtract(const Duration(days: 30)),
      ordersCount: 45,
      revenue: 650000.0,
      isMaintenanceMode: false,
    ),
    Tenant(
      id: 'TEN004',
      name: 'Grace Akinyi',
      businessName: 'Grace Kitchen Essentials',
      email: 'client4@gmail.com',
      phone: '+254745678901',
      status: 'Active',
      tierId: 'premium',
      createdDate: DateTime(2024, 4, 5),
      lastLogin: DateTime.now().subtract(const Duration(hours: 5)),
      ordersCount: 212,
      revenue: 3100000.0,
      isMaintenanceMode: false,
    ),
    Tenant(
      id: 'TEN005',
      name: 'David Kiprop',
      businessName: 'Kiprop Oil & Flour',
      email: 'client5@gmail.com',
      phone: '+254756789012',
      status: 'Pending',
      tierId: 'standard',
      createdDate: DateTime(2024, 5, 1),
      lastLogin: null,
      ordersCount: 0,
      revenue: 0.0,
      isMaintenanceMode: false,
    ),
    Tenant(
      id: 'TEN007',
      name: 'David Kiprop',
      businessName: 'Kiprop Oil & Flour',
      email: 'client7@gmail.com',
      phone: '+254756789012',
      status: 'Active',
      tierId: 'alone',
      createdDate: DateTime(2024, 5, 1),
      lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
      ordersCount: 0,
      revenue: 0.0,
      isMaintenanceMode: false,
    ),
  ];

  List<Tenant> getTenants() {
    return List.unmodifiable(_tenants);
  }

  void addTenant(Tenant tenant) {
    _tenants.add(tenant);
  }

  void updateTenant(Tenant updatedTenant) {
    final index = _tenants.indexWhere((t) => t.id == updatedTenant.id);
    if (index != -1) {
      _tenants[index] = updatedTenant;
    }
  }

  void deleteTenant(String id) {
    _tenants.removeWhere((t) => t.id == id);
  }

  // Tier Management
  List<Tier> getTiers() {
    return List.unmodifiable(_tiers);
  }

  Tier? getTierById(String id) {
    try {
      return _tiers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  void addTier(Tier tier) {
    if (!_tiers.any((t) => t.id == tier.id)) {
      _tiers.add(tier);
    }
  }

  void updateTier(Tier tier) {
    final index = _tiers.indexWhere((t) => t.id == tier.id);
    if (index != -1) {
      _tiers[index] = tier;
    }
  }

  void deleteTier(String id) {
    // Prevent deleting default tiers if needed, or if assigned to tenants
    _tiers.removeWhere((t) => t.id == id);
  }

  Map<String, dynamic> getStats() {
    final totalRevenue = _tenants.fold<double>(0, (sum, t) => sum + t.revenue);
    final totalOrders = _tenants.fold<int>(0, (sum, t) => sum + t.ordersCount);
    final activeTenants = _tenants.where((t) => t.status == 'Active').length;
    
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'activeTenants': activeTenants,
      'avgRevenue': _tenants.isEmpty ? 0.0 : totalRevenue / _tenants.length,
    };
  }

  // Feature Gating Logic
  bool canAccessFeature(String tenantId, String feature) {
    try {
      final tenant = _tenants.firstWhere((t) => t.id == tenantId);
      
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
  };

  bool get isMaintenanceMode => _isMaintenanceMode;

  void setTenantMaintenanceMode(String tenantId, bool enabled) {
     final index = _tenants.indexWhere((t) => t.id == tenantId);
     if (index != -1) {
       _tenants[index] = _tenants[index].copyWith(isMaintenanceMode: enabled);
     }
  }

  void setMaintenanceMode(bool enabled) {
    _isMaintenanceMode = enabled;
  }
  
  void setModuleMaintenance(String module, bool enabled) {
    if (_moduleMaintenance.containsKey(module)) {
      _moduleMaintenance[module] = enabled;
    }
  }
  
  bool isModuleUnderMaintenance(String module) {
    return _moduleMaintenance[module] ?? false;
  }

  /// Check if a tenant has immunity to blocking
  bool isTenantImmune(String tenantId, {String? fallbackTierId}) {
    try {
      // Try to find tenant in memory
      try {
        final tenant = _tenants.firstWhere((t) => t.id == tenantId);
        
        // 1. Tenant Override
        if (tenant.immuneToBlocking != null) {
          return tenant.immuneToBlocking!;
        }

        // 2. Fallback to Tier
        final tier = getTierById(tenant.tierId);
        return tier?.immuneToBlocking ?? false;
      } catch (e) {
        // Tenant not found in memory
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
      final tenant = _tenants.firstWhere((t) => t.id == tenantId);
      
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
        final tenant = _tenants.firstWhere((t) => t.id == tenantId);
        
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
       final tenant = _tenants.firstWhere((t) => t.id == tenantId);
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
      final tenant = _tenants.firstWhere(
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

  void completeLogin(String tenantId) {
    final index = _tenants.indexWhere((t) => t.id == tenantId);
    if (index != -1) {
      final updated = _tenants[index].copyWith(lastLogin: DateTime.now());
      _tenants[index] = updated;
    }
  }

  bool isFirstLogin(String tenantId) {
    try {
      final tenant = _tenants.firstWhere((t) => t.id == tenantId);
      return tenant.lastLogin == null;
    } catch (e) {
      return false;
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _tiers.clear();
    _tiers.addAll([
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
    
    _tenants.clear();
    _tenants.add(
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
  final List<Branch> _branches = [
    // Mock Data for "Mwangi Flour Distributors" (TEN001)
    const Branch(
      id: 'BR001',
      tenantId: 'TEN001',
      name: 'Nairobi CBD',
      location: 'Moi Avenue',
      contactPhone: '+254712345678',
      managerName: 'James Kamau',
      loginUsername: 'nairobi_cbd', // New
      loginPassword: 'MAN001', // New
    ),
    const Branch(
      id: 'BR002',
      tenantId: 'TEN001',
      name: 'Mombasa Road',
      location: 'Industrial Area',
      contactPhone: '+254722334455',
      managerName: 'Sarah Njoroge',
      loginUsername: 'mombasa_rd', // New
      loginPassword: 'MAN002', // New
    ),
  ];

  List<Branch> getBranchesForTenant(String tenantId) {
    return _branches.where((b) => b.tenantId == tenantId).toList();
  }
  
  void addBranch(Branch branch) {
    _branches.add(branch);
  }
  
  void updateBranch(Branch branch) {
    final index = _branches.indexWhere((b) => b.id == branch.id);
    if (index != -1) {
      _branches[index] = branch;
    }
  }

  void deleteBranch(String branchId) {
    _branches.removeWhere((b) => b.id == branchId);
  }
}


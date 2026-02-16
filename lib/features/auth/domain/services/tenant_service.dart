import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';

class TenantService {
  // Singleton pattern for simple state management in this phase
  static final TenantService _instance = TenantService._internal();
  factory TenantService() => _instance;
  TenantService._internal();

  final List<Tenant> _tenants = [
    // Super Admin Account
    Tenant(
      id: 'SUPER_ADMIN',
      name: 'System Administrator',
      businessName: 'SSS Kiosk System',
      email: 'admin@sss.com',
      phone: '+254000000000',
      status: 'Active',
      tier: TenantTier.premium,
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
      tier: TenantTier.premium,
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
      tier: TenantTier.standard,
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
      tier: TenantTier.standard,
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
      tier: TenantTier.premium,
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
      tier: TenantTier.standard,
      createdDate: DateTime(2024, 5, 1),
      lastLogin: null,
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
      
      // Check if tenant is active
      if (tenant.status != 'Active') return false;

      // Check specific enabled features
      if (tenant.enabledFeatures.contains(feature)) {
        return true;
      }

      // Fallback to tier-based logic if not explicitly enabled/disabled
      // This ensures backward compatibility
      switch (feature) {
        case 'insights':
          return tenant.tier == TenantTier.premium;
        default:
          return true;
      }
    } catch (e) {
      // Logic: If tenant not found, they likely don't have access or it's a new config
      // Default to FALSE to be safe (deny by default)
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

  /// Check if a user/tenant can access the system
  /// [tenantId] - The ID of the tenant trying to access
  /// [isSuperAdmin] - Whether the user is a super admin (bypasses maintenance)
  /// Returns [true] if access is allowed, [false] otherwise.
  bool canAccessSystem(String tenantId, {bool isSuperAdmin = false}) {
    // 1. Maintenance Mode Check
    if (_isMaintenanceMode && !isSuperAdmin) {
      return false; 
    }

    // 2. Super Admin always has access if not maintenance (or if maintenance and is super admin)
    if (isSuperAdmin) return true;

    // 3. Tenant Status Check
    try {
      final tenant = _tenants.firstWhere((t) => t.id == tenantId);
      if (tenant.isMaintenanceMode) return false; // Check tenant specific maintenance
      return tenant.status == 'Active';
    } catch (e) {
      return true; // Unknown tenant -> Allowed (Default to Active for demo)
    }
  }

  bool isTenantEnabled(String tenantId) {
     try {
       final tenant = _tenants.firstWhere((t) => t.id == tenantId);
       return tenant.status == 'Active';
     } catch (e) {
       return true; // Unknown tenant -> Allowed (Default to Active for demo)
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
}

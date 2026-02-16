# Multi-Tenant System Documentation

> Developer-focused documentation for the KFL Kiosk multi-tenant architecture.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Core Entities](#core-entities)
4. [Tenant Service](#tenant-service)
5. [Authentication Flow](#authentication-flow)
6. [Configuration System](#configuration-system)
7. [Order Isolation](#order-isolation)
8. [Feature Gating & Tier System](#feature-gating--tier-system)
9. [Maintenance Mode](#maintenance-mode)
10. [UI Integration](#ui-integration)
11. [Sync Server](#sync-server)
12. [Dependency Injection](#dependency-injection)
13. [File Reference](#file-reference)

---

## Overview

The KFL Kiosk application implements a **multi-tenant architecture** where each tenant (business entity) operates in an isolated context sharing the same application instance. The system provides:

- **Tenant identity** — Each tenant has a unique ID, business profile, tier, and status.
- **Data isolation** — Orders are tagged with `tenantId` and filtered per tenant.
- **Feature gating** — Access to modules is controlled by tenant tier (`standard` / `premium`) and individually enabled features.
- **Maintenance mode** — Global system-wide, per-tenant, and per-module maintenance controls.
- **Configuration isolation** — Each tenant has its own `AppConfiguration` persisted locally.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                       │
│  LoginScreenDesktop → StaffPanelDesktop → SuperAdminScreen      │
│  HomeScreen → TenantSetupScreen → MaintenanceScreen             │
│                    AuthBloc / OrderBloc                          │
├─────────────────────────────────────────────────────────────────┤
│                          Domain Layer                            │
│  Tenant entity    │  Order entity (tenantId)                     │
│  TenantService    │  AuthRepository / OrderRepository            │
│  AppConfiguration │  OrderUseCases (GenerateOrderId)             │
├─────────────────────────────────────────────────────────────────┤
│                           Data Layer                             │
│  AuthMockDataSource / AuthRemoteDataSource                       │
│  LocalOrderDataSource / OrderRemoteDataSource                    │
│  LocalConfigurationDataSource                                    │
├─────────────────────────────────────────────────────────────────┤
│                        Infrastructure                            │
│  SharedPreferences (local)  │  HTTP (remote API / sync server)   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Entities

### Tenant

**File:** `lib/features/auth/domain/entities/tenant.dart`

```dart
class Tenant extends Equatable {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String status;        // 'Active', 'Inactive', 'Pending'
  final TenantTier tier;      // standard | premium
  final DateTime createdDate;
  final DateTime lastLogin;
  final int ordersCount;
  final double revenue;
  final bool isMaintenanceMode;
  final List<String> enabledFeatures;
}
```

| Field              | Purpose                                              |
|--------------------|------------------------------------------------------|
| `id`               | Unique identifier (UUID v4, generated at setup)      |
| `tier`             | Controls feature access (`standard` / `premium`)     |
| `status`           | Account lifecycle state                              |
| `isMaintenanceMode`| Per-tenant maintenance flag                          |
| `enabledFeatures`  | Fine-grained feature whitelist                       |

The `TenantTier` enum defines two levels:

```dart
enum TenantTier { standard, premium }
```

### AppConfiguration

**File:** `lib/core/configuration/domain/entities/app_configuration.dart`

Tenant-specific application settings, persisted locally per device:

```dart
class AppConfiguration {
  final bool isConfigured;
  final String? tenantId;
  final String? businessName;
  final String? contactEmail;
  final String? contactPhone;
  final String? businessAddress;
  final String? logoPath;
  final String? defaultWarehouse;
  final String currency;
  final bool enableNotifications;
  final StatusTrackingMode statusTrackingMode;  // orderLevel | itemLevel
  final bool darkMode;
  final String language;
}
```

This entity bridges the tenant identity to the local device configuration. During login, `tenantId` is written into the configuration, linking all subsequent operations to that tenant.

### Order (Tenant-Aware)

**File:** `lib/features/orders/domain/entities/order.dart`

```dart
class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final String phone;
  final DateTime timestamp;
  final String status;
  final String? tenantId;    // ← Multi-tenant field
  // ...
}
```

The `tenantId` field enables data isolation — all queries filter by the current tenant's ID.

---

## Tenant Service

**File:** `lib/features/auth/domain/services/tenant_service.dart`

A **singleton** service managing tenant operations:

### Key Methods

| Method                                  | Description                                                           |
|-----------------------------------------|-----------------------------------------------------------------------|
| `getTenants()`                          | Returns all registered tenants                                        |
| `addTenant(Tenant)`                     | Adds a new tenant                                                     |
| `updateTenant(Tenant)`                  | Updates an existing tenant                                            |
| `deleteTenant(String id)`              | Removes a tenant                                                      |
| `getStats()`                            | Aggregated statistics: total revenue, orders, active count, avg revenue|
| `canAccessFeature(tenantId, feature)`   | **Feature gating** — checks tier + `enabledFeatures`                  |
| `canAccessSystem(tenantId, {isSuperAdmin})` | Full access check: maintenance + status + super admin bypass     |
| `isSuperAdmin(tenantId)`                | Checks if tenant is the super admin                                   |
| `isTenantEnabled(tenantId)`             | Checks `status == 'Active'`                                          |
| `login(username, password)`             | Authenticates credentials and returns a `Tenant`                      |
| `setMaintenanceMode(bool)`              | Toggles **global** maintenance mode                                   |
| `setTenantMaintenanceMode(id, bool)`    | Toggles **per-tenant** maintenance mode                               |
| `setModuleMaintenance(module, bool)`    | Toggles **per-module** maintenance (orders, history, insights, etc.)  |
| `isModuleUnderMaintenance(module)`      | Checks if a specific module is under maintenance                      |

### Feature Gating Logic

```dart
bool canAccessFeature(String tenantId, String feature) {
  final tenant = _tenants.firstWhere((t) => t.id == tenantId);
  
  // Check tier-based access
  if (_premiumFeatures.contains(feature) && tenant.tier != TenantTier.premium) {
    // Check if explicitly enabled for this tenant regardless of tier
    return tenant.enabledFeatures.contains(feature);
  }
  return true;  // Standard features accessible to all
}
```

Premium features are defined internally. Standard-tier tenants can still access premium features if explicitly added to their `enabledFeatures` list.

### System Access Logic

```dart
bool canAccessSystem(String tenantId, {bool isSuperAdmin = false}) {
  if (_isMaintenanceMode && !isSuperAdmin) return false;
  if (isSuperAdmin) return true;
  final tenant = findTenant(tenantId);
  if (tenant.isMaintenanceMode) return false;
  return tenant.status == 'Active';
}
```

> **Note:** Unknown tenant IDs default to `allowed` — this is intended for demo purposes but should be restricted in production.

---

## Authentication Flow

### Components

| Component                    | File                                                         | Role                                       |
|------------------------------|--------------------------------------------------------------|--------------------------------------------|
| `AuthBloc`                   | `lib/features/auth/presentation/bloc/auth_bloc.dart`         | State management for auth events           |
| `AuthRepository`             | `lib/features/auth/domain/repositories/auth_repository.dart` | Abstract interface                         |
| `AuthRepositoryImpl`         | `lib/features/auth/data/repositories/auth_repository_impl.dart` | Switches mock/remote based on `ApiConfig.isMockMode` |
| `AuthMockDataSource`         | `lib/features/auth/data/datasources/auth_mock_datasource.dart`  | Uses `TenantService.login()`             |
| `AuthRemoteDataSource`       | `lib/features/auth/data/datasources/auth_remote_datasource.dart`| POST to `/auth/login`                    |
| `LoginScreenDesktop`         | `lib/features/auth/presentation/screens/login_screen_desktop.dart` | Desktop login UI                      |

### Flow Sequence

```
User enters credentials
  → LoginScreenDesktop dispatches LoginRequested to AuthBloc
    → AuthBloc calls AuthRepository.login()
      → Mock: TenantService.login() validates + returns Tenant
      → Remote: POST /auth/login → parses JSON → creates Tenant
    → AuthBloc emits AuthAuthenticated(tenant)
      → LoginScreenDesktop receives state:
        1. Updates AppConfiguration with tenant's ID
        2. If first login (no config): navigates to TenantSetupScreen
        3. If configured: navigates to StaffPanelDesktop
```

### Auth State Machine

```
AuthInitial → (LoginRequested) → AuthLoading → AuthAuthenticated
                                              → AuthFailure
AuthAuthenticated → (LogoutRequested) → AuthInitial
```

### Logout Cleanup

On logout, `StaffPanelDesktop._handleLogout()`:
1. Resets `AppConfiguration` to defaults (clears `tenantId`)
2. Dispatches `ClearOrders()` event to `OrderBloc` (prevents data bleeding)
3. Navigates to `LoginScreenDesktop`

---

## Configuration System

### Persistence Stack

```
ConfigurationRepository (abstract)
  └── ConfigurationRepositoryImpl
        └── LocalConfigurationDataSource
              └── SharedPreferences (key: 'app_configuration')
```

**Files:**
- `lib/core/configuration/domain/repositories/configuration_repository.dart`
- `lib/core/configuration/data/repositories/configuration_repository_impl.dart`
- `lib/core/configuration/data/datasources/local_configuration_datasource.dart`

The configuration is stored as a JSON string in `SharedPreferences` and includes the `tenantId` to bind the device to a specific tenant session.

### Tenant Setup Wizard

**File:** `lib/features/admin/presentation/screens/tenant_setup_screen.dart`

A 3-step wizard for first-time setup:

1. **Business Information** — Name, email, phone, address
2. **Kiosk Preferences** — Warehouse, currency, notifications, status tracking mode
3. **Confirmation** — Review and save

Key operation in `_saveConfiguration()`:
```dart
final newConfig = currentConfig.copyWith(
  isConfigured: true,
  tenantId: const Uuid().v4(),  // Generate unique tenant ID
  businessName: _businessNameController.text.trim(),
  // ... other fields
);
await configRepo.saveConfiguration(newConfig);
```

---

## Order Isolation

### How Orders Are Scoped to Tenants

#### 1. Order ID Generation

**File:** `lib/features/orders/domain/usecases/order_usecases.dart`

```dart
class GenerateOrderId {
  Future<String> call() async {
    final tenant = await authRepository.getCurrentTenant();
    final tenantId = tenant?.id ?? 'DEFAULT';
    final counter = await orderRepository.getOrderCounter(tenantId: tenantId);
    // Format: TENANTID-ORD0001
    return '${tenantId.substring(0, min(8, tenantId.length))}-ORD${counter.toString().padLeft(4, '0')}';
  }
}
```

Order IDs are **prefixed with a truncated tenant ID**, ensuring global uniqueness across tenants.

#### 2. Order Counter Isolation

**File:** `lib/features/orders/data/datasources/local_order_datasource.dart`

Counters use a **composite key**: `{tenantId}_{yyyyMMdd}`

```dart
Map<String, int> _orderCounters = {};  // e.g., "tenant123_20260216" -> 5

String _getCounterKey(String? tenantId) {
  final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
  final tId = tenantId ?? "default";
  return "${tId}_$dateStr";
}
```

This ensures:
- Each tenant has its own counter
- Counters reset daily (based on date portion of the key)

#### 3. Order Storage & Filtering

**File:** `lib/features/orders/data/repositories/order_repository_impl.dart`

```dart
class OrderRepositoryImpl implements OrderRepository {
  final AuthRepository authRepository;  // ← Injected for tenant context
  
  Future<List<Order>> getAllOrders() async {
    final tenantId = (await authRepository.getCurrentTenant())?.id;
    final orders = await localDataSource.getOrders(tenantId: tenantId);
    return orders.map((m) => m.toEntity()).toList();
  }
}
```

Both `LocalOrderDataSource` and `OrderRemoteDataSource` accept an optional `tenantId` parameter for filtering:

```dart
// LocalOrderDataSource
Future<List<OrderModel>> getOrders({String? tenantId}) async {
  if (tenantId == null) return List.from(_ordersCache);
  return _ordersCache.where((o) => o.tenantId == tenantId).toList();
}

// OrderRemoteDataSource
Future<List<OrderModel>> getOrders({String? tenantId}) async {
  final uri = tenantId != null 
    ? Uri.parse('${ApiConfig.baseUrl}/orders?tenantId=$tenantId')
    : Uri.parse('${ApiConfig.baseUrl}/orders');
  // ...
}
```

#### 4. Order Watching (Streams)

Streams are also tenant-scoped:

```dart
Stream<List<OrderModel>> watchOrders({String? tenantId}) {
  if (tenantId == null) return _ordersStreamController.stream;
  return _ordersStreamController.stream.map((orders) {
    return orders.where((o) => o.tenantId == tenantId).toList();
  });
}
```

#### 5. OrderBloc Tenant Awareness

**File:** `lib/features/orders/presentation/bloc/order/order_bloc.dart`

The `OrderBloc` receives `AuthRepository` and `ConfigurationRepository` as dependencies. It:
- Filters loaded/watched orders by current tenant
- Dispatches `ClearOrders()` on logout to prevent data bleeding between sessions
- Uses `StatusTrackingMode` from configuration for mode-aware status updates

---

## Feature Gating & Tier System

### Tier Definitions

| Feature            | Standard | Premium |
|--------------------|----------|---------|
| Orders             | ✅        | ✅       |
| Order History      | ✅        | ✅       |
| Warehouse Stations | ✅        | ✅       |
| Business Insights  | ❌        | ✅       |

### Access Check in UI

**File:** `lib/features/orders/presentation/screens/staff_panel_desktop.dart`

```dart
// Sidebar always shows "Business Insights" but the content is gated:
_currentScreen == ScreenType.businessInsights
  ? (TenantService().canAccessFeature(tenantId, 'insights')
      ? const BusinessInsightsScreen()
      : const PremiumUpgradeScreen())  // Paywall screen
  : ...
```

Standard-tier tenants see a `PremiumUpgradeScreen` instead of the actual insights.

### Feature Override

A super admin can override tier restrictions by adding features directly to a tenant's `enabledFeatures` list, granting access regardless of tier.

---

## Maintenance Mode

The system supports **three levels** of maintenance control:

### 1. Global System Maintenance

Controlled via `TenantService.setMaintenanceMode(bool)`.

- Blocks **all** non-super-admin users from accessing the system
- Users see `MaintenanceScreen` with a logout option
- Super admin can still access the `SuperAdminScreen` to toggle it off

### 2. Per-Tenant Maintenance

Controlled via `TenantService.setTenantMaintenanceMode(tenantId, bool)`.

- Only blocks users of that specific tenant
- Checked in `StaffPanelDesktop.build()`:

```dart
if ((tenantService.isMaintenanceMode || isTenantMaintenance) 
    && !isSuperAdmin 
    && _currentScreen != ScreenType.superAdmin) {
  return MaintenanceScreen(...);
}
```

### 3. Per-Module Maintenance

Controlled via `TenantService.setModuleMaintenance(module, bool)`.

Individual modules can be put under maintenance:

| Module Key    | Affects                     |
|---------------|-----------------------------|
| `orders`      | Dashboard / active orders   |
| `history`     | Order history view          |
| `insights`    | Business insights screen    |
| `warehouse`   | Warehouse stations          |

When a module is under maintenance, users see a `_buildMaintenancePlaceholder(moduleName)` widget instead of the module content. Super admins bypass all module maintenance checks.

### UI Control

The `SuperAdminScreen` Settings tab provides toggle switches for:
- Global maintenance mode
- Per-module maintenance (orders, history, insights, warehouse)

---

## UI Integration

### Screen Routing Logic

**File:** `lib/features/home/presentation/screens/home_screen.dart`

```
HomeScreen.build():
  1. Load AppConfiguration
  2. If not configured:
     - Desktop → LoginScreenDesktop
     - Mobile/Tablet → TenantSetupScreen
  3. If configured:
     - Check maintenance mode via TenantService
     - Route to responsive screen:
       - Mobile → HomeScreenMobile
       - Tablet → HomeScreenTablet
       - Desktop → StaffPanelDesktop
```

### StaffPanelDesktop Multi-Tenant Checks

**File:** `lib/features/orders/presentation/screens/staff_panel_desktop.dart`

On every build, the panel performs:

1. **Configuration loading** — Reads `tenantId` from `AppConfiguration`
2. **Maintenance check** — Global + per-tenant + per-module
3. **Account status check** — `isTenantEnabled(tenantId)` → shows `AccountDisabledScreen` if false
4. **Super admin check** — `isSuperAdmin(tenantId)` → shows/hides admin sidebar items
5. **Feature gating** — `canAccessFeature()` → gate premium modules

### Sidebar Visibility

```dart
// Super admin only items:
if (TenantService().isSuperAdmin(tenantId)) ...[
  _buildSidebarItem(icon: Icons.storefront, label: 'Customer Kiosk', ...),
  _buildSidebarItem(icon: Icons.admin_panel_settings, label: 'Tenant Management', ...),
  _buildSidebarItem(icon: Icons.tune, label: 'System Settings', ...),
]
```

### Mode-Aware UI Behavior

The `StaffPanelDesktop` adapts based on `StatusTrackingMode`:

| Element                 | Order-Level Mode          | Item-Level Mode                |
|-------------------------|---------------------------|--------------------------------|
| Warehouse Stations      | Hidden from sidebar       | Visible                        |
| Right panel (warehouse) | Hidden                    | Visible                        |
| Status progress         | Binary (0% or 100%)      | Per-item percentage            |
| Status updates          | Entire order at once      | Per-item / per-category        |

---

## Sync Server

**File:** `server/order_server.dart`

A lightweight HTTP server for cross-device order synchronization.

### Tenant-Relevant Endpoints

| Method | Endpoint             | Multi-Tenant Behavior                                   |
|--------|----------------------|---------------------------------------------------------|
| GET    | `/orders`            | Returns all orders (client-side filtering by `tenantId`)|
| POST   | `/orders`            | Stores order with embedded `tenantId`                   |
| GET    | `/orders/counter`    | Returns counter map (`{tenantId_date: count}`)          |
| POST   | `/orders/counter`    | Updates counter for specific `tenantId_date` key        |

The server stores counters in a `Map<String, int>` keyed by `{tenantId}_{yyyyMMdd}`, supporting per-tenant daily counter isolation.

---

## Dependency Injection

**File:** `lib/di/injection.dart`

Key multi-tenant registrations:

```dart
// Auth
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(sl(), sl())
);

// Orders — depends on AuthRepository for tenant context
sl.registerLazySingleton<OrderRepository>(
  () => OrderRepositoryImpl(sl(), sl(), sl())  // includes AuthRepository
);

// Use cases
sl.registerLazySingleton(() => GenerateOrderId(sl(), sl()));  // needs AuthRepository

// BLoC — receives ConfigurationRepository + AuthRepository
sl.registerFactory(() => OrderBloc(
  sl(), sl(), sl(), sl(), sl(),
  configurationRepository: sl(),
  authRepository: sl(),
));
```

The `AuthRepository` is injected into `OrderRepositoryImpl`, `GenerateOrderId`, and `OrderBloc` to provide tenant context without coupling at the data layer.

---

## File Reference

| File | Multi-Tenant Role |
|------|-------------------|
| `lib/features/auth/domain/entities/tenant.dart` | Tenant entity definition |
| `lib/features/auth/domain/services/tenant_service.dart` | Tenant management singleton |
| `lib/core/configuration/domain/entities/app_configuration.dart` | Tenant-specific device config |
| `lib/core/configuration/data/datasources/local_configuration_datasource.dart` | Config persistence |
| `lib/core/configuration/data/repositories/configuration_repository_impl.dart` | Config repository |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Auth state management |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Auth interface |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Auth impl (mock/remote switch) |
| `lib/features/auth/data/datasources/auth_mock_datasource.dart` | Mock auth via TenantService |
| `lib/features/auth/data/datasources/auth_remote_datasource.dart` | Remote auth via HTTP |
| `lib/features/auth/presentation/screens/login_screen_desktop.dart` | Login UI + config update |
| `lib/features/admin/presentation/screens/tenant_setup_screen.dart` | Tenant setup wizard |
| `lib/features/admin/presentation/screens/super_admin_screen.dart` | Super admin panel |
| `lib/features/orders/domain/entities/order.dart` | Order entity with tenantId |
| `lib/features/orders/data/models/order_model.dart` | Order JSON model |
| `lib/features/orders/domain/repositories/order_repository.dart` | Order repo interface |
| `lib/features/orders/data/repositories/order_repository_impl.dart` | Tenant-filtered order operations |
| `lib/features/orders/domain/usecases/order_usecases.dart` | Tenant-prefixed order ID generation |
| `lib/features/orders/data/datasources/local_order_datasource.dart` | Local store with tenant filtering |
| `lib/features/orders/data/datasources/order_remote_datasource.dart` | Remote store with tenant query param |
| `lib/features/orders/presentation/bloc/order/order_bloc.dart` | Tenant-aware order state management |
| `lib/features/home/presentation/screens/home_screen.dart` | Entry point routing |
| `lib/features/orders/presentation/screens/staff_panel_desktop.dart` | Main dashboard with tenant checks |
| `lib/features/settings/presentation/screens/maintenance_screen.dart` | Maintenance mode UI |
| `lib/features/auth/presentation/screens/account_disabled_screen.dart` | Disabled tenant UI |
| `lib/features/settings/presentation/screens/premium_upgrade_screen.dart` | Tier upgrade paywall |
| `lib/di/injection.dart` | DI wiring for tenant dependencies |
| `lib/main.dart` | App entry point |
| `server/order_server.dart` | Sync server with tenant-aware counters |

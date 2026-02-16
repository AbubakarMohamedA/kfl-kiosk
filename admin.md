# Admin & Super Admin — Developer Documentation

> Comprehensive reference for the administration layer of the KFL Kiosk application.
> Covers role-based access, multi-tenant management, feature gating, maintenance mode, and every screen/service involved.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Role Hierarchy & Access Control](#role-hierarchy--access-control)
3. [File Map](#file-map)
4. [Authentication Flow](#authentication-flow)
5. [Tenant Data Model](#tenant-data-model)
6. [Tenant Service (`TenantService`)](#tenant-service)
7. [Super Admin Screen](#super-admin-screen)
8. [Staff Management Screen](#staff-management-screen)
9. [Tenant Setup Wizard](#tenant-setup-wizard)
10. [Settings & Configuration Screens](#settings--configuration-screens)
11. [Maintenance Mode](#maintenance-mode)
12. [Feature Gating & Tier System](#feature-gating--tier-system)
13. [Sidebar Navigation & Module Routing](#sidebar-navigation--module-routing)
14. [Dependency Injection](#dependency-injection)
15. [Current Limitations & TODOs](#current-limitations--todos)

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                    login_screen_desktop                      │
│          (AuthBloc → AuthRepository → TenantService)        │
└───────────┬───────────────────────┬─────────────────────────┘
            │ First login           │ Returning user / Super Admin
            ▼                       ▼
  ┌──────────────────┐   ┌──────────────────────────┐
  │ TenantSetupScreen│   │   StaffPanelDesktop       │
  │  (Setup Wizard)  │   │  (Main App Shell)         │
  └──────────────────┘   └──────────┬─────────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                          │
   ┌──────▼──────┐          ┌───────▼───────┐          ┌──────▼──────┐
   │  Dashboard  │          │ Settings /    │          │ SuperAdmin  │
   │  (Orders)   │          │ Config Screen │          │  Screen     │
   └─────────────┘          └───────────────┘          └─────────────┘
                                                              │
                                               ┌──────────────┼──────────────┐
                                               │              │              │
                                         Tenant Mgmt    Analytics     System Settings
```

The system uses a **multi-tenant architecture** where each tenant operates within an isolated configuration context. The `TenantService` singleton acts as the central authority for tenant data, access control, and maintenance mode management.

**State Management Pattern:**
- **BLoC** (`AuthBloc`, `OrderBloc`) for cross-cutting async state
- **`setState`** for local UI state within admin screens
- **`TenantService`** singleton for tenant CRUD and business rules (in-memory, no persistence yet)

---

## Role Hierarchy & Access Control

| Role | Access Level | Key Capabilities |
|------|-------------|-------------------|
| **Super Admin** | Full system access | Manage all tenants, analytics, system settings, bypass maintenance mode, access Customer Kiosk |
| **Admin / Manager** | Tenant-scoped | Dashboard, Order History, Business Insights (if tier allows), Settings |
| **Staff** | Operational only | Dashboard, Order processing |

**How role is determined:**
- The `TenantService.isSuperAdmin(tenantId)` method checks if `tenantId == 'SUPER_ADMIN'`
- Super Admin status unlocks:
  - Sidebar items: "Customer Kiosk" and "Super Admin"
  - Bypass of global and per-module maintenance mode
  - Bypass of account disabled checks

---

## File Map

### Admin Screens
| File | Lines | Purpose |
|------|-------|---------|
| `lib/features/admin/presentation/screens/super_admin_screen.dart` | ~1299 | Super Admin Panel — tenant CRUD, analytics, system settings |
| `lib/features/admin/presentation/screens/staff_management_screen.dart` | ~1505 | Staff roster, attendance, performance, scheduling, order tracking |
| `lib/features/admin/presentation/screens/tenant_setup_screen.dart` | ~816 | Multi-step setup wizard for new tenants |

### Auth & Tenant Domain
| File | Lines | Purpose |
|------|-------|---------|
| `lib/features/auth/domain/entities/tenant.dart` | ~85 | `Tenant` data model (Equatable) |
| `lib/features/auth/domain/entities/user.dart` | ~19 | `User` entity (id, username, role, token) |
| `lib/features/auth/domain/services/tenant_service.dart` | ~260 | Singleton: tenant CRUD, auth, feature gating, maintenance |
| `lib/features/auth/domain/repositories/auth_repository.dart` | ~8 | Abstract auth contract (login, logout, getCurrentTenant) |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | ~78 | BLoC: LoginRequested / LogoutRequested events, AuthAuthenticated / AuthFailure states |
| `lib/features/auth/presentation/screens/login_screen_desktop.dart` | ~281 | Desktop login UI with AuthBloc integration |

### Settings & Configuration
| File | Lines | Purpose |
|------|-------|---------|
| `lib/features/settings/presentation/screens/settings_screen.dart` | ~1481 | 5-tab settings: General, Business, System, Receipt, Security |
| `lib/features/settings/presentation/screens/configuration_screen.dart` | ~485 | Status tracking mode configuration (order-level vs item-level) |
| `lib/features/settings/presentation/screens/maintenance_screen.dart` | ~81 | Maintenance mode splash screen with logout option |
| `lib/core/configuration/domain/entities/app_configuration.dart` | ~107 | `AppConfiguration` model with tenant-specific fields |

### Navigation
| File | Lines | Purpose |
|------|-------|---------|
| `lib/features/orders/presentation/screens/staff_panel_desktop.dart` | ~2681 | Main app shell: header, sidebar, content routing, maintenance/disabled checks |

### DI
| File | Lines | Purpose |
|------|-------|---------|
| `lib/di/injection.dart` | ~145 | GetIt registration of all data sources, repos, use cases, and BLoCs |

---

## Authentication Flow

```
User enters email + Client ID (Tenant ID as password)
           │
           ▼
  AuthBloc.add(LoginRequested(email, password))
           │
           ▼
  AuthRepository.login(email, password)
      → TenantService.login(email, tenantId)
      → Returns matching Tenant or throws
           │
           ▼
  emit(AuthAuthenticated(tenant))
           │
           ▼
  LoginScreenDesktop._onAuthSuccess(tenant)
      │
      ├─ tenant.id == 'SUPER_ADMIN' → StaffPanelDesktop
      ├─ isFirstLogin (lastLogin == null) → TenantSetupScreen
      └─ otherwise → StaffPanelDesktop
```

**Key details:**
- Login uses `email` to find the tenant and `password` field holds the `tenantId` (simplified for demo)
- On success, `AppConfiguration` is updated with tenant details (`tenantId`, `businessName`, `contactEmail`, etc.) and persisted via `ConfigurationRepository`
- `BlocListener<AuthBloc, AuthState>` in the login screen handles routing

---

## Tenant Data Model

**File:** `lib/features/auth/domain/entities/tenant.dart`

```dart
class Tenant extends Equatable {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String status;           // 'Active', 'Pending', 'Inactive'
  final String tier;             // 'standard', 'premium'
  final DateTime? createdDate;
  final DateTime? lastLogin;
  final int ordersCount;
  final double revenue;
  final bool isMaintenanceMode;
  final List<String> enabledFeatures;  // e.g. ['orders', 'history', 'insights', 'warehouse']
}
```

- Uses `Equatable` for value-based comparison
- `copyWith()` for immutable updates
- `enabledFeatures` allows granular module access beyond basic tier gating

---

## Tenant Service

**File:** `lib/features/auth/domain/services/tenant_service.dart`

The `TenantService` is a **singleton** that acts as the in-memory data store and business logic layer for tenant management.

### Data Storage
- Holds a `List<Tenant> _tenants` with hardcoded demo data including a `SUPER_ADMIN` tenant
- Global maintenance mode flag: `bool _isMaintenanceMode`
- Per-module maintenance map: `Map<String, bool> _moduleMaintenance` (keys: `orders`, `history`, `insights`, `warehouse`)

### CRUD Operations
| Method | Signature | Description |
|--------|-----------|-------------|
| `getTenants()` | `List<Tenant>` | Returns unmodifiable list of all tenants |
| `addTenant(Tenant)` | `void` | Adds a new tenant to the list |
| `updateTenant(Tenant)` | `void` | Replaces tenant with matching ID |
| `deleteTenant(String id)` | `void` | Removes tenant by ID |

### Access Control Methods
| Method | Signature | Description |
|--------|-----------|-------------|
| `isSuperAdmin(String id)` | `bool` | Returns `id == 'SUPER_ADMIN'` |
| `isTenantEnabled(String id)` | `bool` | Checks if tenant status is `'Active'` |
| `canAccessFeature(String tenantId, String feature)` | `bool` | Feature gating by tier + enabledFeatures |
| `canAccessSystem(String tenantId, {bool isSuperAdmin})` | `bool` | Considers global maintenance + tenant maintenance + status |

### Maintenance Mode
| Method | Signature | Description |
|--------|-----------|-------------|
| `isMaintenanceMode` (getter) | `bool` | Global maintenance flag |
| `setMaintenanceMode(bool)` | `void` | Toggle global maintenance |
| `isModuleUnderMaintenance(String module)` | `bool` | Per-module maintenance check |
| `setModuleMaintenance(String, bool)` | `void` | Toggle per-module maintenance |

### Authentication
| Method | Signature | Description |
|--------|-----------|-------------|
| `login(String email, String tenantId)` | `Tenant?` | Finds tenant by email where password = tenant ID |
| `getStats()` | `Map<String, dynamic>` | Returns counts of active/pending/inactive tenants |

---

## Super Admin Screen

**File:** `lib/features/admin/presentation/screens/super_admin_screen.dart` (~1299 lines)

### Layout
```
┌──────────────────────────────────────────────────┐
│  Header (gradient, total tenants, "Add Tenant")  │
├──────────┬───────────────────────────────────────┤
│ Sidebar  │           Tab Content                  │
│ ────────┤  ┌─ Tenants List ──────────────────┐  │
│ Tenants  │  │ Search bar + Tenant cards       │  │
│ Analytics│  │ Each card: name, business,      │  │
│ Settings │  │ status badge, tier, contact,    │  │
│          │  │ actions (view/edit/delete)       │  │
│ Quick    │  └─────────────────────────────────┘  │
│ Stats:   │  ┌─ Analytics ─────────────────────┐  │
│ Active   │  │ Revenue, Orders, Active tenants │  │
│ Pending  │  │ Top performers list             │  │
│ Inactive │  └─────────────────────────────────┘  │
│          │  ┌─ Settings ──────────────────────┐  │
│          │  │ Default tenant, Security,       │  │
│          │  │ Notifications, Maintenance       │  │
│          │  └─────────────────────────────────┘  │
└──────────┴───────────────────────────────────────┘
```

### Tenant Management Dialogs
- **Add Tenant:** `AlertDialog` with fields for name, business name, email, phone, tier dropdown. Creates new tenant via `TenantService.addTenant()`.
- **Edit Tenant:** Pre-fills dialog with existing tenant data. Updates via `TenantService.updateTenant()`.
- **View Tenant:** Bottom sheet showing full tenant details including features, orders, revenue.
- **Delete Tenant:** Confirmation dialog → `TenantService.deleteTenant()`.

### Analytics Tab Content
- total revenue (sum of all tenant revenues)
- total orders (sum of all tenant orders)
- active tenant count
- average revenue per tenant
- Top 5 performing tenants by revenue (sorted descending)

### Settings Tab Content
- **Default Tenant Settings:** auto-approve toggle, welcome emails toggle
- **Security:** 2FA toggle, session timeout dropdown
- **Notifications:** email notifications toggle, SMS alerts toggle
- **System Maintenance:** global maintenance mode toggle, per-module toggles (orders, history, insights, warehouse)

---

## Staff Management Screen

**File:** `lib/features/admin/presentation/screens/staff_management_screen.dart` (~1505 lines)

### Tabs

| Tab | Description |
|-----|-------------|
| **Staff Roster** | Full staff list with search + role filter, cards showing avatar/name/role/status/contact/performance, PopupMenu (Edit, Permissions, Deactivate) |
| **Attendance** | Overview counts (present/on-leave/absent), detailed records with check-in/out times and status badges |
| **Performance** | Per-staff metrics: orders completed, avg completion time, attendance %, overall score with color-coded bars |
| **Scheduling** | Work schedule grid (days × shifts), shift legend. **Partially implemented — placeholder UI** |
| **Active Orders** | Uses `BlocBuilder<OrderBloc, OrderState>` to show live active orders with completion progress per warehouse category |
| **Order History** | Completed orders grouped by date, showing ID, phone, timestamp, total |

### Key Implementation Details
- Mock data for staff roster and attendance (hardcoded `List<Map<String, dynamic>>`)
- Permissions managed via `CheckboxListTile` in a dialog (view_orders, process_orders, manage_inventory, etc.)
- Uses `OrderBloc` for real-time order data in Active Orders and Order History tabs

---

## Tenant Setup Wizard

**File:** `lib/features/admin/presentation/screens/tenant_setup_screen.dart` (~816 lines)

A 3-step wizard shown on **first login** (`tenant.lastLogin == null`).

| Step | Fields | Validation |
|------|--------|------------|
| **1. Business Info** | Business Name, Contact Email, Phone, Address | Required fields, email format |
| **2. Kiosk Settings** | Currency (dropdown), Default Warehouse (dropdown), Order Tracking Mode (order-level / item-level), Notifications toggle | Dropdown selection |
| **3. Review & Complete** | Summary of all entered data, Edit buttons per section | N/A |

**Save Flow:**
1. Reads current `AppConfiguration` from `OrderBloc.configurationRepository`
2. Updates config with tenant-specific values via `copyWith()`
3. Saves config via `configurationRepository.saveConfiguration()`
4. Navigates to `StaffPanelDesktop` via `pushReplacementNamed`

**UI Details:**
- Step progress indicator with numbered circles + connecting lines
- `AnimatedSwitcher` for step transitions (crossFadeTransition)
- `Form` + `GlobalKey<FormState>` per step for validation
- Fade-in animation on initial load

---

## Settings & Configuration Screens

### Settings Screen (5-Tab)

**File:** `lib/features/settings/presentation/screens/settings_screen.dart` (~1481 lines)

| Tab | Contents |
|-----|----------|
| **General** | Notifications, Sound Effects, Auto Backup, Language/Currency/Timezone dropdowns, Operational Mode (item-level tracking toggle) |
| **Business** | Business Name/Phone/Email, Tax config (enable + rate), Operating Hours |
| **System** | Auto Update, Analytics, Backup Frequency, Data Retention, Clear Cache / Export Data / Reset Settings actions, **Network Sync** (server URL + connect) |
| **Receipt** | Print/Email receipts, Logo, Tax breakdown, Footer text, **Live receipt preview** |
| **Security** | Change PIN, Staff Permissions, Auto Logout, Require PIN on Resume, Encryption Key, Audit Log |

**Key Design:**
- Header with gradient + "Save All Changes" button
- Sidebar navigation with tab icons
- `_loadConfiguration()` reads `AppConfiguration` from `OrderBloc.configurationRepository` and `LocalOrderDataSource` for server URL
- Operational mode change (`_showOperationalModeDialog`) confirms before switching status tracking mode

### Configuration Screen (Standalone)

**File:** `lib/features/settings/presentation/screens/configuration_screen.dart` (~485 lines)

Dedicated screen for **Status Tracking Mode** selection:
- **Order-Level:** Entire order moves through statuses together
- **Item-Level:** Per-product-category tracking enabling parallel warehouse processing

Includes visual comparison with step-by-step workflow explanations for each mode. Saves via `configurationRepository.saveConfiguration()` and triggers `LoadOrders` event on the OrderBloc.

---

## Maintenance Mode

### Global Maintenance
When `TenantService.isMaintenanceMode == true`:
- **Non-Super-Admin users** see `MaintenanceScreen` (construction icon, message, logout button)
- **Super Admin** bypasses entirely and can access all screens

### Per-Module Maintenance
Controlled via `TenantService._moduleMaintenance` map. Checked in two places:

1. **`_buildSidebarItem()`** in `StaffPanelDesktop`: Shows lock icon and prevents navigation for non-super-admins
2. **Content area** in `StaffPanelDesktop.build()`: Renders `_buildMaintenancePlaceholder()` instead of the actual screen

Module keys: `orders`, `history`, `insights`, `warehouse`

### Per-Tenant Maintenance
`Tenant.isMaintenanceMode` flag on individual tenants. Checked in `StaffPanelDesktop.build()` alongside global maintenance.

### Account Disabled
`TenantService.isTenantEnabled(tenantId)` checks if `tenant.status == 'Active'`. If disabled, renders `AccountDisabledScreen`.

---

## Feature Gating & Tier System

### Tiers
| Tier | Default Features |
|------|------------------|
| `standard` | `orders`, `history` |
| `premium` | `orders`, `history`, `insights`, `warehouse` |

### Access Check Logic (`TenantService.canAccessFeature`)
```
1. Super Admin → always true
2. Check tenant.enabledFeatures list → if feature is in list, true
3. Fall back to tier defaults → if feature is in tier defaults, true
4. Otherwise → false
```

### Implementation in UI
- **Business Insights** sidebar item is always visible, but clicking it checks `canAccessFeature(tenantId, 'insights')`
  - If allowed → `BusinessInsightsScreen`
  - If denied → `PremiumUpgradeScreen` (paywall)
- **Warehouse Stations** sidebar item only visible when `statusTrackingMode == StatusTrackingMode.itemLevel`

---

## Sidebar Navigation & Module Routing

**File:** `StaffPanelDesktop._buildSidebar()` (lines 726–865)

### Sidebar Items

| Item | ScreenType | Visible To | Condition |
|------|-----------|------------|-----------|
| Dashboard | `dashboard` | All | Always |
| Order History | `dashboard` (showHistory=true) | All | Always |
| Warehouse Stations | `warehouseSelector` | All (if item-level mode) | `statusTrackingMode == itemLevel` |
| Business Insights | `businessInsights` | All | Always (gated by paywall) |
| Customer Kiosk | Dialog (HomeScreenDesktop) | Super Admin only | `isSuperAdmin` |
| Super Admin | `superAdmin` | Super Admin only | `isSuperAdmin` |
| Settings | `settings` | All | Via header icon |

### Content Routing (build method)
```
StaffPanelDesktop.build():
  1. If maintenance mode + not super admin → MaintenanceScreen
  2. If tenant disabled + not super admin → AccountDisabledScreen
  3. Check per-module maintenance for current screen
  4. Route to appropriate screen widget based on _currentScreen enum
```

---

## Dependency Injection

**File:** `lib/di/injection.dart`

Uses **GetIt** service locator. Admin-relevant registrations:

```dart
// Auth Data Sources
getIt.registerLazySingleton<AuthMockDataSource>(() => AuthMockDataSource());
getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(client: getIt()));

// Auth Repository
getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
  mockDataSource: getIt<AuthMockDataSource>(),
  remoteDataSource: getIt<AuthRemoteDataSource>(),
));

// Auth BLoC (factory = new instance per provider)
getIt.registerFactory(() => AuthBloc(
  authRepository: getIt<AuthRepository>(),
));

// Configuration
getIt.registerLazySingleton<LocalConfigurationDataSource>(() => LocalConfigurationDataSource());
getIt.registerLazySingleton<ConfigurationRepository>(() => ConfigurationRepositoryImpl(getIt<LocalConfigurationDataSource>()));
```

> **Note:** `TenantService` is **NOT** registered in GetIt — it uses its own singleton pattern and is instantiated directly where needed.

---

## AppConfiguration Model

**File:** `lib/core/configuration/domain/entities/app_configuration.dart`

```dart
class AppConfiguration {
  final StatusTrackingMode statusTrackingMode;  // orderLevel | itemLevel
  final bool darkMode;
  final String language;
  final bool isConfigured;          // true after TenantSetupScreen completion
  final String? tenantId;
  final String? businessName;
  final String? contactEmail;
  final String? contactPhone;
  final String? businessAddress;
  final String? logoPath;
  final String? defaultWarehouse;
  final String currency;            // default 'KSH'
  final bool enableNotifications;
}
```

Includes `copyWith()`, `toJson()`, and `fromJson()` for serialization. Persisted via `ConfigurationRepository` → `LocalConfigurationDataSource`.

---

## Current Limitations & TODOs

| Area | Issue | Priority |
|------|-------|----------|
| **Authentication** | `TenantService.login()` uses tenant ID as password — demo-only, needs real auth | High |
| **Tenant Data** | All tenants stored in-memory; no database persistence | High |
| **Staff Management** | Scheduling tab is **placeholder UI** only | Medium |
| **Staff Management** | Add/Edit staff dialogs use hardcoded mock data | Medium |
| **TenantService** | Not registered in DI container; uses manual singleton | Low |
| **User Entity** | `User` entity exists but is not used in auth flow (uses `Tenant` instead) | Low |
| **Super Admin Detection** | Hardcoded string check `id == 'SUPER_ADMIN'` — needs role-based system | Medium |
| **Feature Gating** | Tier system is hardcoded in service — should be configurable | Medium |
| **Settings Screen** | Many settings are local state only, not persisted across sessions | Medium |
| **Network Sync** | Server URL is stored in `LocalOrderDataSource`, separate from tenant config | Low |

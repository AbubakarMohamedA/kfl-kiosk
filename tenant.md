# Tenant System — Developer Documentation

> **Audience:** Developers working on the SSS Kiosk codebase.
> **Scope:** Everything related to the **Tenant** concept — model, service, authentication, feature gating, maintenance mode, admin management UI, first-login setup, order tagging, and local configuration.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture at a Glance](#2-architecture-at-a-glance)
3. [File Map](#3-file-map)
4. [Tenant Entity](#4-tenant-entity)
5. [TenantService — Core Business Logic](#5-tenantservice--core-business-logic)
6. [Authentication Flow](#6-authentication-flow)
7. [Feature Gating](#7-feature-gating)
8. [Maintenance Mode](#8-maintenance-mode)
9. [Tenant Setup Wizard (First-Login)](#9-tenant-setup-wizard-first-login)
10. [Super Admin — Tenant CRUD](#10-super-admin--tenant-crud)
11. [Tenant in Orders](#11-tenant-in-orders)
12. [Configuration Persistence](#12-configuration-persistence)
13. [Staff Panel Integration](#13-staff-panel-integration)
14. [Home Screen Routing](#14-home-screen-routing)
15. [Dependency Injection](#15-dependency-injection)
16. [Key Data Flows (Step-by-Step)](#16-key-data-flows-step-by-step)
17. [Enhancement Guide](#17-enhancement-guide)

---

## 1. Overview

The **Tenant** is the central identity in the SSS Kiosk system. Every logged-in user belongs to a tenant, and the tenant determines:

| Concern | What the Tenant Controls |
|---|---|
| **Identity** | Business name, contact info, unique ID |
| **Authorization** | Which features (modules) are accessible |
| **Tier** | `Standard` vs `Premium` — controls default feature availability |
| **Status** | `Active`, `Inactive`, or `Pending` — gates system access |
| **Maintenance** | Per-tenant and global maintenance mode |
| **Branding/Config** | Currency, warehouse, notifications, order tracking mode — persisted locally |
| **Order Ownership** | Every order is tagged with a `tenantId` |

There is one special tenant: **`SUPER_ADMIN`** (ID = `'SUPER_ADMIN'`). This tenant bypasses all maintenance and access restrictions and has access to the Super Admin Panel for managing other tenants.

---

## 2. Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │ LoginScreen  │ │ TenantSetup  │ │   SuperAdminScreen   │ │
│  │  Desktop     │ │   Screen     │ │  (CRUD + Analytics)  │ │
│  └──────┬───────┘ └──────┬───────┘ └──────────┬───────────┘ │
│         │                │                    │             │
│  ┌──────┴───────┐        │                    │             │
│  │  AuthBloc    │        │                    │             │
│  └──────┬───────┘        │                    │             │
├─────────┼────────────────┼────────────────────┼─────────────┤
│         │          Domain Layer               │             │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌──────────┴───────────┐ │
│  │AuthRepository│ │ AppConfig-   │ │   TenantService      │ │
│  │  (interface) │ │ uration      │ │   (Singleton)        │ │
│  └──────┬───────┘ └──────┬───────┘ │  - CRUD              │ │
│         │                │         │  - Auth (login)      │ │
│  ┌──────┴───────┐ ┌──────┴───────┐ │  - Feature Gating    │ │
│  │AuthRepoImpl  │ │ ConfigRepo   │ │  - Maintenance       │ │
│  │ (mock/remote)│ │ (SharedPrefs)│ │  - Stats             │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Tenant Entity (Equatable, immutable, copyWith)      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. File Map

Every file that participates in the tenant subsystem, grouped by layer.

### Domain Layer

| File | Purpose | Key Exports |
|---|---|---|
| `lib/features/auth/domain/entities/tenant.dart` | Tenant data model | `Tenant`, `TenantTier` |
| `lib/features/auth/domain/services/tenant_service.dart` | **Core business logic** — CRUD, auth, feature gating, maintenance | `TenantService` |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Auth repository interface | `AuthRepository` |
| `lib/core/configuration/domain/entities/app_configuration.dart` | Local config model (includes tenant fields) | `AppConfiguration`, `StatusTrackingMode` |
| `lib/core/configuration/domain/repositories/configuration_repository.dart` | Config repo interface | `ConfigurationRepository` |

### Data Layer

| File | Purpose |
|---|---|
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Switches between mock and remote login; caches `_currentTenant` |
| `lib/features/auth/data/datasources/auth_mock_datasource.dart` | Calls `TenantService.login()` with simulated delay |
| `lib/features/auth/data/datasources/auth_remote_datasource.dart` | POST `/auth/login`, maps JSON → `Tenant` |
| `lib/core/configuration/data/repositories/configuration_repository_impl.dart` | Saves/loads `AppConfiguration` via `SharedPreferences` |
| `lib/core/configuration/data/datasources/local_configuration_datasource.dart` | Raw SharedPreferences read/write for config JSON |

### Presentation Layer

| File | Purpose |
|---|---|
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | BLoC managing login/logout; emits `AuthAuthenticated(tenant)` |
| `lib/features/auth/presentation/screens/login_screen_desktop.dart` | Desktop login form; routes to `TenantSetupScreen` or `StaffPanelDesktop` based on tenant state |
| `lib/features/admin/presentation/screens/tenant_setup_screen.dart` | 3-step first-login wizard (Business Info → Settings → Review) |
| `lib/features/admin/presentation/screens/super_admin_screen.dart` | Full CRUD panel for managing tenants (Tenants, Analytics, Settings tabs) |
| `lib/features/admin/presentation/screens/staff_management_screen.dart` | Uses `tenant.enabledFeatures` to show role-permissions UI |
| `lib/features/orders/presentation/screens/staff_panel_desktop.dart` | Main desktop shell; tenant gates sidebar items & module access |
| `lib/features/home/presentation/screens/home_screen.dart` | Root router; checks config & maintenance before rendering |
| `lib/features/home/presentation/screens/home_screen_tablet.dart` | Tablet login/home; uses `AuthBloc` and displays `tenant.name` |

### Order Layer (Tenant Tagging)

| File | Purpose |
|---|---|
| `lib/features/orders/domain/entities/order.dart` | `Order` entity has nullable `tenantId` field |
| `lib/features/orders/data/models/order_model.dart` | `OrderModel` mirrors `tenantId` for serialization |
| `lib/features/orders/presentation/bloc/order/order_bloc.dart` | Attaches `tenantId` from `authRepository.getCurrentTenant()` to new orders |
| `lib/features/orders/data/repositories/order_repository_impl.dart` | Passes tenant context through to datasources |
| `lib/features/orders/domain/usecases/order_usecases.dart` | Use cases that flow through tenant-tagged orders |

### Dependency Injection

| File | Purpose |
|---|---|
| `lib/di/injection.dart` | Registers `AuthMockDataSource`, `AuthRemoteDataSource`, `AuthRepositoryImpl`, `AuthBloc`, `ConfigurationRepository` in GetIt |

---

## 4. Tenant Entity

**File:** `lib/features/auth/domain/entities/tenant.dart`

```dart
enum TenantTier { standard, premium }

class Tenant extends Equatable {
  final String id;              // Unique ID (e.g., 'TEN001', 'SUPER_ADMIN')
  final String name;            // Contact person name
  final String businessName;    // Company/business name
  final String email;           // Login email
  final String phone;           // Contact phone
  final String status;          // 'Active' | 'Inactive' | 'Pending'
  final TenantTier tier;        // standard | premium
  final DateTime createdDate;   // Account creation date
  final DateTime? lastLogin;    // null = never logged in (triggers setup wizard)
  final int ordersCount;        // Aggregated order count
  final double revenue;         // Aggregated revenue
  final bool isMaintenanceMode; // Per-tenant maintenance flag
  final List<String> enabledFeatures; // e.g., ['orders','history','insights','warehouse']
}
```

### Key Design Decisions

- **Equatable**: Enables value-based equality for BLoC state comparisons.
- **`copyWith`**: Immutable updates — used extensively in edit dialogs and service methods.
- **`status` is a `String`**, not an enum — values are `'Active'`, `'Inactive'`, `'Pending'`. Watch for case sensitivity.
- **`lastLogin == null`** is the signal for first-login (triggers setup wizard).
- **`enabledFeatures`** is an explicit list of module keys that override tier-based defaults.

### If You Need to Change It

| Change | What to Update |
|---|---|
| Add a new field | Add to constructor, `copyWith`, `props`, and update `TenantService` hardcoded entries, `super_admin_screen.dart` dialogs, `auth_remote_datasource.dart` JSON mapping |
| Add a new status | Update status string checks in `TenantService`, `super_admin_screen.dart` status dropdown, and `_buildTenantCard` color logic |
| Add a new tier | Extend `TenantTier` enum, update `canAccessFeature` switch, and `_parseTier` in `auth_remote_datasource.dart` |

---

## 5. TenantService — Core Business Logic

**File:** `lib/features/auth/domain/services/tenant_service.dart`

This is a **singleton** class that acts as the central in-memory data store and business-logic engine for tenants.

### Singleton Pattern

```dart
static final TenantService _instance = TenantService._internal();
factory TenantService() => _instance;
```

Any `TenantService()` call anywhere in the codebase returns the same instance with the same `_tenants` list.

### Pre-Seeded Data

The service initializes with **6 hardcoded tenants** (including `SUPER_ADMIN`):

| ID | Name | Business | Status | Tier |
|---|---|---|---|---|
| `SUPER_ADMIN` | System Administrator | SSS Kiosk System | Active | Premium |
| `TEN001` | John Mwangi | Mwangi Flour Distributors | Active | Premium |
| `TEN002` | Mary Wanjiru | Wanjiru General Store | Active | Standard |
| `TEN003` | Peter Ochieng | Ochieng Bakery Supplies | Inactive | Standard |
| `TEN004` | Grace Akinyi | Grace Kitchen Essentials | Active | Premium |
| `TEN005` | David Kiprop | Kiprop Oil & Flour | Pending | Standard |

> **Warning:** All tenant data lives **in memory** only. App restarts reset to these defaults. This is the demo/development phase design.

### Functions Reference

#### CRUD Operations

| Function | Signature | What It Does |
|---|---|---|
| `getTenants()` | `List<Tenant> getTenants()` | Returns an **unmodifiable** copy of all tenants |
| `addTenant()` | `void addTenant(Tenant tenant)` | Appends a new tenant to the list |
| `updateTenant()` | `void updateTenant(Tenant updatedTenant)` | Finds by `id` and replaces in-place |
| `deleteTenant()` | `void deleteTenant(String id)` | Removes by `id` |
| `getStats()` | `Map<String, dynamic> getStats()` | Returns `totalRevenue`, `totalOrders`, `activeTenants`, `avgRevenue` |

#### Authentication Methods

| Function | Signature | What It Does |
|---|---|---|
| `login()` | `Tenant? login(String email, String password)` | Matches `email` (case-insensitive) **AND** `password == tenant.id`. Returns null on failure. |
| `isSuperAdmin()` | `bool isSuperAdmin(String tenantId)` | Returns `true` if `tenantId == 'SUPER_ADMIN'` |
| `completeLogin()` | `void completeLogin(String tenantId)` | Updates `lastLogin` to `DateTime.now()` |
| `isFirstLogin()` | `bool isFirstLogin(String tenantId)` | Returns `true` if `lastLogin == null` |

> **Important:** The current auth model uses **Tenant ID as the password**. For example, tenant `TEN001` logs in with email `client1@gmail.com` and password `TEN001`.

#### Feature Gating

| Function | Signature | What It Does |
|---|---|---|
| `canAccessFeature()` | `bool canAccessFeature(String tenantId, String feature)` | **3-layer check:** ① Tenant must be `Active` ② Check `enabledFeatures` list ③ Fallback to tier logic (only `insights` is Premium-gated by default). Deny by default if tenant not found. |

**Feature Keys in Use:** `'orders'`, `'history'`, `'insights'`, `'warehouse'`

```
canAccessFeature Logic:
  1. Tenant not Active? → FALSE
  2. Feature in enabledFeatures? → TRUE
  3. Fallback switch:
     - 'insights' → Premium only
     - default → TRUE
  4. Tenant not found → FALSE (deny by default)
```

#### Maintenance Mode

| Function | Signature | What It Does |
|---|---|---|
| `setMaintenanceMode()` | `void setMaintenanceMode(bool enabled)` | Toggles **global** maintenance |
| `isMaintenanceMode` | `bool get isMaintenanceMode` | Returns global maintenance state |
| `setTenantMaintenanceMode()` | `void setTenantMaintenanceMode(String tenantId, bool enabled)` | Toggles maintenance for a **specific tenant** |
| `setModuleMaintenance()` | `void setModuleMaintenance(String module, bool enabled)` | Toggles maintenance for a **specific module** |
| `isModuleUnderMaintenance()` | `bool isModuleUnderMaintenance(String module)` | Checks if a specific module is under maintenance |

**Module maintenance keys:** `'orders'`, `'history'`, `'insights'`, `'warehouse'`, `'settings'`

#### System Access

| Function | Signature | What It Does |
|---|---|---|
| `canAccessSystem()` | `bool canAccessSystem(String tenantId, {bool isSuperAdmin})` | **3-layer check:** ① Global maintenance blocks non-super-admins ② Super admin always passes ③ Checks tenant-specific maintenance and `Active` status |
| `isTenantEnabled()` | `bool isTenantEnabled(String tenantId)` | Returns `true` if status is `'Active'` (returns `true` for unknown tenants — demo default) |

---

## 6. Authentication Flow

### Architecture

```
LoginScreenDesktop                     AuthBloc
     │                                    │
     │── LoginRequested(email, pwd) ──►   │
     │                                    │── authRepository.login()
     │                                    │      │
     │                                    │      ├── MockMode? → AuthMockDataSource
     │                                    │      │                  └── TenantService.login()
     │                                    │      │
     │                                    │      └── RemoteMode? → AuthRemoteDataSource
     │                                    │                          └── POST /auth/login
     │                                    │
     │◄── AuthAuthenticated(tenant) ──── │
     │                                    │
     ├── tenant.id == 'SUPER_ADMIN'? ─►  StaffPanelDesktop
     ├── tenant.lastLogin == null?   ─►  TenantSetupScreen (first login)
     └── otherwise                   ─►  StaffPanelDesktop
```

### Key Files in the Flow

1. **`login_screen_desktop.dart`** — UI dispatches `LoginRequested` event to `AuthBloc`, listens for `AuthAuthenticated` state.
2. **`auth_bloc.dart`** — Calls `authRepository.login()`, emits `AuthAuthenticated(tenant)` or `AuthFailure(message)`.
3. **`auth_repository_impl.dart`** — Checks `ApiConfig.isMockMode`. In mock mode, delegates to `AuthMockDataSource`; in live mode, to `AuthRemoteDataSource`. Caches `_currentTenant` for later retrieval.
4. **`auth_mock_datasource.dart`** — Calls `TenantService().login(email, password)`. Simulates 1-second network delay.
5. **`auth_remote_datasource.dart`** — HTTP POST to `/auth/login`. Maps JSON response to `Tenant` object with `_parseTier()`.

### Post-Login Routing (in `_onAuthSuccess`)

```dart
if (tenant.id == 'SUPER_ADMIN') → StaffPanelDesktop
else if (isFirstLogin)          → TenantSetupScreen  // lastLogin == null
else                            → StaffPanelDesktop
```

Additionally, on successful login:
- `AppConfiguration` is updated with `tenantId`, `businessName`, `contactEmail`, `contactPhone`, and `isConfigured = true`
- Config is saved via `ConfigurationRepository`

### Mock Mode Credentials

| Email | Password (Tenant ID) | Result |
|---|---|---|
| `admin@sss.com` | `SUPER_ADMIN` | Super Admin |
| `client1@gmail.com` | `TEN001` | John Mwangi |
| `client2@gmail.com` | `TEN002` | Mary Wanjiru |
| `client3@gmail.com` | `TEN003` | Peter Ochieng (Inactive — will be blocked) |
| `client4@gmail.com` | `TEN004` | Grace Akinyi |
| `client5@gmail.com` | `TEN005` | David Kiprop (Pending — first login) |

---

## 7. Feature Gating

Feature gating controls which sidebar modules a tenant can access in the Staff Panel.

### How It Works

The Staff Panel (`staff_panel_desktop.dart`) checks each sidebar item before rendering:

```dart
// In _buildSidebar():
TenantService().canAccessFeature(
    _currentConfig.tenantId ?? '',
    'insights'  // or 'orders', 'history', 'warehouse'
)
```

If `canAccessFeature()` returns `false`, the sidebar item is hidden or the view is replaced with a premium upsell message.

### Two-Level Gating System

1. **Explicit Features** (`enabledFeatures` list on the Tenant entity):
   - If the feature key is in this list → **allowed** (overrides tier)
   - Super Admin sets these in the edit/add dialogs

2. **Tier Fallback** (only applies if feature not in `enabledFeatures`):
   - `insights` → requires `TenantTier.premium`
   - All other features → allowed by default

### Where Features Are Set

- **Add Tenant Dialog** (`super_admin_screen.dart:810`): Checkbox list of `['orders', 'history', 'insights', 'warehouse']`
- **Edit Tenant Dialog** (`super_admin_screen.dart:984`): Same checkbox list, pre-populated from current tenant

### Adding a New Gated Feature

1. Add the feature key string (e.g., `'reports'`) to:
   - `_moduleMaintenance` map in `TenantService`
   - `availableFeatures` list in `_showAddTenantDialog` and `_showEditTenantDialog`
   - `canAccessFeature()` switch-case if it needs tier-based fallback
2. Add the sidebar item check in `staff_panel_desktop.dart`
3. Add the feature's screen widget

---

## 8. Maintenance Mode

The system has **three levels** of maintenance mode, all managed through `TenantService`:

### Level 1: Global System Maintenance

- **Toggle:** `TenantService.setMaintenanceMode(bool)`
- **Check:** `TenantService.isMaintenanceMode`
- **Effect:** All non-super-admin users see `MaintenanceScreen`
- **Set from:** Super Admin Screen → Settings tab → "Maintenance Mode (Full System)"

### Level 2: Per-Tenant Maintenance

- **Toggle:** `TenantService.setTenantMaintenanceMode(tenantId, bool)` or via `Tenant.isMaintenanceMode` field
- **Check:** Read `tenant.isMaintenanceMode` from tenant entity
- **Effect:** Specific tenant sees `MaintenanceScreen`
- **Set from:** Super Admin Screen → Edit Tenant Dialog → "Maintenance Mode" switch

### Level 3: Per-Module Maintenance

- **Toggle:** `TenantService.setModuleMaintenance(module, bool)`
- **Check:** `TenantService.isModuleUnderMaintenance(module)`
- **Effect:** Specific module shows maintenance placeholder instead of content; sidebar item shows warning indicator
- **Set from:** Super Admin Screen → Settings tab → "Module Maintenance" section
- **Module keys:** `'orders'`, `'history'`, `'insights'`, `'warehouse'`, `'settings'`

### Enforcement Points

| Where | What It Checks | Effect |
|---|---|---|
| `home_screen.dart` (L50) | `canAccessSystem()` — global + tenant maintenance | Redirects to `MaintenanceScreen` |
| `staff_panel_desktop.dart` (build, L433) | Global + tenant maintenance | Shows `MaintenanceScreen` with optional admin access button |
| `staff_panel_desktop.dart` (build, L503) | Module-level maintenance | Shows inline maintenance placeholder within the panel |
| `staff_panel_desktop.dart` (_buildSidebarItem, L878) | Module maintenance key | Shows ⚠ warning icon on sidebar item |

### Super Admin Bypass

Super admins (`tenantId == 'SUPER_ADMIN'`) bypass **all three levels** of maintenance. This is critical for being able to turn maintenance off.

---

## 9. Tenant Setup Wizard (First-Login)

**File:** `lib/features/admin/presentation/screens/tenant_setup_screen.dart`

When a tenant logs in for the first time (`lastLogin == null`), they are redirected to this 3-step onboarding wizard.

### Steps

| Step | Screen Key | Fields | Validation |
|---|---|---|---|
| **0 — Business Info** | `'business'` | Business Name, Contact Email, Contact Phone, Business Address | Name, Email (regex), Phone required |
| **1 — Settings** | `'settings'` | Currency, Default Warehouse, Order Tracking Mode, Enable Notifications | None required |
| **2 — Review** | `'review'` | Read-only summary of Steps 0 and 1 | N/A |

### Configuration Options

| Setting | Options | Default |
|---|---|---|
| Currency | KSH, USD, EUR, GBP, TZS, UGX | KSH |
| Default Warehouse | Main, Flour, Oil, Premium | None selected |
| Order Tracking Mode | Order Level, Item Level | Order Level |
| Notifications | Enabled / Disabled | Enabled |

### What `_saveConfiguration()` Does

1. Gets current `AppConfiguration` from `ConfigurationRepository` (via GetIt DI)
2. Creates a new config with:
   - `isConfigured = true`
   - `tenantId` = new UUID (auto-generated)
   - All form fields mapped to config properties
3. Saves to `ConfigurationRepository` (persisted via SharedPreferences)
4. Navigates to `'/'` (root route → `HomeScreen`)

> **Note:** The `tenantId` generated here is a new UUID, **not** the tenant's ID from the `TenantService`. This is because the setup screen is an initial device configuration flow. The tenant's actual ID from `TenantService` is set during login in `login_screen_desktop.dart`.

---

## 10. Super Admin — Tenant CRUD

**File:** `lib/features/admin/presentation/screens/super_admin_screen.dart` (1299 lines)

This is the admin console accessible only to the `SUPER_ADMIN` tenant. It provides full tenant lifecycle management through three tabs.

### Tab Structure

| Tab | Content |
|---|---|
| **Tenants** | Searchable tenant list with cards showing name, business, status badge, tier badge, maintenance badge, revenue, orders, creation date. Actions: View Details, Edit, Delete. |
| **Analytics** | Total Revenue, Total Orders, Active Tenants, Avg Revenue/Tenant — plus Top 3 Performing Tenants. |
| **Settings** | Default Tenant Settings, Security, Notifications, System Control (Global Maintenance), Module Maintenance toggles. |

### CRUD Dialog Details

#### Add Tenant (`_showAddTenantDialog`)
- **Fields:** Full Name, Business Name, Email, Phone, Subscription Tier dropdown, Feature Access checkboxes
- **ID Generation:** `'TEN' + (tenantCount + 1).padLeft(3, '0')` (e.g., `TEN007`)
- **Default Status:** `'Pending'`
- **Calls:** `TenantService.addTenant(newTenant)` then `_loadTenants()` to refresh UI

#### Edit Tenant (`_showEditTenantDialog`)
- **Fields:** Full Name, Business Name, Email, Phone, Status dropdown (`Active`/`Inactive`/`Pending`), Tier dropdown, Maintenance Mode switch, Feature Access checkboxes
- **Calls:** `TenantService.updateTenant(updatedTenant)` then `_loadTenants()`

#### View Details (`_showTenantDetailsDialog`)
- **Read-only:** Tenant ID, Email, Phone, Status, Tier, Created date, Last Login, Orders count, Revenue

#### Delete Tenant (`_showDeleteConfirmDialog`)
- **Confirmation dialog** with warning text
- **Calls:** `TenantService.deleteTenant(tenant.id)` then `_loadTenants()`

### Search & Filter

- **Search bar** filters by `name`, `businessName`, `email`, or `id` (case-insensitive)
- **Status filter dropdown** exists in UI but is not yet wired (always shows "All Status")

---

## 11. Tenant in Orders

Each order is tagged with the logged-in tenant's ID to enable multi-tenant data isolation.

### Entity Fields

```dart
// lib/features/orders/domain/entities/order.dart
class Order extends Equatable {
  final String? tenantId; // Nullable for legacy orders
  // ... other fields
}
```

```dart
// lib/features/orders/data/models/order_model.dart
class OrderModel {
  final String? tenantId;
  // ... mirrors entity for serialization
}
```

### How Tenant ID is Attached to Orders

In `order_bloc.dart`, when a `CreateOrder` event is processed:

```dart
final currentTenant = await authRepository.getCurrentTenant();
final tenantId = currentTenant?.id;
final orderWithTenant = event.order.copyWith(tenantId: tenantId);
final orderId = await createOrderUseCase(orderWithTenant);
```

The `authRepository.getCurrentTenant()` returns the `_currentTenant` cached during login in `AuthRepositoryImpl`.

### Serialization

The `tenantId` is included in the order's JSON serialization:

```dart
// In Order.toMap()
'tenantId': tenantId,

// In Order.fromMap()
tenantId: map['tenantId'],
```

---

## 12. Configuration Persistence

Tenant-related configuration is persisted locally via `AppConfiguration`, stored through `SharedPreferences`.

### Tenant Fields in `AppConfiguration`

**File:** `lib/core/configuration/domain/entities/app_configuration.dart`

| Field | Type | Default | Purpose |
|---|---|---|---|
| `isConfigured` | `bool` | `false` | Whether initial setup has been completed |
| `tenantId` | `String?` | `null` | Unique tenant identifier |
| `businessName` | `String?` | `null` | Business/company name |
| `contactEmail` | `String?` | `null` | Contact email |
| `contactPhone` | `String?` | `null` | Contact phone |
| `businessAddress` | `String?` | `null` | Business address |
| `logoPath` | `String?` | `null` | Path to uploaded logo |
| `defaultWarehouse` | `String?` | `null` | Default warehouse |
| `currency` | `String` | `'KSH'` | Currency code |
| `enableNotifications` | `bool` | `true` | Push notification toggle |
| `statusTrackingMode` | `StatusTrackingMode` | `orderLevel` | Order vs item tracking |

### When Config Is Written

1. **Login success** (`login_screen_desktop.dart`): Sets `tenantId`, `businessName`, `contactEmail`, `contactPhone`, `isConfigured = true`
2. **Setup wizard** (`tenant_setup_screen.dart`): Sets all config fields including currency, warehouse, notifications, tracking mode

### When Config Is Read

1. **`home_screen.dart`**: Checks `isConfigured` to decide routing; reads `tenantId` for maintenance check
2. **`staff_panel_desktop.dart`**: Reads `tenantId` for feature gating, maintenance checks, and UI display

---

## 13. Staff Panel Integration

**File:** `lib/features/orders/presentation/screens/staff_panel_desktop.dart`

The Staff Panel is the main shell after login. Tenant logic is deeply integrated:

### Build Method Gate Sequence

```
1. Is config loading?  → Show loading spinner
2. Get tenantId from config
3. Is global or tenant maintenance? AND not super admin?
   → Show MaintenanceScreen (with admin access button)
4. Is tenant disabled (status != Active)? AND not on super admin screen?
   → Show AccountDisabledScreen
5. Render normal scaffold with sidebar + content
```

### Sidebar Visibility

| Item | Visibility Check |
|---|---|
| Dashboard / Orders | Always visible (but module maintenance can block content) |
| Order History | Always in sidebar, content gated by module maintenance |
| Warehouse Stations | Always in sidebar, content gated by module maintenance |
| Business Insights | `canAccessFeature(tenantId, 'insights')` must return `true` |
| Tenant Management | `isSuperAdmin(tenantId)` must be `true` |
| System Settings | `isSuperAdmin(tenantId)` must be `true` |

### Module Maintenance in Sidebar

Each sidebar item can have a `maintenanceKey`. If `isModuleUnderMaintenance(key)` returns `true`:
- A ⚠ warning icon appears on the sidebar item
- The content area shows a maintenance placeholder instead of the actual screen
- Super admins bypass this and see the actual content

### Feature Gating for Insights

```dart
TenantService().canAccessFeature(_currentConfig.tenantId ?? '', 'insights')
    ? const BusinessInsightsScreen()
    : _buildFeatureLockedMessage()  // Premium upsell message
```

---

## 14. Home Screen Routing

**File:** `lib/features/home/presentation/screens/home_screen.dart`

The home screen is the app's root (`'/'`) and serves as a router based on tenant state:

```
HomeScreen (FutureBuilder<AppConfiguration>)
   │
   ├── Config loading? → Loading screen (gradient + spinner)
   │
   ├── !isConfigured?
   │   ├── Mobile/Tablet → TenantSetupScreen
   │   └── Desktop/Web   → LoginScreenDesktop
   │
   ├── isConfigured BUT canAccessSystem() == false?
   │   └── MaintenanceScreen
   │
   └── isConfigured AND access allowed
       ├── Mobile  → HomeScreenMobile
       ├── Tablet  → HomeScreenTablet
       ├── Desktop → StaffPanelDesktop
       └── Web     → HomeScreenDesktop
```

---

## 15. Dependency Injection

**File:** `lib/di/injection.dart`

Tenant-related registrations in GetIt:

```dart
// Data Sources
getIt.registerLazySingleton<AuthMockDataSource>(() => AuthMockDataSource());
getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(client: getIt()));

// Repository
getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
  mockDataSource: getIt<AuthMockDataSource>(),
  remoteDataSource: getIt<AuthRemoteDataSource>(),
));

// BLoC
getIt.registerFactory(() => AuthBloc(
  authRepository: getIt<AuthRepository>(),
));

// Configuration
getIt.registerLazySingleton<LocalConfigurationDataSource>(() => LocalConfigurationDataSource());
getIt.registerLazySingleton<ConfigurationRepository>(() => ConfigurationRepositoryImpl(getIt<LocalConfigurationDataSource>()));
```

> **Note:** `TenantService` is **not** registered in GetIt. It uses its own internal singleton pattern. All consumers call `TenantService()` directly to get the shared instance. This is a design choice for simplicity in the current phase.

---

## 16. Key Data Flows (Step-by-Step)

### Flow 1: Fresh App Start → Login → Dashboard

```
1. App starts → main.dart → HomeScreen
2. HomeScreen loads AppConfiguration
3. isConfigured == false → show LoginScreenDesktop
4. User enters email + tenant ID → AuthBloc dispatches LoginRequested
5. AuthBloc → AuthRepositoryImpl → AuthMockDataSource → TenantService.login()
6. Match found → Tenant returned → AuthAuthenticated(tenant) emitted
7. LoginScreenDesktop._onAuthSuccess():
   a. Updates AppConfiguration with tenant details, saves config
   b. tenant.id == 'SUPER_ADMIN'? → StaffPanelDesktop
   c. tenant.lastLogin == null? → TenantSetupScreen
   d. otherwise → StaffPanelDesktop
8. StaffPanelDesktop loads config, checks maintenance, renders sidebar
```

### Flow 2: Super Admin Adds a New Tenant

```
1. Super admin navigates to Super Admin Panel (sidebar item)
2. Clicks "Add Tenant" button in header
3. _showAddTenantDialog() opens with fields:
   - Name, Business Name, Email, Phone
   - Tier dropdown (Standard/Premium)
   - Feature Access checkboxes (orders, history, insights, warehouse)
4. On submit: creates Tenant(status: 'Pending', id: 'TENxxx', ...)
5. TenantService.addTenant() adds to in-memory list
6. UI refreshes via _loadTenants() → setState()
```

### Flow 3: Feature Gating Check for Business Insights

```
1. Tenant clicks "Business Insights" in sidebar
2. StaffPanelDesktop.build() checks:
   a. isModuleUnderMaintenance('insights')? → show placeholder (unless super admin)
   b. canAccessFeature(tenantId, 'insights')?
      - Tenant Active? → continue
      - 'insights' in enabledFeatures? → YES → show BusinessInsightsScreen
      - No? → Tier == Premium? → YES → show BusinessInsightsScreen
      - Otherwise → show "Feature Locked" message
```

### Flow 4: Global Maintenance Mode Toggle

```
1. Super Admin → Settings tab → toggles "Maintenance Mode (Full System)"
2. TenantService.setMaintenanceMode(true)
3. _isMaintenanceMode = true
4. Next time any non-super-admin user's screen rebuilds:
   - home_screen.dart: canAccessSystem() returns false → MaintenanceScreen
   - staff_panel_desktop.dart: build() detects maintenance → MaintenanceScreen
5. Super Admin can still navigate and toggle it off
```

---

## 17. Enhancement Guide

Common enhancements and which files to modify:

### Persist tenants to a database

**Current state:** All tenant data is in-memory (lost on restart).

| Files to Change | What to Do |
|---|---|
| `tenant_service.dart` | Replace `_tenants` list with database calls |
| New: `tenant_remote_datasource.dart` | Create API client for tenant CRUD |
| New: `tenant_local_datasource.dart` | Create local cache (Hive/SQLite) |
| `injection.dart` | Register new data sources |

### Add a new feature module

| Step | File | Change |
|---|---|---|
| 1 | `tenant_service.dart` | Add key to `_moduleMaintenance` map |
| 2 | `super_admin_screen.dart` | Add to `availableFeatures` in both add/edit dialogs |
| 3 | `super_admin_screen.dart` | Add to Module Maintenance settings card |
| 4 | `staff_panel_desktop.dart` | Add sidebar item with `maintenanceKey` and `canAccessFeature` check |
| 5 | New screen widget | Create the feature's screen |

### Move to real authentication (OAuth / JWT)

| Files to Change | What to Do |
|---|---|
| `auth_remote_datasource.dart` | Implement actual token-based auth, store JWT |
| `auth_repository_impl.dart` | Add token refresh logic, persistent login |
| `tenant_service.dart` | Remove `login()` method (move to remote datasource) |
| `login_screen_desktop.dart` | Update password field label from "Client ID" |

### Add tenant-scoped data filtering

The `tenantId` is already on every order. To filter:

| File | Change |
|---|---|
| `order_repository_impl.dart` | Filter orders by `tenantId` from `getCurrentTenant()` |
| `order_usecases.dart` | Pass tenant context through use cases |
| `order_bloc.dart` | Filter loaded orders by tenant before emitting state |

### Add a new tenant status

| File | Change |
|---|---|
| `tenant.dart` | Document the new status value |
| `tenant_service.dart` | Update checks in `canAccessSystem()`, `isTenantEnabled()`, `canAccessFeature()` |
| `super_admin_screen.dart` | Add to status dropdown items in edit dialog |
| `super_admin_screen.dart` | Add color mapping in `_buildTenantCard` |

---

> **Last Updated:** February 2026
> **Codebase Version:** Pre-production (in-memory data, mock mode)

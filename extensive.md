## SSS Kiosk – Multi‑Role Offline/Online POS Suite

This document is an in‑depth walkthrough of the SSS Kiosk codebase (`sss`).  
It explains **what the system does**, **how it is structured**, and **how the main flows work** (startup, authentication, licensing, local server sync, and role‑specific behavior).

---

## 1. High‑Level Overview

- **Purpose**: A **multi‑tenant, multi‑role POS and kiosk system** for retail/food businesses.
- **Key capabilities**:
  - Self‑service **kiosk terminal** for customers.
  - **Staff/Admin panel** for order management and local server hosting.
  - **Warehouse panel** for item/warehouse‑level order fulfillment.
  - **Enterprise dashboard** for analytics and multi‑branch management.
  - **Super admin tools** for global management and tenant control.
  - **Local HTTP server** for tablets/terminals on the same LAN.
  - **Cloud licensing & heartbeat** to remotely control tenant status.
  - **Configurable order status tracking** (order‑level vs item‑level).
- **Architecture**:
  - Flutter app targeting **mobile**, **desktop (esp. Windows)**, and **web**.
  - **State management**: `flutter_bloc`.
  - **Dependency injection**: `get_it`.
  - **Local persistence**: `drift` (SQLite) + `shared_preferences`.
  - **Cloud backend**: Firebase (`firebase_core`, `cloud_firestore`).
  - **Local HTTP server**: `shelf`, `shelf_router`, `shelf_static`.

---

## 2. Technologies & Dependencies

From `pubspec.yaml`:

- **Flutter & UI**
  - `flutter`, `cupertino_icons`, `flutter_svg`
  - Material 3, custom theming (`AppColors`), responsive layouts.
- **State & DI**
  - `flutter_bloc`, `equatable` – BLoC pattern for features.
  - `get_it` – service locator for DI.
- **Data & Networking**
  - `http` – HTTP client.
  - `drift`, `sqlite3_flutter_libs`, `path`, `path_provider` – local DB.
  - `shared_preferences` – lightweight key/value storage (e.g. migration flags, mobile server IP).
  - `universal_io` – platform abstraction.
  - `json_annotation`, `json_serializable`, `freezed` – models & union types.
- **Firebase**
  - `firebase_core`, `cloud_firestore` – licensing, tenant & tier data, heartbeats.
- **Local Server**
  - `shelf`, `shelf_router`, `shelf_static` – HTTP API exposed from desktop builds.
  - `network_info_plus` – determine local IP for LAN clients.
- **Misc**
  - `intl` – formatting.
  - `uuid` – IDs for entities like orders, etc.

Dev dependencies include `flutter_test`, `build_runner`, `drift_dev`, `freezed`, `json_serializable`, `flutter_lints`, `mockito` for testing and code generation.

---

## 3. Application Roles & Entry Points

The app supports **multiple roles**, each compiled into its own executable entrypoint while sharing the same codebase.

### 3.1 Roles (`lib/core/config/app_role.dart`)

`AppRole` defines the available roles:

- `kiosk` – self‑service terminal app for customers.
- `warehouse` – warehouse admin/staff panel.
- `superAdmin` – global super admin console.
- `dashboard` – enterprise analytics dashboard.
- `staff` – staff/admin panel for branches (and master server host).

`RoleConfig` holds:

- `role` – the active `AppRole`.
- `appName` – window title / branding.
- Flags like `showKioskUI`, `showWarehouseUI`, `showAdminUI`, `showDashboardUI`, `showStaffUI` for feature‑level conditionals.

The `RoleConfig.forRole(AppRole role)` factory maps each role to a human‑readable app name and which UI sections should be visible.

### 3.2 Entry Points (`lib/main*.dart`)

All entrypoints delegate to a **single shared bootstrap function** in `main.dart`:

- `lib/main.dart` – **default Kiosk Terminal**:
  - `main()` calls `mainWithRole(AppRole.kiosk)`.
- `lib/main_terminal.dart` – alternative kiosk terminal; functionally same as `main.dart`.
- `lib/main_staff.dart` & `lib/main_branch.dart` – Staff/Admin panel builds:
  - `main()` calls `mainWithRole(AppRole.staff)`.
- `lib/main_warehouse.dart` – Warehouse Admin:
  - `main()` calls `mainWithRole(AppRole.warehouse)`.
- `lib/main_superadmin.dart` – Super Admin console:
  - `main()` calls `mainWithRole(AppRole.superAdmin)`.
- `lib/main_dashboard.dart` – Enterprise dashboard:
  - `main()` calls `mainWithRole(AppRole.dashboard)`.

Each of these builds the same `KFMKioskApp`, but **injects a different `AppRole`** which controls:

- Window title (via `RoleConfig.appName`).
- Which screens are reachable.
- Whether the **local server** is allowed to run.
- Whether certain tenants/tier combinations are valid for that build.

### 3.3 Windows Build Targets (from `Multi-Role-Build-System-Walkthrough.md`)

To generate separate Windows executables:

- **Kiosk Terminal (standard customers):**
  - `flutter build windows --target lib/main.dart`
  - or `flutter build windows --target lib/main_terminal.dart`
- **Staff & Admin Panel:**
  - `flutter build windows --target lib/main_staff.dart`
  - or `flutter build windows --target lib/main_branch.dart`
- **Warehouse Admin:**
  - `flutter build windows --target lib/main_warehouse.dart`
- **Branch Manager (enterprise master server):**
  - `flutter build windows --target lib/main_branch.dart`
- **Enterprise Dashboard:**
  - `flutter build windows --target lib/main_dashboard.dart`
- **Super Admin:**
  - `flutter build windows --target lib/main_superadmin.dart`

**Distribution strategy:**

- **Standard / Premium / Alone tiers**:
  - Kiosk Terminal executable.
  - Staff Panel executable.
- **Enterprise tier**:
  - Kiosk Terminal.
  - Staff Panel / Branch Manager.
  - Warehouse Admin.
  - Enterprise Dashboard.

The **Login screen and `TenantService` enforce that a user can only log into the correct role app**, and mismatches cause an Access Denied message.

---

## 4. Startup & Initialization Flow (`lib/main.dart`)

The core boot logic lives in `mainWithRole(AppRole role)`:

1. **Flutter initialization**
   - `WidgetsFlutterBinding.ensureInitialized()`.

2. **Firebase initialization (non‑Linux)**
   - Uses `Firebase.initializeApp` with `DefaultFirebaseOptions.currentPlatform`.
   - On Linux, Firebase is skipped to avoid configuration issues during desktop dev.

3. **Dependency Injection**
   - `setupDependencies()` wires up `get_it` with all repositories, services, blocs, and data sources.

4. **Role configuration**
   - `final roleConfig = RoleConfig.forRole(role);`
   - Registers a singleton `RoleConfig` in `getIt` for use across the app (e.g. `LoginScreen`, `HomeScreen`, dashboard).

5. **License & configuration checks**
   - `isLicensed` determined by `LicenseService.isLicensed()` from Drift `appConfig` data.
   - `config` loaded via `LocalConfigurationDataSource.getConfiguration()`:
     - Retrieves `AppConfiguration` from SQLite.
     - On first run, migrates from old `SharedPreferences` storage (legacy `_configKey` JSON) into Drift.
   - `isConfigured` computed from `config.isConfigured`.

6. **Start screen selection**

   - **Mobile (Android/iOS)**:
     - Uses `SharedPreferences`:
       - `is_mobile_configured` – whether server IP has been set.
       - `server_ip` – IP address of the local desktop server.
     - Flows:
       - If not configured → `ServerConnectionScreen` to capture server IP.
       - If configured:
         - `ApiConfig.setBaseUrl('http://<ip>:8080')`.
         - `ApiConfig.setFlavor(AppFlavor.prod)`.
         - Starts at `HomeScreen` (mobile kiosk UX, not Login).

   - **Desktop/Web**:
     - Role‑aware logic:
       - `AppRole.superAdmin` → always starts at `LoginScreen` (for security).
       - Other roles:
         - If `isLicensed && isConfigured` → `HomeScreen`.
         - Else → `LoginScreen`.

7. **Cloud heartbeat (non‑Linux)**
   - `CloudHeartbeatService.checkTenantStatus()` is fired **fire‑and‑forget** at startup.
   - See §6 for details.

8. **Local server boot (desktop roles)**
   - If `config.isConfigured && config.tenantId != null`:
     - Determines if the **local HTTP server** should start, based on tier + role:
       - Enterprise tier: **Staff** role hosts the server.
       - Other tiers: **Kiosk or Staff** may host.
     - `LocalServerService.setActiveTenantId(...)` configures the active tenant/branch/warehouse/tier context.
     - If eligible, calls `serverService.start()`, otherwise logs that this build runs purely as **client**.

9. **App bootstrap**
   - `runApp(KFMKioskApp(home: startScreen, roleConfig: roleConfig));`
   - Wraps UI with **multiple BLoC providers**:
     - `ProductBloc` (initial `LoadProducts`).
     - `CartBloc` (initial `LoadCart`).
     - `OrderBloc` (initial `LoadOrders`).
     - `PaymentBloc`.
     - `LanguageCubit`.
     - `AuthBloc` (`AuthCheckRequested` on startup).
   - Configures Material theme (colors, typography, cards, buttons).

---

## 5. Core Domain Concepts

From entities and services, the main domain objects are:

- **Tenant** – a business that subscribes to SSS Kiosk.
  - Fields: `id`, `name`, `businessName`, `email`, `phone`, `tierId`, `status`, `createdDate`, etc.
- **Branch** – physical location under a tenant.
  - Fields: `id`, `tenantId`, `name`, `location`, `managerName`, `contactPhone`, credentials, etc.
- **Warehouse** – sub‑unit under a branch for category‑based order fulfillment.
  - Fields: `id`, `tenantId`, `branchId`, `name`, `categories`, credentials.
- **Tier** – Subscription tier with feature gating.
  - Fields: `id`, `name`, `enabledFeatures`, `allowUpdates`, `immuneToBlocking`, `description`.
- **AppConfiguration** – local configuration for the running instance:
  - `tenantId`, `branchId`, `warehouseId`, `tierId`, `businessName`, `statusTrackingMode`, `isConfigured`, etc.
- **Product** – items available for purchase.
- **Cart & CartItem** – items selected in kiosk.
- **Order** – customer order with metadata, terminal ID, tenant/branch IDs.
- **OrderItem** – line items per order; used heavily for item‑level tracking.

These entities are persisted in **Drift** (`lib/core/database`) and some cached or bootstrapped via **Firestore**.

---

## 6. Cloud Heartbeat & Tier Sync (`CloudHeartbeatService`)

`CloudHeartbeatService` is responsible for **remote tenant status control** and **tier feature sync**.

Main responsibilities:

1. **Early exit on Linux**
   - Skips network checks on Linux (`if (Platform.isLinux) return;`), useful for offline dev.

2. **Get active configuration**
   - Loads the current `AppConfiguration` via `ConfigurationRepository`.
   - Uses `config.tenantId` as the key to Firestore.

3. **Synchronize global tiers**
   - Reads all docs from the Firestore `tiers` collection.
   - Builds `Tier` objects (`id`, `name`, `enabledFeatures`, `allowUpdates`, `immuneToBlocking`, `description`).
   - Updates them through `TenantService.updateTier`.
   - This enables **feature gating** and cloud‑driven config for each tier.

4. **Tenant status check**
   - Fetches the tenant document from `tenants/<tenantId>`.
   - Reads fields:
     - `status` – e.g. `Active`, `Inactive`.
     - `tierId`.
     - `isMaintenanceMode`.
     - `enabledFeatures`, `allowUpdate`, `immuneToBlocking`.
     - `licenseExpiry`.
   - Updates local tenant record via `TenantService.updateTenant`.
   - When `tierId` changes in the cloud, also updates `AppConfiguration.tierId` and persists it.
   - Writes `last_cloud_heartbeat` timestamp into `SharedPreferences`.

5. **License enforcement**
   - If the tenant is **not** on tier `'alone'`:
     - If `licenseExpiry` is past:
       - Invokes `LicenseService.checkCloudLicenseStatus(tenantId)` to sync license state locally.

6. **Offline grace period**
   - `_checkGracePeriod()` uses `last_cloud_heartbeat` to see how long the app has been offline.
   - If offline **more than 7 days**, logs that the grace period has expired.
   - The code comments note that a real production app could enforce a lockout here.

Result: even though the app works offline, it **phones home quickly on startup** to:

- Sync subscription/tier data.
- Respect remote blocking, license expiry, and maintenance.

---

## 7. Licensing (`LicenseService`)

`LicenseService` is a Drift‑backed licensing layer for the app.

### 7.1 Local license state

- Uses `AppDatabase.appConfig` to store:
  - `licenseStatus` (e.g. `active`).
  - `licenseKey`.
  - `lastVerified`.
  - `license_expiry`.
  - `tenant_id`.

Key operations:

- `isLicensed()` – checks `licenseStatus == 'active'`.
- `isExpired()` – reads and parses `license_expiry`, compares to `DateTime.now()`.

### 7.2 Cloud license verification

- `verifyLicense(String key)`:
  - Skips on Linux (returns `true`) to simplify dev.
  - Queries Firestore `licenses` collection:
    - Where `key == <key>` and `status == 'pending'`.
  - On a match:
    - Reads `tenantId` and `expiresAt`.
    - Sets license doc to `status: 'active'` and attaches `activatedAt`.
    - Calls `saveLicense(key, expiresAt, tenantId)` to **persist locally**.
  - Returns `true` on success, `false` on failure.

- `checkCloudLicenseStatus(String tenantId)`:
  - Fetches `tenants/<tenantId>` from Firestore.
  - Updates:
    - `license_expiry` in local DB.
    - `licenseStatus` in local DB.

### 7.3 License management helpers

- `generateLicense()` – produces a human‑readable key like `KFL-XXXXXXXXXXXX` from a restricted character set.
- `clearLicense()` – clears all license‑related appConfig keys (useful for debugging or reset).

Licensing interacts closely with:

- `HomeScreen` (screens a user into maintenance/lockout when expired).
- `CloudHeartbeatService` (remote license blocking).

---

## 8. Local HTTP Server & Sync (`LocalServerService`)

`LocalServerService` exposes a **local REST API on port 8080**.  
It is primarily used when the **desktop acts as a master server** for kiosk tablets/terminals.

### 8.1 Core responsibilities

- Track the **active tenant/branch/warehouse/tier** context for the running desktop instance.
- Host a **REST API** for:
  - Health checks.
  - Initial sync of configuration.
  - Listing products and product images.
  - Pushing/pulling orders.
  - Maintaining per‑tenant counters (e.g. order number).
  - Tracking **connected terminals** via heartbeats.

### 8.2 State & configuration

- `TerminalInfo`:
  - `ip`, `name`, `lastSeen`, `isOnline`.
  - Provides a simplified view of connected kiosk devices.
- `_connectedTerminals`:
  - `Map<String, TerminalInfo>` keyed by client IP.
  - Cleaned regularly by `_cleanupStaleTerminals()`.
- Active context:
  - `_activeTenantId`, `_activeBranchId`, `_activeWarehouseId`, `_activeTierId`.
  - Set by `setActiveTenantId(...)`, usually from **login flows** in `LoginScreen`.

The service is injected with:

- `TenantConfigDao` – tenant configuration.
- `ProductsDao` – product catalog.
- `OrdersDao` – orders and items.
- `AppConfigDao` – general app config (e.g., counters).

### 8.3 Endpoints

Key endpoints (all under `/api/v1`):

- `GET /health`
  - Simple health check (`OK`).

- `GET /sync/init`
  - Valid only when `_activeTenantId` is set; otherwise returns an error JSON.
  - Reads `terminalName` from query parameters.
  - Tracks the calling terminal in `_connectedTerminals`.
  - Responds with:
    - `tenantId`, `branchId`, `warehouseId`, `tierId`.
    - Serialized `TenantConfigModel` (branding, colors, logo path, app name, welcome message) for the active tenant.

- `POST /sync/heartbeat`
  - Body: JSON containing `terminalName`.
  - Extracts client IP, updates `_connectedTerminals[clientIp]` with current `lastSeen`.
  - Responds with `{ "status": "alive" }`.

- `GET /config/<tenantId>`
  - If `tenantId == 'active'`, uses `_activeTenantId`.
  - Retrieves tenant config via `TenantConfigDao`.
  - Returns a serialized `TenantConfigModel` JSON.

- `GET /sync/logo`
  - Serves the tenant’s **logo file** from disk, with appropriate `Content-Type`.
  - Validates that `_activeTenantId` is set and that the logo file exists.

- `GET /products/<tenantId>`
  - Supports `branchId` query param.
  - `tenantId == 'active'` resolves to `_activeTenantId`.
  - `branchId == 'active'` resolves to `_activeBranchId`.
  - Fetches products from `ProductsDao` and serializes them as `ProductModel`.

- `GET /products/images/<filename>`
  - Serves product images from `<app documents>/product_images/<filename>`.
  - Sets `Content-Type` based on extension.

- `GET /orders`
  - Returns all orders stored in the local Drift DB.
  - For each order:
    - Joins items via `OrdersDao.getItemsForOrder`.
    - Builds an `OrderModel` with nested `CartItemModel` and simplified `ProductModel`.

- `POST /orders`
  - Accepts an `OrderModel` JSON payload.
  - Upserts:
    - Order row in `Orders` table.
    - Associated line items in `OrderItems` table (with statuses and categories).
  - Responds with `status: success` and `orderId`.

- `POST /orders/counter`
  - Body: JSON `{ "key": string, "counter": int }`.
  - Writes `counter_<key>` into `AppConfigDao` (used for daily or per‑branch order numbering).

- `GET /orders/counter/<keyOrTenantId>`
  - If `keyOrTenantId == 'active'`, constructs a key from:
    - `_activeTenantId`, `_activeBranchId`, and current date `YYYY-MM-DD`.
    - Example: `tenant_branch_2026-02-27`.
  - Returns `{ "counter": <value> }` from app config.

### 8.4 Lifecycle

- `start()`:
  - Creates a `Router` and registers all routes.
  - Wraps it in a `Pipeline` with `logRequests()` middleware.
  - Serves on `InternetAddress.anyIPv4`, port `8080`.
  - Logs startup/failure messages.

- `stop()`:
  - Closes `_server`, clears `_connectedTerminals`.

This local server is **the bridge between desktop and tablets/kiosks**, enabling LAN‑based sync without requiring constant internet.

---

## 9. Authentication & Access Control

Authentication is handled by BLoC + specialized flows that respect **role‑based entrypoints** and **tier rules**.

### 9.1 `AuthBloc`

Defined in `lib/features/auth/presentation/bloc/auth_bloc.dart`.

- **Events**:
  - `AuthCheckRequested` – check if a tenant session exists.
  - `LoginRequested(email, password)` – attempt login.
  - `LogoutRequested` – clear session.

- **States**:
  - `AuthInitial`, `AuthLoading`, `AuthAuthenticated(Tenant)`, `AuthUnauthenticated`, `AuthFailure(message)`.

- **Behavior**:
  - On `AuthCheckRequested`:
    - If `authRepository.getCurrentTenant()` returns a tenant → `AuthAuthenticated`.
    - Else → `AuthUnauthenticated`.
  - On `LoginRequested`:
    - Calls `authRepository.login(email, password)`.
    - Emits `AuthAuthenticated` on success, `AuthFailure` on errors.
    - Network errors (socket, timeout, client) are mapped to **friendly messages**.
  - On `LogoutRequested`:
    - Calls `authRepository.logout()`.
    - Clears local server context via `localServerService.setActiveTenantId('')`.
    - Emits `AuthUnauthenticated`.

### 9.2 `LoginScreen`

Located in `lib/features/auth/presentation/screens/login_screen.dart`.

Key aspects:

- Uses `TenantService` and `RoleConfig` to enforce **build‑time vs user‑type compatibility**.
- `_handleLogin`:
  - Validates form.
  - Fetches `roleConfig` and `TenantService`.
  - Performs **cloud login**: `tenantService.cloudLogin(email, password, roleConfig.role)`.
  - Cloud response type decides routing:
    - `type == 'tenant'` → build `Tenant` and call `_onAuthSuccess(tenant)`.
    - `type == 'branch'` → build `Branch`, then `_onBranchAuthSuccess(tenant, branch)`.
    - `type == 'warehouse'` → build `Warehouse`, then `_onWarehouseAuthSuccess(warehouse)`.
  - On failure, shows an error about invalid credentials or cloud issues.

- **Success flows**:
  - `_onWarehouseAuthSuccess(Warehouse)`:
    - Fetches associated `Tenant`.
    - Updates `AppConfiguration` with:
      - `tenantId`, `branchId`, `warehouseId`, `tierId`, business contact info.
      - `statusTrackingMode` set to `itemLevel`.
      - `isConfigured = true`.
    - Calls `LocalServerService.setActiveTenantId` with tenant/branch/warehouse/tier.
    - Navigates to `StaffPanelWarehouse`.

  - `_onBranchAuthSuccess(Tenant, Branch)`:
    - Updates `AppConfiguration` with:
      - `tenantId`, `branchId`, `tierId: 'enterprise'`, marks configured.
      - Clears warehouse context.
    - Calls `LocalServerService.setActiveTenantId` with tenant and branch.
    - Navigates to `StaffPanelDesktop`.

  - `_onAuthSuccess(Tenant)`:
    - Determines `isEnterprise` from `tenant.tierId`.
    - Updates `AppConfiguration`:
      - Sets `tenantId`, `tierId`, clears branch context, `isConfigured = true`.
    - Updates `LocalServerService` context.
    - Flows:
      - Super admin (`tenant.id == 'SUPER_ADMIN'`):
        - Forces `isConfigured = true`.
        - Navigates to `HomeScreen` (which branches into SuperAdmin screen).
      - Enterprise tenant:
        - If **first‑time config** → `TenantSetupScreen`.
        - Else → `EnterpriseDashboard`.
      - Non‑enterprise tenant:
        - If first‑time config → `TenantSetupScreen`.
        - Else → `StaffPanelDesktop`.

- **Role/build enforcement (`BlocListener<AuthBloc, AuthState>`)**:
  - If logging in as `SUPER_ADMIN` on a non‑superAdmin build:
    - Shows Access Denied and logs out immediately.
  - If non‑superAdmin tries to log into superAdmin build:
    - Access Denied + logout.
  - If Enterprise Dashboard build (`AppRole.dashboard`) is used by a non‑enterprise tenant:
    - Access Denied + logout.

This guarantees that **only the correct .exe can be used for each user type and tier**.

---

## 10. Home Routing & Maintenance Screens (`HomeScreen`)

`HomeScreen` is the central router after initial checks.

Core flow:

1. Uses `FutureBuilder<AppConfiguration>` via `ConfigurationRepository.getConfiguration()`.
2. Shows a **full‑screen loading scaffold** with gradient and logo until data is ready.
3. Retrieves `RoleConfig` from `getIt`.
4. Special case:
   - If `roleConfig.role == AppRole.superAdmin` → directly returns `SuperAdminScreen`.
5. If configuration is **not** done (`!config.isConfigured`):
   - If role is `kiosk`:
     - Uses `ResponsiveWrapper`:
       - `mobile`: `HomeScreenMobile`.
       - `tablet`: `HomeScreenTablet`.
       - `desktop` / `web`: `LoginScreen`.
   - If role is non‑kiosk (Staff, Warehouse, Dashboard):
     - Goes to `LoginScreen`.
6. After config, checks **license expiration** (except tier `'alone'` and super admins):
   - Uses `LicenseService.isExpired()`.
   - If expired → shows `MaintenanceScreen` with renewal message.
7. Uses `TenantService` and tier info to determine **if the tenant is allowed to access the system**:
   - If not allowed:
     - If tenant `status == 'Inactive'`:
       - Shows `MaintenanceScreen` with “Subscription Expired” messaging.
     - Else:
       - Shows default `MaintenanceScreen` (maintenance or block).
8. **Role‑based routing**:
   - `AppRole.superAdmin` → `SuperAdminScreen`.
   - `AppRole.dashboard` → `EnterpriseDashboard`.
   - `AppRole.warehouse`:
     - If `config.warehouseId` & `config.branchId` set:
       - Fetch warehouses via `WarehouseService`.
       - If matching warehouse is found → `StaffPanelWarehouse` directly.
       - Else → `LoginScreen`.
     - If not configured → `LoginScreen`.
   - `AppRole.staff` → `StaffPanelDesktop`.
   - Default (`kiosk`) → `ResponsiveWrapper` with mobile/tablet/desktop kiosk home UIs.

This ensures:

- **License & subscription enforcement**.
- **Tier‑based access** (enterprise vs standard).
- **Role‑specific UX** from the same codebase.

---

## 11. Configuration & Status Tracking (`ConfigurationScreen`)

`ConfigurationScreen` (`features/settings/presentation/screens/configuration_screen.dart`) lets admins configure **how order status is tracked**.

Main features:

- Loads current `AppConfiguration` via `OrderBloc.configurationRepository`.
- Shows read‑only branch info and license status.
- Exposes a choice between:
  - `StatusTrackingMode.orderLevel` – entire order moves together.
  - `StatusTrackingMode.itemLevel` – items/warehouses can progress independently.

UI details:

- Cards describing **Order‑Level Tracking**:
  - Simple PAID → PREPARING → READY → FULFILLED flow for the whole order.
- Cards describing **Item/Warehouse‑Level Tracking**:
  - Each category/warehouse can be in a separate stage.
  - Better for larger operations with parallel preparation.
- Warning message when switching to **item‑level**:
  - Explains that additional configuration is needed in inventory/warehouse settings.

Persistence:

- `_saveConfiguration`:
  - Reads current config.
  - Overwrites `statusTrackingMode` with selection.
  - Saves via `configurationRepository.saveConfiguration(updatedConfig)`.
  - Triggers `LoadOrders()` to refresh BLoC state.

---

## 12. Feature Modules Overview

The `lib/features` directory is organized by **domain feature**:

- **`auth`**
  - Entities: `Tenant`, `Branch`, `Warehouse`, `Tier`.
  - Data sources: remote auth (cloud login).
  - BLoC: `AuthBloc`.
  - Screens: `LoginScreen`, `ServerConnectionScreen` (mobile config), account disabled, etc.

- **`home`**
  - Screens:
    - `HomeScreen` (router).
    - `HomeScreenMobile`, `HomeScreenTablet`, `HomeScreenDesktop`, `HomeScreenWeb`.
  - Provides entry points into kiosk flows, dashboards, or maintenance screens.

- **`products`**
  - Entities & models: `Product`, `ProductModel`.
  - Data sources: `LocalProductDataSource` + server sync.
  - Repositories & usecases for loading and filtering products.
  - UI widgets: `ProductCard`, lists, etc.

- **`cart`**
  - Entities: `CartItem`.
  - Models: `CartItemModel`.
  - Local storage for current cart state (customer selections).
  - BLoC for adding/removing items, clearing cart, etc.
  - Screens: `CartScreenMobile`, widgets like `CartItemWidget`.

- **`orders`**
  - Entities: `Order`, `OrderFilter`.
  - Data sources: local DB and sync endpoints (`/api/v1/orders`).
  - BLoC: `OrderBloc` with `LoadOrders`, etc.
  - Screens: receipts (`ReceiptScreenDesktop`, `ReceiptScreenTablet`), `StaffPanelDesktop`.
  - Integrates with status tracking configuration.

- **`payment`**
  - Repositories and usecases for payment processing (mock/local).
  - BLoC: `PaymentBloc`.
  - Screens: `PaymentScreenMobile`, `PaymentScreenWeb`.

- **`dashboard`**
  - Enterprise dashboard visualizations:
    - `EnterpriseDashboard`.
    - Widgets like `EnterpriseCharts`, `EnterpriseFeed`.
  - Uses aggregated data from local DB and potentially cloud.

- **`warehouse`**
  - Domain services: `WarehouseService` (DB queries for branch warehouses).
  - Screens:
    - `StaffPanelWarehouse` – station UI.
    - `CatalogScreenDesktop`, `CatalogScreenTablet`, `CatalogScreenMobile`.
    - `InventoryScreen`.
  - Heavily uses item‑level tracking and categories.

- **`settings`**
  - Screens for language selection (`LanguageCubit`), maintenance, and configuration (see above).

- **`admin`**
  - `SuperAdminScreen` – global admin UX.
  - `TenantSetupScreen` – post‑login configuration wizard for tenants.

Each feature follows a standard **clean architecture flavor**:

- `data` – datasources & models.
- `domain` – entities, repositories, usecases, services.
- `presentation` – blocs/cubits, screens, widgets.

---

## 13. Core Layer Structure

The `lib/core` directory is shared across all features:

- **`config`**
  - `app_role.dart` – roles and `RoleConfig`.
  - `api_config.dart` – base URLs and flavors (offline/local vs remote).

- **`configuration`**
  - Domain entities & repositories for `AppConfiguration`.
  - `LocalConfigurationDataSource` – bridging legacy SharedPreferences → Drift.

- **`database`**
  - `app_database.dart` & generated `app_database.g.dart` – Drift schema.
  - DAOs:
    - `tenants_dao`, `tiers_dao`, `branches_dao`, `warehouses_dao`, `products_dao`, `orders_dao`, `cart_dao`, `tenant_config_dao`, `app_config_dao`, etc.

- **`services`**
  - `cloud_heartbeat_service.dart` – remote control & tier sync.
  - `license_service.dart` – license & subscription handling.
  - `local_server_service.dart` – local HTTP server for sync.
  - Other services used across the app (e.g., `insights_service`).

- **`utils`**
  - Validation helpers, shared constants (`AppConstants`, `AppColors`).

- **`widgets`**
  - Shared components for desktop/mobile layouts:
    - `ResponsiveWrapper`.
    - Card widgets for orders, staff views (`ConfigurableOrderCard`, `StaffOrderCard`, `WarehouseOrderCard`).
    - Shared app bars (`MobileAppBar`).

- **`repositories`**
  - Shared abstractions such as `ImageRepository`.

---

## 14. Project Layout Summary

At a glance, the important top‑level Dart files are:

- `lib/main.dart` – shared bootstrap for all roles (`mainWithRole`).
- `lib/main_terminal.dart` – kiosk terminal.
- `lib/main_staff.dart`, `lib/main_branch.dart` – staff/admin/master server builds.
- `lib/main_warehouse.dart` – warehouse console.
- `lib/main_superadmin.dart` – super admin console.
- `lib/main_dashboard.dart` – enterprise dashboard.
- `lib/firebase_options.dart` – Firebase configuration (auto‑generated).
- `lib/core/...` – shared configuration, services, DB, utils, widgets.
- `lib/features/...` – per‑feature modules as described above.

Additionally:

- `Multi-Role-Build-System-Walkthrough.md` – high‑level explanation of the multi‑role build system and Windows build commands.

---

## 15. Running & Building the App

### 15.1 Local development

**Prerequisites:**

- Flutter SDK (version matching the `sdk: ^3.10.1` constraint is recommended).
- A configured Firebase project with Firestore collections:
  - `tenants`, `licenses`, `tiers`, and any other app‑specific collections.
- A local SQLite environment (managed automatically via `sqlite3_flutter_libs`).

**Install dependencies:**

```bash
flutter pub get
```

**Run in debug mode:**

- Default kiosk build:

```bash
flutter run
# or explicitly:
flutter run -t lib/main.dart
```

- Staff panel:

```bash
flutter run -t lib/main_staff.dart
```

- Warehouse:

```bash
flutter run -t lib/main_warehouse.dart
```

- Enterprise dashboard:

```bash
flutter run -t lib/main_dashboard.dart
```

- Super admin:

```bash
flutter run -t lib/main_superadmin.dart
```

### 15.2 Building Windows executables

Use the commands from §3.3 to produce role‑specific `.exe` files.

Example:

```bash
flutter build windows --target lib/main_dashboard.dart
```

### 15.3 Mobile/tablet kiosks

- Desktop/master server must be running with role that is allowed to start `LocalServerService`.
- On mobile:
  - First launch goes to `ServerConnectionScreen`.
  - User enters server IP (the desktop machine); value is persisted in `SharedPreferences`.
  - Mobile client then uses `ApiConfig` to talk to `http://<server-ip>:8080`.

---

## 16. Error Handling & Logging

- Logs are primarily emitted via `debugPrint` (e.g., server startup failures, heartbeat/Firestore errors, license issues).
- Network errors in auth are mapped to **user‑friendly messages**:
  - Socket exceptions, timeouts, and client exceptions produce specific hints about connectivity and network configuration.
- Remote failure scenarios:
  - `CloudHeartbeatService` falls back to local state and checks offline grace period.
  - License expiration triggers UI blocks via `MaintenanceScreen`.
  - Inconsistent tenant/role combos cause Access Denied messages and forced logout.

---

## 17. Extensibility Notes

Based on the current design, the app is straightforward to extend:

- **New roles**:
  - Add a new `AppRole` and corresponding `RoleConfig`.
  - Create a `lib/main_<role>.dart` entrypoint calling `mainWithRole(newRole)`.
  - Adjust login and home routing logic (`LoginScreen`, `HomeScreen`) to support the new role.

- **New feature modules**:
  - Follow the existing `features/<feature>/{data,domain,presentation}` pattern.
  - Wire up `BlocProvider`s in `KFMKioskApp` if globally scoped.

- **New local server routes**:
  - Add endpoints to `LocalServerService.start()` router.
  - Expose them to mobile/tablet clients via appropriate data sources.

- **Additional licensing rules**:
  - Extend `CloudHeartbeatService` and `LicenseService` to handle new fields or rules from Firestore.
  - Update `HomeScreen` routing and `TenantService.canAccessSystem` if new blocking scenarios are added.

This document should give you a solid mental model of how everything fits together—roles, licensing, local server, configuration, and feature modules—so you can confidently modify, debug, and extend the system.


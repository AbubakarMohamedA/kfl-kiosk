# KFL Kiosk — Developer Documentation

> **KFL Kiosk** (package: `kfm_kiosk`) is a cross-platform Flutter self-service kiosk application built for **Kitui Flour Mills (KFM)**. It supports ordering, payment, warehouse fulfilment and multi-tenant management, targeting mobile (Android/iOS), tablet, desktop (Linux/macOS/Windows) and web.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Core Layer](#core-layer)
4. [Feature Modules](#feature-modules)
   - [Auth](#auth)
   - [Products](#products)
   - [Cart](#cart)
   - [Orders](#orders)
   - [Payment](#payment)
   - [Warehouse](#warehouse)
   - [Settings](#settings)
   - [Admin](#admin)
   - [Home](#home)
   - [Insights](#insights)
5. [Dependency Injection](#dependency-injection)
6. [Server (Order Sync)](#server-order-sync)
7. [State Management](#state-management)
8. [Multi-Tenant Architecture](#multi-tenant-architecture)
9. [Responsive Design](#responsive-design)
10. [Data Flow](#data-flow)
11. [Key Dependencies](#key-dependencies)
12. [Running the Project](#running-the-project)
13. [Areas for Improvement](#areas-for-improvement)

---

## Architecture Overview

The project follows **Clean Architecture** with three distinct layers per feature:

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│  (Screens, Widgets, BLoC / Cubit)           │
├─────────────────────────────────────────────┤
│               Domain Layer                   │
│  (Entities, Use Cases, Repository contracts)│
├─────────────────────────────────────────────┤
│                Data Layer                    │
│  (Data Sources, Models, Repository impls)   │
└─────────────────────────────────────────────┘
```

**Key architectural decisions:**
- **BLoC/Cubit** for state management (via `flutter_bloc`).
- **GetIt** for service-locator-style dependency injection.
- **Dual data sources** — every repository implementation can switch between a `Mock` data source and a `Remote` data source based on `ApiConfig.isMockMode`.
- **Multi-tenant isolation** — configuration, orders, and counters are scoped per tenant.
- **Dual status-tracking modes** — order-level (single status per order) vs. item-level (per-item status, enabling warehouse-specific fulfilment).

---

## Project Structure

```
kflkiosk/
├── lib/
│   ├── main.dart                         # App entry point
│   ├── di/
│   │   └── injection.dart                # GetIt DI setup
│   ├── core/                             # Shared utilities & widgets
│   │   ├── config/
│   │   │   └── api_config.dart           # API flavour (mock/prod) & base URL
│   │   ├── configuration/                # App config persistence (multi-tenant)
│   │   │   ├── data/datasources/         # SharedPreferences-based storage
│   │   │   ├── data/repositories/        # ConfigurationRepositoryImpl
│   │   │   └── domain/                   # AppConfiguration entity & contract
│   │   ├── constants/
│   │   │   └── app_constants.dart        # Colours, statuses, i18n strings
│   │   ├── errors/
│   │   │   └── failures.dart             # Custom Failure hierarchy
│   │   ├── platform/
│   │   │   └── platform_info.dart        # Device detection & responsive helpers
│   │   ├── presentation/widgets/
│   │   │   └── responsive_wrapper.dart   # ResponsiveWrapper / ResponsiveBuilder
│   │   ├── services/
│   │   │   └── insights_service.dart     # Business analytics from order data
│   │   ├── usecases/
│   │   │   └── usecase.dart              # Abstract UseCase base classes
│   │   ├── utils/
│   │   │   └── validators.dart           # Phone, email, order-ID validation
│   │   └── widgets/                      # Shared UI components
│   │       ├── common/                   # LanguageSelector, LoadingIndicator
│   │       ├── desktop/                  # StaffOrderCard, WarehouseOrderCard,
│   │       │                             # ConfigurableOrderCard
│   │       └── mobile/                   # MobileAppBar
│   └── features/                         # Feature modules (Clean Architecture)
│       ├── admin/                        # Super-admin & tenant setup
│       ├── auth/                         # Authentication & tenant services
│       ├── cart/                         # Shopping cart
│       ├── home/                         # Home screens (per platform)
│       ├── insights/                     # Analytics dashboards
│       ├── orders/                       # Order CRUD & staff panel
│       ├── payment/                      # Payment processing
│       ├── settings/                     # Language & maintenance
│       └── warehouse/                    # Warehouse fulfilment panel
├── server/
│   └── order_server.dart                 # Local HTTP server for device sync
├── assets/                               # Images, icons, SVGs
├── android/, ios/, linux/, macos/, windows/  # Platform runners
└── pubspec.yaml                          # Dependencies & assets
```

---

## Core Layer

### `core/config/api_config.dart`

Manages API flavour switching and URL construction.

| Property / Method  | Purpose |
|-|-|
| `ApiConfig.flavor`  | `mock` (in-memory) or `prod` (HTTP) |
| `ApiConfig.baseUrl`  | Remote server URL (default `http://localhost:8080`) |
| `ApiConfig.isMockMode` | Quick check for data-source branching |
| `ordersEndpoint`, `productsEndpoint`, `authEndpoint` | Composed endpoint paths |

### `core/configuration/` — App Configuration (Multi-Tenant)

| File | Purpose |
|-|-|
| `domain/entities/app_configuration.dart` | `AppConfiguration` — tenant ID, business name, currency, logo, dark-mode, language, `StatusTrackingMode` (order-level / item-level), enabled features, maintenance mode, contact info. Supports `copyWith`, `toJson`, `fromJson`. |
| `domain/repositories/configuration_repository.dart` | Contract: `getConfiguration()`, `saveConfiguration()` |
| `data/datasources/local_configuration_datasource.dart` | Reads/writes JSON to `SharedPreferences` (key scoped per tenant) |
| `data/repositories/configuration_repository_impl.dart` | Delegates to local data source |

### `core/constants/app_constants.dart`

Defines app-wide constants used throughout the codebase:

- **App info** — name, version
- **Order statuses** — `PAID`, `PREPARING`, `READY_FOR_PICKUP`, `FULFILLED`
- **Language codes** — `en`, `sw` (English, Swahili)
- **Responsive breakpoints** — mobile < 600, tablet < 1024, desktop ≥ 1024
- **Colours** (`AppColors`) — `primaryBlue`, `successGreen`, `warningOrange`, `errorRed`, `textDark`, `textLight`, `backgroundLight`
- **i18n map** — `AppStrings.get(key, languageCode)` returns localised text

### `core/errors/failures.dart`

A sealed hierarchy of `Failure` classes extending `Equatable`:

`Failure` → `ServerFailure` | `CacheFailure` | `NetworkFailure` | `ProductNotFoundFailure` | `CartFailure` | `CartEmptyFailure` | `OrderCreationFailure` | `OrderNotFoundFailure` | `PaymentFailure` | `PaymentTimeoutFailure` | `ValidationFailure` | `UnknownFailure`

### `core/platform/platform_info.dart`

- `PlatformInfo` — static booleans (`isWeb`, `isMobile`, `isDesktop`, `isAndroid`, `isIOS`, etc.) and `getDeviceType(width)` returning `DeviceType` enum.
- `ResponsiveUtils` — helper methods for responsive font sizes, padding, and grid columns.

### `core/presentation/widgets/responsive_wrapper.dart`

- `ResponsiveWrapper` — renders the appropriate child widget (`mobile`, `tablet`, `desktop`, `web`) based on `PlatformInfo.getDeviceType`.
- `ResponsiveBuilder` — callback-based variant.
- `ResponsiveExtension` — `BuildContext` extension with `.isMobile`, `.isTablet`, etc.

### `core/services/insights_service.dart`

Pure-logic service that analyses `List<Order>` data:

| Method | Returns |
|-|-|
| `calculateTotalRevenue` | Sum of all order totals |
| `getWeeklyRevenueTrend` | `Map<dayLabel, revenue>` for last 7 days |
| `calculatePeakHours` | Orders grouped by hour |
| `getTopSellingProducts` | Top N products by revenue |
| `calculateAverageBasketSize` | Avg items per order |
| `getPopularCombinations` | Frequently co-purchased products |
| `calculateAverageFulfillmentTime` | Simulated (actual field not yet in `Order`) |
| `calculateEfficiencyScore` | Composite score 0–100 |
| `getCategoryPerformance` | Revenue per product category |
| `generateAlerts` | Advisory alerts based on trends |

### `core/usecases/usecase.dart`

Three abstract base classes:
- `UseCase<ReturnType, Params>` — standard async use case
- `UseCaseNoParams<ReturnType>` — no-param variant
- `StreamUseCaseNoParams<ReturnType>` — returns `Stream`

### `core/utils/validators.dart`

Static validation methods for:
- Kenyan phone numbers (07XX/01XX, 10 digits)
- Order IDs (format `ORD-XXXX`)
- Quantities, prices, payment amounts (positive, non-zero)
- Product IDs, emails
- Input sanitisation

### `core/widgets/`

| Widget | Location | Purpose |
|-|-|-|
| `LanguageSelector` | `common/` | EN / SW toggle buttons using `LanguageCubit` |
| `LoadingIndicator` | `common/` | Spinner with optional message |
| `KFMLoadingOverlay` | `common/` | Full-screen loading overlay |
| `MobileAppBar` | `mobile/` | Custom AppBar with cart badge from `CartBloc` |
| `StaffOrderCard` | `desktop/` | Order card for order-level tracking mode |
| `WarehouseOrderCard` | `desktop/` | Order card for item-level / warehouse tracking mode |
| `ConfigurableOrderCard` | `desktop/` | Dynamically renders `StaffOrderCard` or `WarehouseOrderCard` based on `AppConfiguration.statusTrackingMode` |

---

## Feature Modules

### Auth

**Purpose:** Login, logout, tenant management, feature gating.

#### Domain

| File | Description |
|-|-|
| `entities/user.dart` | `User` — `id`, `username`, `role`, `token`. Uses `Equatable`. |
| `entities/tenant.dart` | `Tenant` — `id`, `name`, `businessName`, `email`, `phone`, `status`, `tier` (`TenantTier.standard/premium`), `createdDate`, `lastLogin`, `ordersCount`, `revenue`, `isMaintenanceMode`, `enabledFeatures`, `maintenanceModules`. Supports `copyWith`. |
| `repositories/auth_repository.dart` | Contract: `login(username, password)` → `Tenant`, `logout()`, `getCurrentTenant()` → `Tenant?` |
| `services/tenant_service.dart` | **Singleton** mock service managing an in-memory tenant list. Provides CRUD, feature-gating by tier, global/module maintenance mode, `login(email, tenantId)`, `isSuperAdmin()`, `canAccessSystem()`, `canAccessModule()`. Contains 4 hardcoded tenants including a `SUPER_ADMIN`. |

#### Data

| File | Description |
|-|-|
| `datasources/auth_mock_datasource.dart` | Delegates to `TenantService.login()` with 1s simulated delay |
| `datasources/auth_remote_datasource.dart` | HTTP POST to `/auth/login` & `/auth/logout`, parses JSON to `Tenant` |
| `repositories/auth_repository_impl.dart` | Switches between mock/remote based on `ApiConfig.isMockMode`. Caches current tenant in memory. |

#### Presentation

| File | Description |
|-|-|
| `bloc/auth_bloc.dart` | `AuthBloc` — handles `LoginRequested`, `LogoutRequested`. States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(tenant)`, `AuthFailure(message)`. |
| `screens/login_screen_desktop.dart` | Two-panel desktop login (branding left, form right). Email + Client/Tenant ID fields. Routes to `TenantSetupScreen` on first login, `StaffPanelDesktop` on subsequent logins. Super-admin goes directly to staff panel. Includes "Clear Local Data (Dev)" button. |
| `screens/account_disabled_screen.dart` | Shown when a tenant account is disabled. Clears config and orders on logout. |

---

### Products

**Purpose:** Product catalogue browsing and search.

#### Domain

| File | Description |
|-|-|
| `entities/product.dart` | `Product` — `id`, `name`, `brand`, `price`, `size`, `category`, `description`, `imageUrl`. Supports `toMap`, `fromMap`, `copyWith`. |
| `repositories/product_repository.dart` | Contract: `getAllProducts`, `getCategories`, `getProductById`, `getProductsByCategory`, `searchProducts`, `getProductsByBrand`, `getBrands`, `getProductsByPriceRange`. |
| `usecases/product_usecases.dart` | `GetAllProducts`, `GetCategories`, `GetProductsByCategory`, `GetProductById` |

#### Data

| File | Description |
|-|-|
| `datasources/local_product_datasource.dart` | In-memory list of 13 hardcoded KFM products (flour variants: Unga Wa Dola, Jahazi, Ziwa Premium, Chenga, Dola Gold, bakers flour, and Golden Drop cooking oil). Supports add/update/delete in memory. |
| `datasources/product_remote_datasource.dart` | Implements the `ProductDataSource` interface for remote fetching. |
| `models/product_model.dart` | Data transfer model extending `Product`. |
| `repositories/product_repository_impl.dart` | Delegates to local/remote data source. |

#### Presentation

| File | Description |
|-|-|
| `bloc/product/product_bloc.dart` | Events: `LoadProducts`, `FilterProductsByCategory`, `SearchProducts`, `LoadCategories`. States: `ProductInitial`, `ProductLoading`, `ProductLoaded(products, filteredProducts, categories, selectedCategory)`, `ProductError`. In-memory search filtering by name, brand, category, description. |
| Screens | `product_screen_mobile.dart`, `product_screen_desktop.dart`, `home_screen_desktop.dart` (product grid) |

---

### Cart

**Purpose:** Shopping cart management.

#### Domain

| File | Description |
|-|-|
| `entities/cart_item.dart` | `CartItem` — wraps `Product` + `quantity` + `status` (defaults to `PAID`). Computed `subtotal`. Methods: `copyWith`, `incrementQuantity`, `decrementQuantity`, `toMap`, `fromMap`. |
| `entities/cart.dart` | Aggregate cart entity. |
| `repositories/cart_repository.dart` | Contract: `addToCart`, `removeFromCart`, `updateQuantity`, `getCartItems`, `clearCart`, `getCartTotal`. |
| `usecases/cart_usecases.dart` | `AddToCart`, `RemoveFromCart`, `UpdateCartQuantity`, `GetCartItems`, `ClearCart`, `GetCartTotal`. |

#### Data

| File | Description |
|-|-|
| `datasources/local_cart_datasource.dart` | In-memory cart storage. |
| `models/cart_item_model.dart` | JSON-serialisable model (uses `json_annotation`). |
| `repositories/cart_repository_impl.dart` | Standard delegation to data source. |

#### Presentation

| File | Description |
|-|-|
| `bloc/cart/cart_bloc.dart` | Events: `AddToCartEvent`, `RemoveFromCartEvent`, `UpdateQuantityEvent`, `ClearCartEvent`, `LoadCartEvent`. States: `CartInitial`, `CartLoading`, `CartLoaded(items, total)`, `CartError`. |
| `screens/cart_screen_mobile.dart` | Mobile cart view with item list and checkout. |
| `widgets/cart_item_widget.dart` | Individual cart item display with quantity controls. |

---

### Orders

**Purpose:** Order lifecycle — create, track, filter, sort, fulfil.

#### Domain

| File | Description |
|-|-|
| `entities/order.dart` | `Order` — `id`, `items: List<CartItem>`, `total`, `phone`, `timestamp`, `status`, `tenantId?`. Rich methods: `setAllItemsStatus`, `getItemsForWarehouse(category)`, `getWarehouseStatus(category)`, `warehouseItemsHaveStatus`, `updateWarehouseItemsStatus`, `overallStatus` (computed from items), `getEffectiveStatus(config)` (order-level vs item-level), `isActive(config)`, `toMap`, `fromMap`. |
| `entities/order_filter.dart` | Filter criteria object. |
| `repositories/order_repository.dart` | Contract: `createOrder`, `getAllOrders`, `getOrderById`, `updateOrderStatus`, `saveFullOrder`, `watchOrders` (stream), `getOrderCounter`, `incrementOrderCounter`. |
| `usecases/order_usecases.dart` | `CreateOrder`, `GetAllOrders`, `GetOrderById`, `UpdateOrderStatus`, `SaveFullOrder`, `WatchOrders`, `GenerateOrderId` (tenant-prefixed: `TEN001-ORD0001`). |

#### Data

| File | Description |
|-|-|
| `datasources/local_order_datasource.dart` | In-memory storage with `StreamController` for `watchOrders`. Tenant-scoped counters (`tenantId_yyyyMMdd` → count). |
| `datasources/order_remote_datasource.dart` | HTTP client communicating with the order sync server. |
| `models/order_model.dart` | JSON-serialisable order model. |
| `repositories/order_repository_impl.dart` | Switches mock/remote. Delegates order persistence. |

#### Presentation

| File | Description |
|-|-|
| `bloc/order/order_bloc.dart` | 436 lines. Handles: `LoadOrders`, `CreateOrder`, `UpdateOrderStatus`, `UpdateWarehouseItemsStatus`, `SearchOrders`, `FilterOrdersByStatus`, `FilterOrders`, `SortOrders`, `WatchOrdersStarted`, `OrdersUpdated`, `ClearOrders`. Exposes `configurationRepository` for tenant config access. |
| `bloc/order/order_event.dart` | All event classes with `Equatable`. |
| `bloc/order/order_state.dart` | `OrdersLoaded` includes warehouse-specific helper methods (`getWarehouseActiveOrders`, `getWarehouseFulfilledOrders`, `getWarehouseItemCountByStatus`, etc.). |
| `screens/staff_panel_desktop.dart` | **Main desktop hub** (2681 lines). Sidebar navigation: Dashboard, Order History, Settings, Warehouse Selector, Business Insights, Super Admin. Contains order management, analytics overview, notification system, logout flow. `ScreenType` enum drives content switching. Role-based sidebar visibility (Manager vs Super Admin). |
| `screens/receipt_screen_*.dart` | Receipt display per platform (mobile, tablet, desktop, web). |
| `widgets/order_status_badge.dart` | Colour-coded status badge widget. |

---

### Payment

**Purpose:** Payment processing (M-Pesa style).

#### Domain

| File | Description |
|-|-|
| `repositories/payment_repository.dart` | Contract: `processPayment(phoneNumber, amount, orderId)` → `bool`, `getPaymentStatus(transactionId)` → `String`. |
| `usecases/payment_usecases.dart` | `ProcessPayment(ProcessPaymentParams)`, `GetPaymentStatus(transactionId)`. |

#### Data

| File | Description |
|-|-|
| `datasources/mock_payment_datasource.dart` | Simulates M-Pesa payment with delay; always succeeds. |
| `repositories/payment_repository_impl.dart` | Standard delegation. |

#### Presentation

| File | Description |
|-|-|
| `bloc/payment/payment_bloc.dart` | Handles `ProcessPaymentEvent`. States: `PaymentInitial`, `PaymentProcessing`, `PaymentSuccess`, `PaymentFailure`. |
| `screens/payment_screen_mobile.dart` | Mobile payment UI with phone number entry. |
| `screens/payment_screen_desktop.dart` | Desktop payment UI. |

---

### Warehouse

**Purpose:** Warehouse-specific order fulfilment with per-item status tracking.

#### Presentation

| File | Description |
|-|-|
| `screens/staff_panel_warehouse.dart` | 1415-line warehouse panel. Defines `Warehouse` enum (flour, premiumFlour, bakerFlour, cookingOil) with `WarehouseExtension` (display names, icons, colours, category matching). Features: dashboard stats per warehouse, active/fulfilled order views, search & filter bar, order history with date grouping, real-time auto-refresh timer. |

**Warehouse-product mapping:**
| Warehouse | Categories |
|-|-|
| Flour | `Flour` |
| Premium Flour | `Premium Flour` |
| Bakers Flour | `Bakers Flour` |
| Cooking Oil | `Cooking Oil` |

---

### Settings

**Purpose:** Language selection and maintenance mode.

| File | Description |
|-|-|
| `bloc/language/language_cubit.dart` | `LanguageCubit` — manages `LanguageState(languageCode)`. Methods: `changeLanguage`, `toggleLanguage`, `setEnglish`, `setSwahili`. |
| `bloc/language/language_state.dart` | `LanguageState` with `isEnglish` / `isSwahili` getters. |
| `screens/maintenance_screen.dart` | Shown when tenant system access is blocked (global or module maintenance mode). |
| `screens/settings_screen_desktop.dart` | Desktop settings panel (language, theme config, etc.). |

---

### Admin

**Purpose:** Tenant management and system administration.

| File | Description |
|-|-|
| `screens/super_admin_screen.dart` | 1299-line super-admin console. Tabs: Tenant List, Analytics, Settings. CRUD dialogs for tenant management (add/edit/delete/details). Header stats (total tenants, active, premium, total revenue). Sidebar navigation. |
| `screens/tenant_setup_screen.dart` | First-time setup wizard for new tenants. |
| `screens/staff_management_screen.dart` | Staff/employee management interface. |

---

### Home

**Purpose:** App entry routing based on configuration and platform.

| File | Description |
|-|-|
| `screens/home_screen.dart` | **Root router.** Uses `FutureBuilder` to load `AppConfiguration`. Routes: unconfigured → `TenantSetupScreen` (mobile/tablet) or `LoginScreenDesktop` (desktop/web). Configured → checks maintenance mode via `TenantService.canAccessSystem()` → `MaintenanceScreen` or platform-specific home. |
| `screens/home_screen_mobile.dart` | Mobile product catalogue with categories. |
| `screens/home_screen_tablet.dart` | Tablet-optimised layout. |
| `screens/home_screen_desktop.dart` | Desktop product browsing (used as kiosk display). |
| `screens/home_screen_web.dart` | Web variant. |

---

### Insights

**Purpose:** Business analytics and reporting.

| File | Description |
|-|-|
| `screens/analytics_screen.dart` | 1302-line analytics dashboard. Tabs: Overview, Sales, Products, Customers. KPI cards (revenue, orders, avg basket, fulfilment time). Sales chart, peak hours analysis, top products, recent transactions. Period selector (today/week/month/custom). |
| `screens/business_insights_screen.dart` | Alternative/complementary insights view leveraging `InsightsService`. |

---

## Dependency Injection

**File:** `lib/di/injection.dart`

Uses `GetIt` to register all dependencies at app startup via `setupDependencies()`:

```
Registration order:
1. Data Sources (local + remote)
2. Repositories (depend on data sources)
3. Use Cases (depend on repositories)
4. BLoCs & Cubits (depend on use cases)
5. Configuration Repository (standalone)
```

| Registration | Type | Dependencies |
|-|-|-|
| `LocalProductDataSource` | Singleton | — |
| `ProductRepositoryImpl` | Singleton | `LocalProductDataSource` |
| `GetAllProducts`, `GetCategories`, etc. | Factory | `ProductRepository` |
| `ProductBloc` | Factory | Use cases |
| `LocalCartDataSource` | Singleton | — |
| `CartRepositoryImpl` | Singleton | `LocalCartDataSource` |
| `CartBloc` | Factory | Cart use cases |
| `LocalOrderDataSource` | Singleton | — |
| `OrderRepositoryImpl` | Singleton | `LocalOrderDataSource` |
| `OrderBloc` | Factory | Order use cases + `ConfigurationRepository` |
| `MockPaymentDataSource` | Singleton | — |
| `PaymentBloc` | Factory | Payment use cases |
| `LanguageCubit` | Factory | — |
| `AuthMockDataSource`, `AuthRemoteDataSource` | Singleton | — |
| `AuthBloc` | Factory | `AuthRepository` |
| `ConfigurationRepository` | Singleton | `SharedPreferences` |

---

## Server (Order Sync)

**File:** `server/order_server.dart`

A standalone Dart HTTP server for cross-device order synchronisation.

**Run:** `dart run server/order_server.dart`

**Listens on:** `0.0.0.0:8080` (all IPv4 interfaces)

| Endpoint | Method | Description |
|-|-|-|
| `/orders` | `GET` | List all orders + counters |
| `/orders` | `POST` | Add or upsert an order |
| `/orders/:id` | `PUT` | Partial update an order |
| `/orders/:id` | `DELETE` | Delete an order |
| `/orders` | `DELETE` | Clear all orders |
| `/orders/counter` | `GET` | Get order counters |
| `/orders/counter` | `POST` | Set counter (tenant-scoped or global) |
| `/health` | `GET` | Health check with order count |

**Storage:** In-memory (`List<Map>` for orders, `Map<String, int>` for tenant-scoped counters). Data is lost on server restart.

**CORS:** Fully enabled for all origins/methods.

---

## State Management

The app uses **BLoC** (Business Logic Component) pattern via `flutter_bloc`:

| BLoC / Cubit | Feature | Key States |
|-|-|-|
| `ProductBloc` | Products | `ProductLoaded(products, filteredProducts, categories)` |
| `CartBloc` | Cart | `CartLoaded(items, total)` |
| `OrderBloc` | Orders | `OrdersLoaded(orders, filteredOrders, filter, sort)` |
| `PaymentBloc` | Payment | `PaymentProcessing`, `PaymentSuccess`, `PaymentFailure` |
| `LanguageCubit` | Settings | `LanguageState(languageCode)` |
| `AuthBloc` | Auth | `AuthAuthenticated(tenant)`, `AuthFailure(message)` |

All BLoCs are provided via `MultiBlocProvider` in `main.dart`.

---

## Multi-Tenant Architecture

Multi-tenancy is implemented across several layers:

1. **`Tenant` entity** — each business/client is a tenant with tier, features, and maintenance settings.
2. **`TenantService`** — singleton managing the tenant registry (in-memory, hardcoded mock data).
3. **`AppConfiguration`** — stores `tenantId`, `businessName`, `contactEmail`, `contactPhone`, `enabledFeatures`, `isMaintenanceMode`, `statusTrackingMode`.
4. **Per-tenant config persistence** — configuration keys in `SharedPreferences` are scoped by tenant ID.
5. **Tenant-scoped order IDs** — format `TENANTID-ORD0001`, with counters keyed by `tenantId_yyyyMMdd`.
6. **Feature gating** — `TenantService.hasFeatureAccess(tenantId, feature)` checks tier + enabled features.
7. **Maintenance mode** — global and per-module; checked at app startup and sidebar item level.

### Tenant Tiers

| Tier | Features |
|-|-|
| Standard | `orders`, `products`, `basic_analytics` |
| Premium | Standard + `warehouse`, `advanced_analytics`, `staff_management`, `api_access` |

---

## Responsive Design

The app renders platform-appropriate UIs:

| Device Type | Breakpoint | Home Screen | Key Differences |
|-|-|-|-|
| Mobile | width < 600 | `HomeScreenMobile` | Bottom nav, mobile app bar with cart badge |
| Tablet | 600 ≤ width < 1024 | `HomeScreenTablet` | Two-column layout |
| Desktop | width ≥ 1024 | `StaffPanelDesktop` | Sidebar + main content + right panel |
| Web | `kIsWeb` | `HomeScreenDesktop` | Desktop-like layout |

**Implementation:**
- `ResponsiveWrapper` dispatches to platform widgets.
- `PlatformInfo.getDeviceType(width)` returns `DeviceType` enum.
- `ResponsiveUtils` provides adaptive font sizes, padding, grid columns.

---

## Data Flow

### Order Creation Flow (Mobile → Server → Desktop)

```
Mobile Kiosk                    Server                     Desktop Staff Panel
─────────────                   ──────                     ───────────────────
1. Browse products
2. Add to cart (CartBloc)
3. Enter phone number
4. Process payment (PaymentBloc)
5. Create order (OrderBloc)
   ├─ GenerateOrderId           
   │  (tenant-prefixed)         
   ├─ POST /orders ────────────→ Store in memory
   │                                    │
   │                            ←──── GET /orders  ────── 6. WatchOrders / LoadOrders
   │                                                      7. Display in StaffPanelDesktop
   │                                                      8. Update status (PAID→PREPARING
   │                              PUT /orders/:id  ←────      →READY→FULFILLED)
   │                            Update in memory          9. WarehousePanel per-item fulfilment
   └─ Show receipt
```

### Status Lifecycle

```
PAID → PREPARING → READY_FOR_PICKUP → FULFILLED
```

In **item-level mode**, each `CartItem.status` progresses independently per warehouse. The `Order.overallStatus` is computed from the "lowest" item status.

---

## Key Dependencies

| Package | Version | Purpose |
|-|-|-|
| `flutter` | SDK | Core framework |
| `flutter_bloc` | ^8.1.6 | State management |
| `get_it` | ^8.0.3 | Dependency injection |
| `equatable` | ^2.0.7 | Value equality for entities/states |
| `http` | ^1.2.2 | HTTP client for API calls |
| `shared_preferences` | ^2.3.4 | Local key-value persistence |
| `intl` | ^0.19.0 | Date/time formatting |
| `uuid` | ^4.5.1 | Unique ID generation |
| `firebase_core` | ^3.12.1 | Firebase integration (initialised but limited use) |
| `json_annotation` / `json_serializable` | ^4.9.0 | JSON serialisation code generation |
| `build_runner` | ^2.4.14 | Code generation runner |
| `dartz` | ^0.10.1 | Functional programming (`Either`) |
| `flutter_svg` | ^2.0.17 | SVG rendering |
| `universal_io` | ^2.2.2 | Platform-agnostic IO |

---

## Running the Project

### Prerequisites
- Flutter SDK (3.x+)
- Dart SDK (3.x+)

### Development

```bash
# Install dependencies
flutter pub get

# Generate JSON serialisation code
dart run build_runner build --delete-conflicting-outputs

# Run the app (desktop)
flutter run -d linux    # or macos, windows

# Run the app (mobile)
flutter run -d <device_id>

# Run the app (web)
flutter run -d chrome
```

### Order Sync Server

```bash
# Start the local sync server (required for cross-device order sync)
dart run server/order_server.dart

# Server listens on 0.0.0.0:8080
# Configure the app's ApiConfig.baseUrl to point to the server IP
```

### Mock vs Production Mode

Toggle `ApiConfig.flavor` in `lib/core/config/api_config.dart`:
- `mock` — uses in-memory data sources (default for development)
- `prod` — uses HTTP data sources communicating with the sync server

---

## Areas for Improvement

| Area | Detail |
|-|-|
| **Tenant persistence** | `TenantService` uses a hardcoded in-memory list. Should migrate to database or remote API. |
| **Fulfillment time tracking** | `Order` model lacks `fulfilledTime` field; `InsightsService` simulates metrics. |
| **Real payment integration** | `MockPaymentDataSource` always succeeds. Needs M-Pesa API integration. |
| **Server persistence** | `order_server.dart` stores data in-memory. Production needs database backing. |
| **Error handling** | `Failure` hierarchy exists but is not consistently used via `Either` across all repositories. |
| **Testing** | No unit/widget/integration tests discovered in the explored codebase. |
| **Firebase usage** | `firebase_core` is initialised but no Firebase services (Firestore, Auth, etc.) are actively used. |
| **Security** | No token-based auth enforcement; password field is tenant ID in mock mode. |
| **Code generation** | Some `.g.dart` files exist but not all models consistently use `json_serializable`. |
| **Super Admin hardcoding** | Super Admin is identified by literal `SUPER_ADMIN` ID string. Should use role-based checks. |

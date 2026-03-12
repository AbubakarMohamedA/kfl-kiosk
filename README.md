# KFM Self-Service Kiosk 🏪

<div align="center">

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Architecture](https://img.shields.io/badge/architecture-Clean%20%2B%20BLoC-orange)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**An enterprise-grade, multi-tenant self-service kiosk solution for SSS**

[Features](#-features) • [Architecture](#-architecture) • [Local Sync](#-local-sync-system) • [Installation](#-installation) • [Super Admin](#-super-admin-panel)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-features)
  - [Customer Experience](#customer-experience)
  - [Staff Operations](#staff-operations)
  - [Enterprise Capabilities](#enterprise-capabilities)
- [Architecture & Tech Stack](#-architecture)
  - [Clean Architecture](#clean-architecture)
  - [State Management](#state-management)
  - [Dependency Injection](#dependency-injection)
- [Local Sync System](#-local-sync-system)
  - [How It Works](#how-it-works)
  - [Server Setup](#server-setup)
- [Super Admin Panel](#-super-admin-panel)
- [Project Structure](#-project-structure)
- [Installation & Setup](#-installation)
- [Configuration](#-configuration)
- [Testing & Deployment](#-testing--deployment)

---

## 🎯 Overview

The **KFM Self-Service Kiosk** is a robust point-of-sale ecosystem designed to streamline operations for SSS and its distributors. Unlike traditional standalone kiosks, this system is built with **Multi-Tenancy** at its core, allowing a single codebase to serve multiple business entities (Tenants) with strict data isolation.

It features a **Local Synchronization Engine** that enables multiple devices (e.g., a customer-facing kiosk and a staff processing unit) to communicate and sync orders in real-time over a local network, ensuring business continuity even without an active internet connection.

### Key Highlights

- 🌍 **Bilingual Support**: Instant switching between English and Kiswahili.
- 🏢 **Multi-Tenant Architecture**: Data isolation and feature gating per tenant.
- 🔄 **Offline-First Local Sync**: Peer-to-peer order synchronization via a local HTTP server.
- 👮 **Super Admin Access**: Global system management, tenant provisioning, and maintenance controls.
- 💳 **M-Pesa Integration**: Seamless mobile money payments with validation.
- 📊 **Real-Time Analytics**: Live insights into revenue, order volume, and staff performance.

---

## ✨ Features

### Customer Experience

#### 🛒 Smart Product Catalog
- **Visual Browsing**: High-quality product imagery with filtered categories (Flour, Oil, Premium).
- **Cart Management**: Real-time cart updates, quantity adjustments, and persistence.
- **Search & Filter**: Rapid product discovery by name, brand, or size.

#### 💳 Seamless Payments
- **M-Pesa Integration**: Validated phone number entry for mobile money payments.
- **Reference Generation**: Automatic generation of unique, human-readable Order IDs (e.g., `ORD0001`).
- **Digital Receipts**: Instant on-screen confirmation with auto-dismiss timers.

### Staff Operations

#### 📱 Command Center
- **Order Dashboard**: Kanban-style view of Active, Preparing, and Ready orders.
- **Status Management**: One-tap status progression (Paid -> Preparing -> Ready -> Fulfilled).
- **Search & Filter**: Find orders instantly by ID, phone number, or status color codes.

#### 📊 Business Intelligence
- **Live Metrics**: Real-time tracking of Today's Revenue, Order Counts, and Average Order Value.
- **Performance Charts**: Visual hourly trends to identify peak business hours.

### Enterprise Capabilities

#### 🏢 Multi-Tenancy
- **Tenant Isolation**: Each business unit (distributor/shop) sees only their data.
- **Tiered Access**: Support for `Standard` and `Premium` tiers, gating advanced features like Analytics.
- **Branding**: Tenant-specific business names and profiles.

#### 👮 Super Admin Control
- **Tenant Management**: Create, Edit, Suspend, or Delete tenant accounts.
- **Global Maintenance**: Toggle "Maintenance Mode" for the entire system or specific modules (e.g., disable Orders but keep History viewable).
- **System Health**: Monitor active tenants and aggregate platform revenue.

---

## 🏗 Architecture

The project strictly follows **Clean Architecture** principles to ensure scalability, testability, and separation of concerns.

### Layered Structure

```mermaid
graph TD
    Presentation[Presentation Layer\n(UI, BLoC, Widgets)] --> Domain[Domain Layer\n(Entities, UseCases, Repositories)]
    Domain --> Data[Data Layer\n(Models, DataSources, APIs)]
```

1.  **Domain Layer** (Inner Circle):
    -   Contains **Entities** (POJOs like `Order`, `Tenant`) and **Repository Interfaces**.
    -   Host **Use Cases** which encapsulate specific business rules (e.g., `CreateOrder`, `ValidateTenantAccess`).
    -   Pure Dart code, no Flutter dependencies.

2.  **Data Layer** (Outer Circle):
    -   **Models**: Data Transfer Objects (DTOs) with JSON serialization (`order_model.dart`).
    -   **Data Sources**:
        -   `LocalDataSource`: Hive/SharedPrefs for persistence.
        -   `RemoteDataSource`: HTTP calls to the Sync Server or Cloud API.
    -   **Repositories**: Implementations of Domain interfaces, coordinating data retrieval strategies.

3.  **Presentation Layer** (External):
    -   **BLoC**: State management handling business logic events (e.g., `OrderEvent`, `TenantEvent`).
    -   **Screens/Widgets**: Responsive UI components for Mobile, Tablet, and Desktop.

### State Management
We use the **BLoC (Business Logic Component)** pattern for predictable state management.
-   **Events**: Triggers driven by user interaction (e.g., `SubmitOrderEvent`).
-   **States**: UI representations of data (e.g., `OrderLoading`, `OrderSuccess`).
-   **Dependency Injection**: **GetIt** is used to inject BLoCs, Repositories, and Use Cases.

---

## 🔄 Local Sync System

The "Local Sync" feature allows the Kiosk (Customer facing) and the Admin Panel (Staff facing) to operate in harmony on the same local network without internet.

### How It Works

1.  **The Server**: A lightweight Dart HTTP server runs on the primary device (usually the Staff Desktop).
2.  **The Clients**: Front-end Flutter apps connect to this server via IP address.
3.  **Data Flow**:
    -   **Customer** places an order -> POST to Server.
    -   **Server** broadcasts or stores the order in memory.
    -   **Staff** device polls or receives stream updates -> UI updates instantly.

### Server Implementation
Located in `/server/order_server.dart`. It provides RESTful endpoints:
-   `GET /orders`: Fetch all active orders.
-   `POST /orders`: Submit a new order.
-   `PUT /orders/:id`: Update status (e.g., mark as "Ready").
-   `POST /orders/counter`: Sync order numbering to prevent ID collisions.

### Server Setup

To start the synchronization server:

```bash
# From the project root
dart run server/order_server.dart
```
*The terminal will display the local IP address (e.g., `192.168.1.15:8080`) to enter in the App Settings.*

---

## 👮 Super Admin Panel

The Super Admin interface is a privileged zone for system oversight.

### Accessing Super Admin
-   **Login**: Use the dedicated Super Admin credentials (ID: `SUPER_ADMIN`).
-   **Security**: Bypasses Maintenance Mode locks.

### Capabilities
1.  **Tenant Provisioning**:
    -   Onboard new distributors.
    -   Assign Service Tiers (`Standard` vs `Premium`).
2.  **Feature Gating**:
    -   Enable/Disable specific modules (e.g., "Business Insights") for specific tenants.
3.  **Maintenance Controls**:
    -   **Global Kill Switch**: Put the entire platform into Maintenance Mode.
    -   **Module Lock**: Disable "Orders" during stock taking while keeping "History" active.

---

## 📁 Project Structure

```
sss/
├── lib/
│   ├── core/                  # Shared utilities, constants, and config
│   │   ├── config/            # API endpoints & flavors
│   │   ├── error/             # Failure definitions
│   │   └── utils/             # Validators & Formatters
│   │
│   ├── di/                    # Dependency Injection (GetIt) setup
│   │
│   ├── features/              # Feature-based modules
│   │   ├── admin/             # Super Admin screens & logic
│   │   ├── auth/              # Tenant Authentication & Management
│   │   ├── cart/              # Shopping Cart logic
│   │   ├── home/              # Landing screens
│   │   ├── orders/            # Order processing & Sync logic
│   │   ├── payment/           # M-Pesa integration
│   │   └── products/          # Catalog management
│   │
│   └── main.dart              # Entry point
│
├── server/                    # Local Sync Server
│   └── order_server.dart      # Dart HTTP Server implementation
│
├── assets/                    # Images, Icons, and Fonts
└── pubspec.yaml               # Dependencies
```

---

## 📦 Installation

### Prerequisites
-   **Flutter SDK**: 3.10+
-   **Dart SDK**: 3.0+
-   **Git**

### Steps

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/your-org/kfm-kiosk.git
    cd kfm-kiosk
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the Sync Server (Optional for standalone, Required for Sync)**
    ```bash
    dart run server/order_server.dart
    ```

4.  **Run the Application**
    ```bash
    # For Desktop (Linux/Windows/macOS)
    flutter run -d linux

    # For Web
    flutter run -d chrome
    ```

---

## ⚙️ Configuration

### App Configuration
Located in `lib/core/config/api_config.dart`.
-   **Base URL**: Toggle between `localhost` (Mock) and Production URLs.
-   **Flavor**: Switch between `AppFlavor.mock` and `AppFlavor.prod`.

### Tenant Configuration
Managed via `TenantService` in `lib/features/auth/domain/services/tenant_service.dart`.
-   **Mock Tenants**: Pre-loaded list of tenants (Standard/Premium) for testing.
-   **Tiers**: Defines feature access levels.

---

## 🧪 Testing & Deployment

### Running Tests
```bash
# Run unit and widget tests
flutter test

# Run integration tests
flutter test integration_test
```

### Deployment Build
```bash
# Build for Linux
flutter build linux --release

# Build for Web
flutter build web --release --base-href "/app/"

# Build Android APK
flutter build apk --release
```

---

*Verified Enterprise Documentation v1.1.0*

---

## 👨‍💻 Developer Internal Guide

This section is intended for developers contributing to the codebase. It covers internal patterns, conventions, and deeper technical explanations.

### 1. Codebase Anatomy

The project is structured to enforce separation of concerns.

#### `lib/core`
Contains successfully shared logic across multiple features.
-   **`config/`**: Environment-specific settings (`ApiConfig`). Use `AppFlavor` to switch between `mock` and `prod`.
-   **`error/`**: `Failure` classes for error handling. We use `Either<Failure, Type>` from `dartz` in Repositories.
-   **`utils/`**: Helper functions (e.g., `Validators.isValidPhone`).

#### `lib/features`
Each feature (Self-Contained System) has its own directory with:
-   **`data/`**:
    -   `models/`: Extend Entities + `fromJson`/`toJson`.
    -   `datasources/`: Implement `Local` (Hive/Prefs) and `Remote` (HTTP) logic.
    -   `repositories/`: Implementation of Domain Interfaces.
-   **`domain/`**:
    -   `entities/`: Pure Dart objects.
    -   `repositories/`: Abstract contracts.
    -   `usecases/`: Single-responsibility classes (e.g., `PlaceOrder`).
-   **`presentation/`**:
    -   `bloc/`: State management.
    -   `screens/`: Full-page widgets broken down by platform (`mobile/`, `desktop/`).
    -   `widgets/`: Reusable components specific to this feature.

### 2. The Sync Protocol Deep Dive

The **Local Sync** feature relies on a custom HTTP protocol defined in `server/order_server.dart`.

#### Server API (Desktop)
-   **`GET /orders`**: Returns `{ "orders": [...], "rows": <count> }`.
    -   Used by Kiosks to fetch the initial state or poll for updates.
-   **`POST /orders`**: Accepts a JSON Order object.
    -   **Payload**:
        ```json
        {
          "id": "ORD0001",
          "tenantId": "TEN001",
          "items": [...],
          "total": 500,
          "status": "PAID"
        }
        ```
    -   **Response**: `{ "success": true, "orderId": "..." }`.

#### Client Logic (Kiosk/Staff App)
-   **`OrderRemoteDataSource`**: Logic in `lib/features/orders/data/datasources/order_remote_datasource.dart`.
-   **Failover**: Currently, if the server is unreachable, the app throws an exception (which should be handled by UI to show "Offline").
-   **Polling**: `OrderRepositoryImpl` uses a `Stream.periodic` to poll `GET /orders` every 5 seconds for real-time updates.

### 3. State Management Guidelines

We use **flutter_bloc** for all complex state.

#### Creating a New Event
1.  Define the Event in `feature_event.dart`:
    ```dart
    abstract class OrderEvent extends Equatable { ... }

    class MarkOrderAsReady extends OrderEvent {
      final String orderId;
      const MarkOrderAsReady(this.orderId);
    }
    ```
2.  Handle it in the Bloc (`feature_bloc.dart`):
    ```dart
    on<MarkOrderAsReady>((event, emit) async {
      emit(OrderLoading());
      final result = await updateOrderStatusUseCase(event.orderId, 'READY');
      result.fold(
        (failure) => emit(OrderError(failure.message)),
        (success) => add(const LoadOrders()), // Refresh list
      );
    });
    ```
3.  **UI Consumption**:
    -   Use `BlocBuilder` for rebuilding UI (e.g., showing a spinner).
    -   Use `BlocListener` for one-time actions (e.g., showing a SnackBar on error).

### 4. Dependency Injection (DI)

We use **GetIt** (`lib/di/injection.dart`) for Service Locator pattern.

#### Registering a New Feature
1.  **Data Source**: `getIt.registerLazySingleton<RemoteDataSource>(() => RemoteDataSourceImpl(client: getIt()));`
2.  **Repository**: `getIt.registerLazySingleton<Repository>(() => RepositoryImpl(dataSource: getIt()));`
3.  **UseCase**: `getIt.registerLazySingleton(() => MyUseCase(repository: getIt()));`
4.  **Bloc**: `getIt.registerFactory(() => MyBloc(useCase: getIt()));` (Use `Factory` for Blocs to get a fresh instance per screen, usually).

### 5. Multi-Tenancy Architecture

The `TenantService` is a singleton that manages the active session.

-   **Initialization**: Loaded at app startup.
-   **Switching Tenants**:
    -   When a user logs in, `TenantService.setCurrentTenant(tenant)` is called.
    -   All subsequent API calls should ideally inject the `tenantId` (e.g., `api/orders?tenantId=TEN001`).
-   **Feature Gating**:
    -   Use `TenantService.canAccessFeature('feature_key')` to show/hide UI elements.
    -   Example: `if (tenant.tier == TenantTier.premium) showAnalytics();`

### 6. Debugging Tips

-   **Mock Mode**: Set `AppFlavor.mock` in `ApiConfig` to bypass the backend and use dummy data.
-   **Logs**: Check the terminal for `[Sync]` tagged logs to debug HTTP traffic between Kiosk and Server.

### 7. Global Error Handling Strategy

We use a custom `Failure` class hierarchy located in `lib/core/errors/failures.dart`.

-   **Structure**: All failures extend the abstract `Failure` class and implement `Equatable` for easy comparison.
-   **Usage**: Repositories typically return `Either<Failure, Type>`.
    ```dart
    // Example: Return Left(ServerFailure) on catch
    try {
      final result = await remoteDataSource.getData();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString())); // Maps exceptions to domain failures
    }
    ```
-   **Common Failures**:
    -   `ServerFailure`: Backend/API errors.
    -   `CacheFailure`: Local storage errors.
    -   `NetworkFailure`: No internet connection.

### 8. Testing Standards

While the current test suite is evolving, we follow these standards for new tests:

-   **Unit Tests (`test/features/...`)**:
    -   Test **Use Cases** by mocking Repositories using `mockito`.
    -   Test **BLoCs** using `bloc_test` package to verify state emissions.
-   **Widget Tests**:
    -   Use `WidgetTester` to verify UI components render correctly.
    -   Always wrap widgets in `MaterialApp` during testing if they depend on Theme or Navigator.
-   **Naming Convention**: All test files must end in `_test.dart`.

### 9. UI & Theming System

The app's design system is centralized in `lib/core/constants/app_constants.dart`.

#### Theming
-   **Colors**: Defined in `AppColors` class.
    -   `primaryBlue`: KFM Green (#0B8843)
    -   `secondaryGold`: Dark Green (#0A5730)
-   **ThemeData**: Configured in `main.dart`. We use `ColorScheme.fromSeed` for Material 3 compliance.

#### Localization
We use a lightweight, manual localization system (avoiding complex `.arb` files for simplicity).
-   **Strings**: Defined in `AppStrings` class as static Maps (`en` and `sw`).
-   **Usage**:
    ```dart
    Text(AppStrings.get('welcome', state.languageCode))
    ```
-   **State**: `LanguageCubit` manages the current locale.

### 10. Contribution Workflow

-   **Branching**: Use feature branches `feat/feature-name` or `fix/issue-name`.
-   **Commits**: Follow [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat: add order validation`).
-   **File Naming**: Use `snake_case` for all files (e.g., `order_repository_impl.dart`).
-   **Class Naming**: Use `PascalCase` (e.g., `OrderRepositoryImpl`).



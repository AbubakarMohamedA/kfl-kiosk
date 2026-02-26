# KFM Kiosk Database Architecture Documentation

This document provides a comprehensive overview of the database architecture for the KFM Kiosk Flutter application.

## 1. Technologies and Overview

The application relies heavily on local storage to act as an offline-first "Master Node" on a local network. 
- **ORM / Database Provider:** `drift` (formerly `moor`), which is a reactive persistence library for Flutter and Dart built on top of SQLite.
- **File Location:** The underlying SQLite file is stored as `kiosk_db.sqlite` in the application's documents directory.
- **Schema Management:** Defined completely in Dart code within `lib/core/database/app_database.dart`. Code generation (`build_runner`) generates the underlying SQL syntax in `app_database.g.dart`.

---

## 2. Schema breakdown (Core Tables)

The database schema is heavily relational and designed to support multi-tenancy (multiple companies/brands) and multi-branch isolation.

### 2.1 Domain & Hardware Hierarchy
- **`Tenants`**: Represents the top-level business or enterprise. Stores tier levels, revenue, and feature flags.
- **`Branches`**: Represents physical locations underneath a Tenant. Critical for data isolation (a tablet in Branch A shouldn't see orders from Branch B).
- **`Warehouses`**: Represents logical storage units underneath a Branch, primarily used for routing specific product categories (e.g., drinks vs. food) to specific preparation screens.
- **`Tiers`**: System-level subscription tiers defining what a tenant is allowed to do.

### 2.2 Point of Sale Entities
- **`Products`**: The master catalog. Contains product names, prices, stock, and categories. *Crucially, it includes `tenantId` and `branchId` to filter what is shown.*
- **`Orders`**: Represents a completed or in-progress transaction. Stores total amounts, timestamps, and origin information. 
  - *Key feature:* Tracks the `terminalId` (which tablet created the order) alongside `tenantId` and `branchId`.
- **`OrderItems`**: The line items of an order.
- **`CartItems`**: Transient state for items currently being selected by a user before checkout.

### 2.3 Configuration & Metadata
- **`AppConfig`**: A generic Key-Value store (columns `key`, `value`) used for system-wide flags, like the daily `orderCounter` or software license status.
- **`TenantConfigs`**: Stores UI/UX configurations synced down for a specific tenant, such as custom logo paths, brand colors, and welcome messages.

---

## 3. Data Access Objects (DAOs)

Drift separates queries into DAO classes (Data Access Objects) located in `lib/core/database/daos/`. 

### 3.1 Reactive Streams
A significant feature of this architecture is the widespread use of Drift's `.watch()` facility. 
For example, `ProductsDao.watchAllProducts()` returns a `Stream<List<Product>>`. The Flutter UI (via BLoC) listens to these streams. When the embedded backend server updates the database via a REST call from a tablet, the UI on the Master Node desktop updates instantly and automatically locally without manual re-fetching.

### 3.2 Robust Upserts (Conflict Resolution)
Because client tablets might resend data if network connections flake, the `OrdersDao` utilizes aggressive "Upsert" (Update or Insert) patterns.
```dart
// Example from OrdersDao.upsertOrder
await into(orders).insertOnConflictUpdate(order);
await (delete(orderItems)..where((tbl) => tbl.orderId.equals(order.id.value))).go();
// Re-insert items...
```
This transaction block guarantees that a synced order exactly matches the state submitted by the client without ending up with duplicate line items.

---

## 4. Key Architectural Design Choices

### 4.1 "Historical Snapshotting" in Order Items
In typical e-commerce DB design, you might link an `OrderItem` to a `Product` solely via a foreign key. However, the `OrderItems` table explicitly duplicates strings: `productName`, `unitPrice`, `productCategory`, and `productVariant`.
- **Why?** If a manager changes the price of a "Burger" in the `Products` table tomorrow, the receipts/orders processed *today* must not retroactively change their calculated prices or names.

### 4.2 Multi-Tenancy & Isolation enforced via Queries
Every DAO query accessing operational data filters by ID.
```dart
// Example from ProductsDao
if (tenantId != null) query = query..where((tbl) => tbl.tenantId.equals(tenantId));
if (branchId != null) query = query..where((tbl) => tbl.branchId.equals(branchId));
```
Because multiple clients might sync to the same master node database file, these columns act as virtual sandboxes.

### 4.3 Automated Migrations
The `AppDatabase.migration` block explicitly handles version bumps (current schema version is `14`). 
- It uses safe methods like `_addColumnIfNotExists` to gracefully handle updates deployed to production machines without wiping existing kiosk data.
- The `beforeOpen` hook is utilized to backfill legacy data with a default `SUPER_ADMIN` tenant ID if records were created before multi-tenancy was introduced.

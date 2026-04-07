# SAP Business One Integration — Technical Reference

> **Project:** KFL Kiosk (`kflkiosk`)  
> **SAP Version:** SAP Business One Service Layer (OData v1 — `/b1s/v1`)  
> **Protocol:** HTTPS on port `50000`  
> **Last Updated:** 2026-03-29

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Authentication & Session Management](#2-authentication--session-management)
3. [Credential & Settings Storage](#3-credential--settings-storage)
4. [Customer (Business Partner) Management](#4-customer-business-partner-management)
5. [Product (Item) Synchronization](#5-product-item-synchronization)
6. [Order-to-Invoice Synchronization](#6-order-to-invoice-synchronization)
7. [Incoming Payment Creation](#7-incoming-payment-creation)
8. [Resilient Sync — Retry Queue & Concurrency](#8-resilient-sync--retry-queue--concurrency)
9. [Local Database — SAP Tracking Columns](#9-local-database--sap-tracking-columns)
10. [SAP Invoice Viewer (UI)](#10-sap-invoice-viewer-ui)
11. [Dependency Injection Wiring](#11-dependency-injection-wiring)
12. [HTTP Client — TLS/SSL Handling](#12-http-client--tlsssl-handling)
13. [SAP Service Layer API Reference](#13-sap-service-layer-api-reference)
14. [Error Handling Patterns](#14-error-handling-patterns)
15. [Known Issues & Mitigations](#15-known-issues--mitigations)
16. [Glossary](#16-glossary)

---

## 1. Architecture Overview

The kiosk system uses a **Hybrid Architecture** where:

- **Kiosk Terminals** (Android/iOS) interact with a **Local Staff Server** running on the Staff Desktop machine on the same LAN.
- The **Local Staff Server** holds all SAP credentials and is the **only** node that communicates with the SAP B1 Service Layer.
- Kiosks themselves **never** make direct SAP requests. They POST orders to the local server over HTTP, and the server handles SAP synchronization.

```
┌─────────────────────────────────────────────────────────┐
│                         LAN / Wi-Fi                     │
│                                                          │
│  ┌────────────┐      POST /api/v1/orders      ┌────────┐ │
│  │  Kiosk     │ ─────────────────────────────▶│ Staff  │ │
│  │  Terminal  │                               │ Server │ │
│  └────────────┘                               │ :8080  │ │
│                                               └───┬────┘ │
└───────────────────────────────────────────────────┼──────┘
                                                     │ HTTPS:50000
                                              ┌──────▼──────────────┐
                                              │  SAP B1 Service Layer│
                                              │  /b1s/v1             │
                                              └──────────────────────┘
```

### Key Files

| File | Role |
|---|---|
| `lib/core/services/sap_auth_service.dart` | All SAP authentication, session, and business partner search |
| `lib/features/orders/data/datasources/sap_invoice_datasource.dart` | Invoice creation, payment posting, retry queue |
| `lib/features/products/data/datasources/sap_product_datasource.dart` | Product catalog fetch, pricing, CRUD |
| `lib/features/orders/data/models/sap_invoice_model.dart` | Data model for a SAP invoice record |
| `lib/features/orders/presentation/screens/sap_invoices_screen.dart` | UI for viewing SAP A/R Invoices |
| `lib/core/services/local_server_service.dart` | Local HTTP server; triggers SAP sync on order receipt |
| `lib/core/database/app_database.dart` | Drift (SQLite) schema including SAP tracking columns |
| `lib/core/database/daos/orders_dao.dart` | DAO for order persistence and SAP status updates |
| `lib/di/injection.dart` | GetIt dependency injection wiring for all SAP services |

---

## 2. Authentication & Session Management

**File:** `lib/core/services/sap_auth_service.dart`  
**Class:** `SapAuthService`

### 2.1 Login

The app logs into SAP B1 via the Service Layer's `/Login` endpoint.

**Endpoint:** `POST https://{serverIp}:50000/b1s/v1/Login`

**Request Payload:**
```json
{
  "CompanyDB": "SBODemoKE",
  "UserName": "manager",
  "Password": "password"
}
```

**On Success (HTTP 200):**  
- The response body contains `SessionId` (a UUID string).
- The response headers contain a `Set-Cookie` header. The app extracts the `ROUTEID` value from this cookie using a regex (`ROUTEID=([^;]+)`) for load-balanced environments.
- Both `SessionId` and `ROUTEID` are persisted to `SharedPreferences`.
- The `serverIp` and `companyDb` used to create this session are also stored as `sap_last_login_server_ip` and `sap_last_login_company_db` for consistency checks.

**Code:**
```dart
final response = await client.post(
  Uri.parse('https://$serverIp:50000/b1s/v1/Login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'CompanyDB': companyDb, 'UserName': username, 'Password': password}),
);
```

### 2.2 Session Consistency Check

On every `getSessionId()` call, the code compares the stored `server_ip` / `sap_company_db` against the `sap_last_login_*` values. If they differ (meaning the user changed the SAP config after logging in), the stored session ID is considered **stale and not returned**, forcing a re-login.

### 2.3 Auto-Login (`ensureSession`)

`ensureSession()` is the primary guard used before any SAP API call:

```dart
Future<bool> ensureSession() async {
  final sessionId = await getSessionId();
  if (sessionId != null && sessionId.isNotEmpty) return true;
  final loginResult = await login();
  return loginResult.success;
}
```

If a valid session exists → returns `true` immediately without re-logging in.  
If no session → attempts login and returns the result.

### 2.4 Logout

**Endpoint:** `POST https://{serverIp}:50000/b1s/v1/Logout`

Sends the `B1SESSION` and `ROUTEID` cookies. After the HTTP call (whether it succeeds or not), the local session keys are cleared from `SharedPreferences`.

### 2.5 Request Headers

All authenticated requests use headers assembled by `getHeaders()`:

```dart
{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Cache-Control': 'no-cache',
  'Pragma': 'no-cache',
  'Cookie': 'B1SESSION={sessionId}; ROUTEID={routeId}',  // routeId only if present
}
```

---

## 3. Credential & Settings Storage

**Storage Engine:** `SharedPreferences` (on-device key-value store)

All SAP configuration is stored locally using these keys:

| SharedPreferences Key | Description |
|---|---|
| `server_ip` | SAP server hostname (stripped of protocol and port) |
| `sap_company_db` | SAP Company Database name (e.g., `SBODemoKE`) |
| `sap_username` | SAP B1 username |
| `sap_password` | SAP B1 password (stored in plaintext) |
| `b1_session_id` | Active SAP session ID (UUID) |
| `sap_route_id` | Load-balancer `ROUTEID` cookie value |
| `sap_last_login_server_ip` | Server IP used to create the current session |
| `sap_last_login_company_db` | CompanyDB used to create the current session |
| `sap_walkin_card_code` | Default "walk-in" customer `CardCode` for orders |
| `sap_currency_code` | Default currency (e.g., `KES`) |
| `sap_warehouse_code` | Default warehouse code (e.g., `01`) |
| `sap_bpl_id` | Branch/Plant ID (`BPL_IDAssignedToInvoice`) |
| `sap_tax_code` | VAT group code (e.g., `O1`) |
| `sap_payment_gl_account` | G/L account for incoming payment bank transfers |
| `sap_override_card_code` | Temporary per-date override `CardCode` |
| `sap_override_start_date` | Start date for the override customer rule |
| `sap_override_end_date` | End date for the override customer rule |
| `sap_active_customer_code` | Per-transaction active customer `CardCode` |
| `sap_active_customer_name` | Per-transaction active customer `CardName` |

### Server IP Cleaning

Before saving, hostile formats are stripped:
```dart
final cleanIp = serverIp
    .replaceAll('https://', '')
    .replaceAll('http://', '')
    .replaceAll('/b1s/v1', '')
    .replaceAll(':50000', '');
```

### Session Invalidation on Config Change

If `serverIp` or `companyDb` changes during `saveCredentials()`, any existing `b1_session_id` and `sap_route_id` are immediately deleted to prevent cross-company session leakage.

---

## 4. Customer (Business Partner) Management

### 4.1 Active Customer Priority Rules

The method `getActiveCardCode()` resolves the customer to use for an order with this priority:

1. **`sap_active_customer_code`** — Set explicitly via the "Active Customer" picker in the UI. Highest priority. Clears after the session ends.
2. **`sap_override_card_code`** — Date-bound override. Used only if today's date falls within `[sap_override_start_date, sap_override_end_date]`.
3. **`sap_walkin_card_code`** — Permanent default customer for standard walk-in transactions.

```dart
// Priority 1
final activeCode = prefs.getString(_activeCustomerKey);
if (activeCode != null && activeCode.isNotEmpty) return activeCode;

// Priority 2 (date-bounded override)
if (overrideCode != null && today.isWithinRange(startDate, endDate)) return overrideCode;

// Priority 3 (walk-in default)
return walkInCode;
```

### 4.2 Setting / Clearing the Active Customer

The staff can set a per-transaction customer via the UI. This is stored immediately in `SharedPreferences`:

```dart
await sapAuthService.saveActiveCustomer('LC00017', 'Quavatel Ltd');
await sapAuthService.clearActiveCustomer(); // Clears after transaction
```

### 4.3 Business Partner Search

**Endpoint:** `GET /b1s/v1/BusinessPartners?$select=CardCode,CardName&$filter=CardType eq 'cCustomer' and (contains(CardCode, '{query}') or contains(CardName, '{query}'))&$top=500`

- Only `CardType eq 'cCustomer'` records are returned (excludes Vendors and Leads).
- Supports OData **pagination** via `odata.nextLink` for result sets exceeding 500 records.
- Single-quote escaping is applied: `query.replaceAll("'", "''")`.
- Search is **debounced 500ms** in the UI to prevent excessive API calls.
- When a `nextLink` is provided by SAP, the app constructs the next URL relative to the server root: `https://{server}:50000{nextLink}`.

**Return Type:** `SapBpQueryResult` containing `List<Map<String, String>>` with keys `CardCode` and `CardName`.

---

## 5. Product (Item) Synchronization

**File:** `lib/features/products/data/datasources/sap_product_datasource.dart`  
**Class:** `SapProductDataSource implements ProductDataSource`

### 5.1 Product Fetching Strategy

The datasource uses a **multi-layer caching strategy** to maximize performance and minimize SAP session load:

| Layer | Duration | Location |
|---|---|---|
| In-memory `_cachedProducts` | Until app restart *or* next day | RAM |
| `SharedPreferences` disk cache | One calendar day | Device storage |
| SAP Service Layer API | On-demand (cache miss) | `https://{server}:50000/b1s/v1/Items` |

A **fetch lock** (`Completer`) prevents concurrent duplicate fetches: if a fetch is already in progress, new callers wait on the same `Future` instead of launching a second request.

### 5.2 Product Fetch API

**Endpoint:** `GET /b1s/v1/Items?$select=ItemCode,ItemName,ItemsGroupCode,QuantityOnStock,MinInventory,MaxInventory,AvgStdPrice,Mainsupplier,InventoryUOM,ItemPrices&$orderby=ItemCode`

- Full **auto-pagination** via `odata.nextLink`: the app loops until `nextLink` is null.
- A **session warmup call** (`GET /Items?$top=0`) is performed before the first real fetch. This avoids an SAP B1 quirk where the first query of a new session returns empty results.
- On `HTTP 401`, the datasource auto re-logins and retries the same request.
- If an initial page returns zero items (defensive retry), it waits 1 second and retries up to 5 times.

### 5.3 Item Group / Category Mapping

**Endpoint:** `GET /b1s/v1/ItemGroups?$select=Number,GroupName`

Item groups are fetched once per session and cached in `_groupCache: Map<int, String>`. Each product's `ItemsGroupCode` is mapped to its human-readable `GroupName`. Falls back to `"Group {code}"` if the group is not found.

### 5.4 Customer-Specific Pricing

Pricing is resolved with two-level priority:

**Level 1: Special Prices (override)**

**Endpoint:** `GET /b1s/v1/SpecialPrices?$filter=CardCode eq '{cardCode}'&$select=ItemCode,Price`

Special prices are specific price overrides negotiated per customer per item. If a special price exists for an item and it is > 0, it takes over all other prices.

**Level 2: Customer Price List**

**Endpoint:** `GET /b1s/v1/BusinessPartners('{cardCode}')?$select=PriceListNum`

First, the `PriceListNum` assigned to the customer is fetched. Then, the `ItemPrices` array returned with each item is scanned to find the price entry matching that price list number.

**Level 3: Fallback**

If no special price and no matching price list entry is found, `AvgStdPrice` (average/standard price) is used.

### 5.5 Product Mapping

SAP item fields are mapped to the app's `ProductModel`:

| SAP Field | ProductModel Field | Notes |
|---|---|---|
| `ItemCode` | `id` | Primary key |
| `ItemName` | `name`, `description` | Used for both |
| `Mainsupplier` | `brand` | Supplier code |
| `InventoryUOM` | `size` | Unit of measure |
| `ItemsGroupCode` | `category` | Mapped via `_groupCache` |
| Calculated price | `price` | Via special price / price list / avg |
| `ItemPrices` | `itemPrices` | Full `List<PriceModel>` |
| Uploaded image URL | `imageUrl` | Local override from `_uploadedImages` |

### 5.6 Product CRUD Operations

| Operation | SAP Endpoint | Method |
|---|---|---|
| Add Product | `POST /Items` | Creates a new SAP Item record |
| Update Product | `PATCH /Items('{ItemCode}')` | Partial update (only non-null fields sent) |
| Delete Product | `DELETE /Items('{ItemCode}')` | Permanently deletes from SAP |
| Get by ID | `GET /Items('{ItemCode}')` | Single item fetch |

> **Important:** Null fields are **never sent** in PATCH requests to avoid SAP clearing existing values.

### 5.7 Product Image Management

Product images are **not stored in SAP**. The app maintains a local mapping:
- `_uploadedImages: Map<String, String>` in memory (keyed by `ItemCode`)
- Persisted to `SharedPreferences` under key `sap_uploaded_images` as JSON

When a product image is updated, `updateLocalImage()` updates both the in-memory map and the persisted cache, then immediately updates the in-memory product list.

The cache can be invalidated via `clearCache()`, which also clears the `SharedPreferences` product and image data.

---

## 6. Order-to-Invoice Synchronization

**File:** `lib/features/orders/data/datasources/sap_invoice_datasource.dart`  
**Class:** `SapInvoiceDataSource`

### 6.1 Sync Trigger

When the Staff Server receives an order via `POST /api/v1/orders`, it immediately calls (fire-and-forget, not awaited in the HTTP response):

```dart
_sapInvoiceDataSource.syncOrderAsInvoice(orderModel);
```

The active customer `CardCode` (captured at the moment of order reception) is embedded in the `orderModel` before the sync call:

```dart
final activeCardCode = await _sapAuthService.getActiveCardCode();
orderModel = orderModel.copyWith(sapCardCode: activeCardCode);
```

### 6.2 Invoice Payload

**Endpoint:** `POST /b1s/v1/Invoices`

**Document Type:** `A/R Reserve Invoice` (`ReserveInvoice: "tYES"`)

```json
{
  "CardCode": "LC00017",
  "DocCurrency": "KES",
  "DocDate": "2026-03-29",
  "DocDueDate": "2026-03-29",
  "ReserveInvoice": "tYES",
  "BPL_IDAssignedToInvoice": 1,
  "DocumentLines": [
    {
      "ItemCode": "ITM00001",
      "Quantity": 1,
      "PriceAfterVAT": 2700.0,
      "VatGroup": "O1",
      "WarehouseCode": "01"
    }
  ]
}
```

**Field Notes:**
- `CardCode` — The `sapCardCode` snapshotted into the order at creation time.
- `DocCurrency` — From `sap_currency_code` setting (default: `KES`).
- `DocDate` / `DocDueDate` — Formatted as `yyyy-MM-dd` from `order.timestamp`.
- `ReserveInvoice: "tYES"` — Creates a Reserve Invoice (not yet delivered), matching the kiosk pre-payment workflow.
- `BPL_IDAssignedToInvoice` — The Branch/Plant ID from `sap_bpl_id`. Only included if configured. Parsed as `int`.
- `VatGroup` — Dynamically pulled from each item's `SalesVATGroup` inside SAP (default fallback: `O1`).
- `WarehouseCode` — From `sap_warehouse_code`. Only included per line if configured.
- `PriceAfterVAT` — Tax-inclusive price. SAP uses this to correctly back-calculate the base price.

### 6.3 Invoice Success Flow

On `HTTP 201` or `HTTP 200`:  
1. The response body is parsed for `DocEntry` (the SAP primary key for the invoice) and `DocTotal`.
2. The `BPL_IDAssignedToInvoice` (or variants `BPLID` / `BPLId`) is extracted from the response for use in the payment.
3. If a `paymentGlAccount` is configured, an **Incoming Payment** is immediately posted (see Section 7).
4. The local database is updated: `sapSyncStatus = 'synced'`, `sapDocEntry = {docEntry}`.

On failure (`HTTP 400+`):  
- The local database is updated: `sapSyncStatus = 'failed'`.
- The order joins the retry queue (see Section 8).

---

## 7. Incoming Payment Creation

**Endpoint:** `POST /b1s/v1/IncomingPayments`

Triggered automatically **immediately after** a successful invoice creation.

### Payment Payload

```json
{
  "DocType": "rCustomer",
  "CardCode": "LC00017",
  "DocDate": "2026-03-29",
  "DocCurrency": "KES",
  "TransferAccount": "1200020",
  "TransferSum": 4100.0,
  "TransferReference": "0712345678",
  "TransferDate": "2026-03-29",
  "Remarks": "Mpesa Payment - 0712345678",
  "JournalRemarks": "Mpesa 0712345678",
  "BPLID": 1,
  "PaymentInvoices": [
    {
      "DocEntry": 564,
      "SumApplied": 4100.0,
      "InvoiceType": "it_Invoice"
    }
  ]
}
```

**Field Notes:**
- `DocType: "rCustomer"` — Specifies this is a customer receipt.
- `TransferAccount` — The `sap_payment_gl_account` setting (GL account for bank/M-Pesa transfers). **Required**; if not configured, no payment is posted.
- `TransferSum` / `SumApplied` — `DocTotal` from the created invoice; applies the full amount.
- `TransferReference` / `Remarks` / `JournalRemarks` — Populated from `order.phone` (the M-Pesa phone number).
- `InvoiceType: "it_Invoice"` — Links the payment to a Reserve Invoice specifically.
- `BPLID` — Branch ID echoed from the invoice response. Parsed as `int`.
- The payment amount **fully closes** the invoice (`SumApplied == DocTotal`).

---

## 8. Resilient Sync — Retry Queue & Concurrency

### 8.1 Mutex Lock

**Package:** `synchronized: ^3.4.0`

A static `Lock` is shared across all instances of `SapInvoiceDataSource`:

```dart
static final _lock = Lock();
```

Every `syncOrderAsInvoice()` call is wrapped in:

```dart
await _lock.synchronized(() async {
  // ... invoice creation and payment logic
});
```

This ensures **only one SAP write operation happens at a time**, eliminating the `ODBC -2028` database lock errors that occurred when two kiosks placed orders simultaneously.

### 8.2 SAP Sync Status Lifecycle

Each order in the local SQLite database carries a `sapSyncStatus` column:

| Status | Meaning |
|---|---|
| `pending` | Order received, sync not yet attempted |
| `synced` | Invoice and payment successfully created in SAP |
| `failed` | Sync attempt made but failed (will be retried) |

### 8.3 Background Retry Timer

A `Timer.periodic` with a **5-minute interval** runs in `LocalServerService` from server start:

```dart
_sapRetryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
  _sapInvoiceDataSource.retryFailedSyncs();
});
```

An initial retry is also triggered immediately at server startup.

### 8.4 Retry Mechanism (`retryFailedSyncs`)

1. `OrdersDao.getFailedSapOrders()` is called — queries all rows where `sapSyncStatus = 'failed'`.
2. For each failed order, order items are fetched from `OrderItems` table.
3. A full `OrderModel` is **manually constructed** from the raw Drift entities (to avoid type name collisions with the domain `Order` class).
4. `syncOrderAsInvoice(orderModel)` is called — the order naturally waits for the `Lock` if another sync is in progress.
5. The `sapCardCode` snapshotted at order time is reused, ensuring the retry targets the **same customer** as the original transaction.

---

## 9. Local Database — SAP Tracking Columns

**File:** `lib/core/database/app_database.dart`  
**Table:** `Orders` (Drift)

```dart
class Orders extends Table {
  // ... standard order columns ...
  TextColumn get sapSyncStatus => text().withDefault(const Constant('pending'))(); // 'pending' | 'synced' | 'failed'
  IntColumn get sapDocEntry   => integer().nullable()(); // SAP DocEntry from invoice response
  TextColumn get sapCardCode  => text().nullable()();    // CardCode snapshotted at order time
}
```

**Schema Version:** `15` (columns added in migration from version 14).

### DAO Methods

**File:** `lib/core/database/daos/orders_dao.dart`

| Method | Description |
|---|---|
| `getFailedSapOrders()` | `SELECT * FROM orders WHERE sapSyncStatus = 'failed'` |
| `updateSapSyncStatus(id, status, {docEntry})` | Updates `sapSyncStatus` and optionally `sapDocEntry` for one order |
| `getItemsForOrder(orderId)` | Fetches all `OrderItems` for a given order (used in retry) |
| `upsertOrder(companion, items)` | Inserts or replaces an order including `sapSyncStatus`, `sapDocEntry`, `sapCardCode` |

---

## 10. SAP Invoice Viewer (UI)

**File:** `lib/features/orders/presentation/screens/sap_invoices_screen.dart`  
**Class:** `SapInvoicesScreen`

### 10.1 Loading Invoices

On initialization, `ensureSession()` is called to guarantee a valid SAP session before any fetch. The screen then fetches invoices using:

**Endpoint:** `GET /b1s/v1/Invoices?$select=DocEntry,DocNum,CardCode,CardName,DocDate,DocTotal,DocumentStatus,DocCurrency&$orderby=DocNum%20desc&$top=20&$skip={page * 20}&$filter=CardCode%20eq%20'{cardCode}'`

- Results are displayed in descending document number order (newest first).
- Page size is **20 records** with manual chevron-based pagination.

### 10.2 "Show All" Toggle

A `Switch` in the toolbar toggles `_showAllInvoices`:

- **OFF (default):** Fetches invoices filtered to `CardCode eq '{activeCardCode}'` — only invoices for the active customer.
- **ON:** Fetches all invoices (no `CardCode` filter).

The active CardCode filter badge is displayed when filtering is active.

### 10.3 Invoice Detail Drill-Down

Tapping an invoice calls:

**Endpoint:** `GET /b1s/v1/Invoices({docEntry})`

Displays a dialog with all `DocumentLines` including `ItemDescription`, `Quantity`, and `Price`, plus the total amount.

### 10.4 Session Recovery

Both the list fetch and the detail fetch implement **401 auto-recovery**:

```dart
if (response.statusCode == 401) {
  final loginResult = await _sapAuthService.login();
  if (loginResult.success) {
    final newHeaders = await _sapAuthService.getHeaders();
    response = await client.get(url, headers: newHeaders); // retry
  }
}
```

### 10.5 Status Color Mapping

| SAP `DocumentStatus` | Display Text | Color |
|---|---|---|
| `bost_Close` | Closed | Green |
| `bost_Open` | Open | Blue |
| Any other | Raw value | Blue |

---

## 11. Dependency Injection Wiring

**File:** `lib/di/injection.dart`  
**Container:** `GetIt` (singleton pattern)

```
SapAuthService                    (lazySingleton)
    ↓ injected into
SapProductDataSource              (lazySingleton)
SapInvoiceDataSource              (lazySingleton, + OrdersDao)
    ↓ injected into
LocalServerService                (lazySingleton)
ProductRepositoryImpl             (lazySingleton)
OrderRepositoryImpl               (lazySingleton)
```

**Registration order:**

```dart
// 1. Auth service
getIt.registerLazySingleton<SapAuthService>(() => SapAuthService());

// 2. Data sources depend on auth
getIt.registerLazySingleton<SapProductDataSource>(
    () => SapProductDataSource(getIt<SapAuthService>()));
getIt.registerLazySingleton<SapInvoiceDataSource>(
    () => SapInvoiceDataSource(getIt<SapAuthService>(), getIt<OrdersDao>()));

// 3. Server depends on invoice datasource + auth
getIt.registerLazySingleton<LocalServerService>(() => LocalServerService(
    getIt<SapInvoiceDataSource>(), getIt<SapAuthService>(), ...));

// 4. Repositories use datasources
getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
    sapDataSource: getIt<SapProductDataSource>(), ...));
getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(
    sapInvoiceDataSource: getIt<SapInvoiceDataSource>(), ...));
```

---

## 12. HTTP Client — TLS/SSL Handling

**File:** `lib/core/utils/http_client_factory.dart`  
**Function:** `createSapHttpClient()`

SAP B1 servers typically use self-signed SSL certificates. The app creates a custom `HttpClient` that bypasses certificate validation for SAP connections:

```dart
HttpClient createSapHttpClient() {
  final ioClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(ioClient);
}
```

> **Security Note:** This disables certificate validation for SAP requests only. This is acceptable for internal LAN-based SAP deployments but should be reviewed for internet-facing configurations.

`SapAuthService` uses this custom client for all its requests. `SapProductDataSource` accepts an optional `http.Client` in its constructor but defaults to the standard `http.Client()` (not the custom one), which means product requests may fail if the SAP server uses a self-signed cert with a strict client. This is worth reviewing if product fetches fail on production.

---

## 13. SAP Service Layer API Reference

### Endpoints Used

| # | Method | Endpoint | Purpose |
|---|---|---|---|
| 1 | `POST` | `/b1s/v1/Login` | Authenticate and get session |
| 2 | `POST` | `/b1s/v1/Logout` | Invalidate session |
| 3 | `GET` | `/b1s/v1/BusinessPartners` | Search customers by CardCode/CardName |
| 4 | `GET` | `/b1s/v1/Items` | Fetch product catalog (paginated) |
| 5 | `GET` | `/b1s/v1/Items('{ItemCode}')` | Fetch single product |
| 6 | `POST` | `/b1s/v1/Items` | Create new SAP Item |
| 7 | `PATCH` | `/b1s/v1/Items('{ItemCode}')` | Update existing SAP Item |
| 8 | `DELETE` | `/b1s/v1/Items('{ItemCode}')` | Delete SAP Item |
| 9 | `GET` | `/b1s/v1/ItemGroups` | Fetch item group/category names |
| 10 | `GET` | `/b1s/v1/BusinessPartners('{CardCode}')` | Get customer's assigned price list |
| 11 | `GET` | `/b1s/v1/SpecialPrices` | Get customer-specific item pricing |
| 12 | `POST` | `/b1s/v1/Invoices` | Create A/R Reserve Invoice |
| 13 | `GET` | `/b1s/v1/Invoices` | List invoices (paginated, filterable) |
| 14 | `GET` | `/b1s/v1/Invoices({DocEntry})` | Fetch a single invoice with all lines |
| 15 | `POST` | `/b1s/v1/IncomingPayments` | Post a customer receipt / payment |

### OData Query Patterns

```
# Filter customers
$filter=CardType eq 'cCustomer' and (contains(CardCode, 'LC') or contains(CardName, 'Q'))

# Paginate items, ordered for consistent skip
$orderby=ItemCode&$top=20&$skip=40

# Filter invoices for a customer
$filter=CardCode%20eq%20'LC00017'

# Select specific fields to minimize payload
$select=DocEntry,DocNum,CardCode,DocDate,DocTotal,DocumentStatus
```

---

## 14. Error Handling Patterns

### 14.1 SAP Error Parsing

All error responses from SAP Service Layer follow this JSON structure:

```json
{
  "error": {
    "code": "-2028",
    "message": {
      "lang": "en-us",
      "value": "No matching records found (ODBC -2028)"
    }
  }
}
```

The app parses these using `_parseError(body)`:

```dart
String _parseError(String body) {
  try {
    final json = jsonDecode(body);
    return json['error']['message']['value'] ?? body;
  } catch (_) {
    return body;
  }
}
```

### 14.2 HTTP Status Handling

| Status | Action |
|---|---|
| `200` / `201` | Success — parse response body |
| `204` | Success (no content) — for PATCH/DELETE |
| `401` | Session expired — auto re-login and retry once |
| `404` | Not found — return `null` (product) or empty list (invoices) |
| `400`–`500` | Parse SAP error message — mark order as `failed` for retry |

---

## 15. Known Issues & Mitigations

### ODBC -2028: No Matching Records Found
**Root Cause:** Two or more concurrent SAP write operations hit the same database transaction lock in SAP HANA/SQL Server.  
**Mitigation:** The static `Lock` (from `synchronized` package) in `SapInvoiceDataSource` serializes all invoice creation calls. Orders fail gracefully and auto-retry every 5 minutes.

### Empty Product Response on New Session
**Root Cause:** SAP B1 Service Layer sometimes returns an empty `value` array on the very first `Items` query after a login.  
**Mitigation:** A lightweight warmup call (`GET /Items?$top=0`) is made before the first paginated fetch to pre-warm the session's data context.

### Session Staleness After Config Change
**Root Cause:** Changing `serverIp` or `companyDb` in the UI without explicit logout left a stale session cookie for the wrong server.  
**Mitigation:** `saveCredentials()` detects a config change and proactively clears the `b1_session_id` and `sap_route_id` from `SharedPreferences`.

### Cross-Company Session Leak
**Root Cause:** After switching `companyDb`, `getSessionId()` could return the old session.  
**Mitigation:** `getSessionId()` performs a consistency check by comparing the current config against `sap_last_login_*` values. If they differ, `null` is returned, forcing a fresh login.

### Customer Lost on Retry
**Root Cause:** If staff changed the active customer between the order creation and a retry 5 minutes later, the retry would use the wrong customer.  
**Mitigation:** The `sapCardCode` is captured at the exact time of order creation and stored in the `Orders` table. All retries use this static snapshot.

---

## 16. Glossary

| Term | Definition |
|---|---|
| **Service Layer** | SAP B1's REST API gateway. Runs on port `50000` at path `/b1s/v1`. |
| **B1SESSION** | The cookie token returned by the Service Layer on successful login. |
| **ROUTEID** | A sticky routing cookie used by load-balanced SAP installations to route requests to the same SAP application server node. |
| **CardCode** | SAP's alphanumeric primary key for a Business Partner (Customer). E.g., `LC00017`. |
| **DocEntry** | SAP's internal integer primary key for any document (Invoice, Payment, etc.). Immutable once created. |
| **DocNum** | SAP's user-visible document number. Sequential within a series. May differ across companies/branches. |
| **Reserve Invoice** | An A/R Invoice type that does not reduce inventory. Used for pre-payments before delivery. Flag: `ReserveInvoice = "tYES"`. |
| **BPL_ID** | Branch/Plant ID. Used in multi-branch SAP installations to associate a document with a specific branch. |
| **VatGroup / TaxCode** | SAP code defining the tax rate and accounting entries for a line item. E.g., `O1` for 16% VAT. |
| **PriceListNum** | An integer key in SAP identifying a specific price list assigned to a customer. |
| **Special Price** | A per-customer, per-item price override stored in `SpecialPrices` entity in SAP. |
| **IncomingPayment** | SAP document recording a receipt of money from a customer, applied against an open invoice. |
| **ODBC -2028** | SAP error "No matching records found" — often triggered by concurrent writes locking the same database transaction. |
| **OData nextLink** | A URL returned in paginated OData responses pointing to the next page of results. |
| **Walk-In Customer** | The default `CardCode` used for anonymous/walk-in customers when no specific customer is selected. |

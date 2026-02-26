# KFM Kiosk Backend Architecture Documentation

This document provides a comprehensive overview of the backend architecture for the KFM Kiosk built with Flutter.

## 1. Architectural Overview

Unlike traditional cloud-hosted backends, the KFM Kiosk implements a **Local Network Master-Client Architecture**. In this setup:
- A designated **Desktop Kiosk** runs an embedded HTTP server and acts as the "Master Node" and authoritative database.
- Other **Mobile/Tablet Kiosks** connect to this Master Node over the local network via HTTP to sync orders, products, and configurations.
- This design ensures the point-of-sale system remains operational locally without requiring a persistent internet connection to a cloud backend.
- Firebase is included in the dependencies (`firebase_core`), but the core kiosk operations (orders, products, configuration) rely on the local embedded server.

---

## 2. Core Backend Components

### 2.1 The Embedded Server (`LocalServerService`)
The primary backend is an embedded HTTP server running directly inside the Flutter application. 

- **File Location:** `lib/core/services/local_server_service.dart`
- **Technology:** Uses the Dart `shelf` and `shelf_router` packages.
- **Port:** The server runs on port `8080` (`InternetAddress.anyIPv4`).
- **Functionality:** 
  - Exposes RESTful API endpoints for client tablets to consume.
  - Interacts directly with the Drift (SQLite) database through DAOs (`OrdersDao`, `ProductsDao`, `TenantConfigDao`, `AppConfigDao`).
  - Maintains an in-memory map (`_connectedTerminals`) to track connected client tablets via a heartbeat mechanism.

#### Key Endpoints (Base Path: `/api/v1`)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | `GET` | Simple health check. Returns `OK`. |
| `/sync/init` | `GET` | Initializes a sync session for a client tablet, returning configuration data based on the active Tenant ID. Also registers the terminal. |
| `/sync/heartbeat` | `POST` | Receives heartbeat pings from tablets to keep them marked as "online" in the connected terminals list. |
| `/config/<tenantId>` | `GET` | Returns full configuration details for a specific tenant (colors, logo, app name). |
| `/sync/logo` | `GET` | Streams the tenant's custom logo file directly from the desktop's local storage. |
| `/products/<tenantId>` | `GET` | Returns all products available for a specific tenant/branch. |
| `/products/images/<filename>`| `GET` | Streams local product images from the `product_images` directory. |
| `/orders` | `GET`, `POST` | Fetches all synced orders or submits a new order to the master database. |
| `/orders/counter` | `GET`, `POST` | Fetches or updates the current order counter (e.g., ORD-001) for the day to prevent duplicate IDs. |

### 2.2 Client Interaction (`OrderRemoteDataSource`)
When the Flutter app is configured as a Mobile/Tablet client, it interacts with the Master Node via remote data sources.

- **File Location:** `lib/features/orders/data/datasources/order_remote_datasource.dart`
- **Technology:** Uses the built-in Dart `http` package.
- **Base URL:** Defined dynamically via `ApiConfig.baseUrl` (e.g., `http://192.168.1.5:8080`).
- **Functionality:** The client converts internal models (`OrderModel`) to JSON and sends them via REST to the `LocalServerService` running on the desktop app.

---

## 3. Database Layer (Drift SQLite)

The backend relies on structured local storage via the `drift` package. The Master Node stores all truth data here.

- **App Config:** Logs tenant information and global application settings (e.g., the current master Order counter).
- **Tenant Config:** Stores UI customization settings specific to a tenant.
- **Products & Orders:** Relational tables managing the menu items and submitted sales/orders.

Data wiping and conflict resolution are managed by carefully handling `upsertOrder` functions with specialized companions in `drift_db`.

---

## 4. Standalone Server (Development / Fallback)

In addition to the embedded `LocalServerService`, the codebase contains a standalone, lightweight Dart HTTP server.

- **File Location:** `server/order_server.dart`
- **Execution:** `dart run server/order_server.dart`
- **Functionality:** Acts as a pure, in-memory sync server for orders. It lacks the SQLite database integration and is generally useful for rapid testing, prototyping, or if the system needs a headless background sync node without running the full Flutter desktop UI.
- **Endpoints Provided:** `/orders`, `/orders/counter`, `/health`.

A supplementary script (`server/verify_multi_client.dart`) is provided to test the concurrency of this standalone server by simulating multiple active terminals submitting orders concurrently.

---

## 5. Security and Networking Considerations

- **CORS:** The standalone server implements blanket CORS (`Access-Control-Allow-Origin: *`). The embedded `shelf` server relies heavily on being on a trusted local subnet.
- **Authentication:** Currently, there is an `AuthBloc` present in the UI layer, but the local REST API endpoints (like `/api/v1/orders`) do not enforce strict token-based security or HMAC signatures. Security relies on physical/network boundary access controls (Wi-Fi password & routing).
- **IP Resolution:** The Desktop kiosk resolves its IP via `NetworkInfo().getWifiIP()` and displays this to users so they can input it into the mobile tablet Settings.

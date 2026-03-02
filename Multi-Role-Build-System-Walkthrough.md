# Multi-Role Build System Walkthrough

I have implemented a flexible build system that allows you to generate distinct `.exe` files for different roles from the same codebase.

## New Files
- `lib/core/config/app_role.dart`: Defines roles (`kiosk`, `warehouse`, `staff`, `superAdmin`, `dashboard`) and their configurations.
- `lib/main_warehouse.dart`: Entry point for Warehouse Admin.
- `lib/main_superadmin.dart`: Entry point for Super Admin.
- `lib/main_dashboard.dart`: Entry point for Enterprise Dashboard.
- `lib/main_staff.dart`: Entry point for Staff Panel (consolidated Branch Manager and Staff roles).
- `lib/main_terminal.dart`: Entry point for Kiosk Terminal (alternative to `main.dart`).

## Distribution Strategy

When delivering executable files to your clients, distribute them based on their subscription tier:

### For Standard, Premium, and Alone Tiers:
These clients do not have branch architecture or enterprise features. Provide them with:
- **SSS Kiosk Terminal (`lib/main.dart`)**: The primary point of sale for customers.
- **SSS Staff Panel (`lib/main_staff.dart`)**: For staff to process and manage orders.

### For Enterprise Tier:
Provide the full specialized suite:
- **SSS Kiosk Terminal**: For customer orders (Client mode).
- **SSS Staff Panel**: (Optional) For branch order processing.
- **SSS Warehouse Admin**: For warehouse-specific order fulfillment.
- **SSS Branch Manager**: For the main branch PC (Acts as Local Server).
- **SSS Enterprise Dashboard**: For multi-branch analytics and management.

## How to Build Separate EXEs

To generate the specific Windows executable for each role, run these commands in your terminal:

### 1. Kiosk Terminal (Default/Terminal build)
```bash
# Both of these produce the Terminal UI
flutter build windows --target lib/main.dart
flutter build windows --target lib/main_terminal.dart
```

### 2. Staff & Admin Panel
```bash
# Used for order processing and running the local server
flutter build windows --target lib/main_staff.dart
# OR for enterprise branding
flutter build windows --target lib/main_branch.dart
```

### 3. Warehouse Admin
```bash
flutter build windows --target lib/main_warehouse.dart
```

### 4. Branch Manager
```bash
flutter build windows --target lib/main_branch.dart
```

### 5. Enterprise Dashboard
```bash
flutter build windows --target lib/main_dashboard.dart
```

### 6. Super Admin
```bash
flutter build windows --target lib/main_superadmin.dart
```

## Security & Access Control
The `LoginScreen` actively checks the `RoleConfig` of the current build against the authenticated user. **A user cannot log in to the wrong application.**
- A **Warehouse Admin** cannot log in to the Manager App.
- A **Super Admin** cannot log in to the Warehouse App.
- Standard/Premium tenants cannot log in to the Enterprise Dashboard.
- If a user attempts to use the wrong executable, they will receive an **Access Denied** message instructing them to use the correct application.

## How it Works
- Each entry point calls `mainWithRole(AppRole.xxx)`.
- The `KFMKioskApp` receives a `RoleConfig` which automatically updates the **Window Title** and can be used to hide/show specific UI features based on the build type.
- The `LocalServerService` uses this role and the Tenant's Tier to determine if it should start broadcasting on the network.

## Remote Security (Cloud Heartbeat)
Even though the apps work offline, they now perform a sub-second "Heartbeat" check to `https://api.sss-kiosk.com` on startup.
- **Remote Blocking:** If you mark a tenant as `Inactive` in your cloud database, their local `.exe` will automatically lock itself and show a **"Subscription Expired"** screen.
- **Offline Grace Period:** If the internet is down, the system allows the store to continue for **7 days** before requiring a connection to verify the license.

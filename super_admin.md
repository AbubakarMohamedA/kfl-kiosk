# Super Admin Functionalities

The Super Admin role is responsible for managing tenants, viewing system-wide analytics, and configuring global system settings. Below is a detailed list of functionalities available to the Super Admin and the files where these functionalities are implemented.

## Functionalities

### 1. Dashboard & Navigation
- **Header Statistics**: Real-time view of total tenants and active tenants.
- **Add Tenant**: Quick access button to onboard new tenants.
- **Sidebar Navigation**: easy navigation between Tenants, Analytics, and Settings tabs.
- **Quick Stats**: Sidebar summary of Active, Pending, and Inactive tenants.

### 2. Tenant Management
Located in the "Tenants" tab.
- **List View**: Displays all registered tenants with their key details (Business Name, Owner Name, Contact Info).
- **Search & Filter**:
  - Search by Name, Business Name, Email, or Tenant ID.
  - Filter by Status (All, Active, Inactive, Pending).
- **Status Indicators**: Visual color codes for Active (Green), Pending (Orange), and Inactive (Red) statuses.
- **Badges**: Special badges for "PREMIUM" tier and "MAINTENANCE" mode.
- **Actions**:
  - **View Details**: View comprehensive tenant information.
  - **Edit Tenant**: Modify tenant details.
  - **Delete Tenant**: Remove a tenant from the system.
  - **Manage Features**: Enable or disable specific modules (Orders, History, Insights, Warehouse) for each tenant via the Edit dialog.

### 3. Analytics
Located in the "Analytics" tab.
- **Overview Cards**:
  - Total Revenue (System-wide)
  - Total Orders (System-wide)
  - Active Tenants Count
  - Average Revenue per Tenant
- **Top Performers**: A ranked list of the top 3 tenants based on revenue, highlighting their performance contribution.

### 4. System Settings
Located in the "Settings" tab.
- **Default Tenant Settings**: Configuration for new tenants (Auto-approve, Welcome email, Order notifications).
- **Security**: System-wide security toggles (2FA, Session timeout, IP whitelisting).
- **Notifications**: Control over system notification channels (Email, SMS, Push).
- **System Control**:
  - **Maintenance Mode (Full System)**: A master switch to put the entire system into maintenance mode, blocking access for regular users.
- **Module Maintenance**: Granular control to toggle maintenance mode for specific modules:
  - Orders Module
  - Order History
  - Business Insights
  - Warehouse Stations

---

## Files & Implementation

### 1. UI Implementation
**File:** `lib/features/admin/presentation/screens/super_admin_screen.dart`
- Contains the entire UI layout for the Super Admin dashboard.
- Implements the `TabController` for switching between Tenants, Analytics, and Settings.
- Contains specific widgets for:
  - `_buildHeader()`: Dashboard header and stats.
  - `_buildSidebar()`: Navigation and quick stats.
  - `_buildTenantListTab()`: Tenant listing, search, filtering, and interactions.
  - `_buildAnalyticsTab()`: distinct analytics cards and top tenant list.
  - `_buildSettingsTab()`: All system configuration toggles and maintenance controls.
  - Dialogs for adding (`_showAddTenantDialog`), editing, and viewing tenants.

### 2. Business Logic & Services
**File:** `lib/features/auth/domain/services/tenant_service.dart`
- **Singleton Service**: Manages the state of tenants and system settings.
- **CRUD Operations**: `getTenants()`, `addTenant()`, `updateTenant()`, `deleteTenant()`.
- **Analytics Logic**: `getStats()` calculates total revenue, orders, and averages.
- **Maintenance Logic**:
  - `setMaintenanceMode()` & `isMaintenanceMode`: Global system maintenance.
  - `setModuleMaintenance()` & `isModuleUnderMaintenance()`: Granular module control.
  - `setTenantMaintenanceMode()`: Tenant-specific maintenance.
- **Access Control**:
  - `canAccessSystem()`: Determines login processing based on maintenance modes and tenant status.
  - `canAccessFeature()`: Gates features based on tenant tier (e.g., Premium vs Standard).
  - `login()`: Handles authentication for tenants and Super Admin.

### 3. Data Models
**File:** `lib/features/auth/domain/entities/tenant.dart`
- Defines the `Tenant` entity with fields:
  - `id`, `name`, `businessName`, `email`, `phone`
  - `status`, `tier` (Standard/Premium)
  - `ordersCount`, `revenue`
  - `isMaintenanceMode`
  - `createdDate`, `lastLogin`

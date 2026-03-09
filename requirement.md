# Software and Hardware Requirements - KFL Kiosk Ecosystem

This document outlines the minimum and recommended software and hardware requirements for the **KFL Kiosk** ecosystem to ensure "safe" and reliable operations across all **5 supported platforms** and **6 application flavors**.

---

## 🏗️ Ecosystem Overview

The KFL Kiosk system is a multi-platform, multi-tenant solution designed for diverse operational roles.

### 5 Supported Platforms
1.  **Android** (Mobile/Tablet/Handheld)
2.  **iOS** (iPhone/iPad)
3.  **Linux** (Desktop/Kiosk Terminals)
4.  **Windows** (Desktop/Point of Sale)
5.  **macOS** (Desktop/Management)

### 6 Application Flavors (Roles)
1.  **SSS Admin** (`superadmin`): Global system oversight.
2.  **SSS Manager** (`manager`): Branch-level management.
3.  **SSS Staff** (`staff`): Order processing and fulfillment terminal.
4.  **SSS Warehouse** (`warehouse`): Inventory and stock management.
5.  **SSS Dashboard** (`dashboard`): Real-time analytics and tracking.
6.  **SSS Kiosk** (`kiosk`): Customer-facing self-service terminal.

---

## 💻 Software Requirements

### Common Requirements (All Platforms/Flavors)
-   **Network:** Stable Local Area Network (LAN) for Peer-to-Peer sync.
-   **Internet:** Required for initial setup, license validation, and cloud heartbeat sync.
-   **Firestore/Firebase:** Access to `*.firebaseio.com` and `*.googleapis.com` must not be blocked by firewalls.

### Platform-Specific OS Requirements

| Platform | Minimum Version | Recommended Version |
| :--- | :--- | :--- |
| **Android** | Android 7.1 (API 25) | Android 11.0 or higher |
| **iOS** | iOS 13.0 | iOS 16.0 or higher |
| **Linux** | Ubuntu 20.04 LTS (x64) | Ubuntu 22.04 LTS or higher |
| **Windows** | Windows 10 (64-bit) | Windows 11 (64-bit) |
| **macOS** | macOS 10.15 (Catalina) | macOS 13.0 (Ventura) or higher |

---

## 🔌 Hardware Requirements (Safe & Reliable)

To ensure "safe" operation under heavy use (especially for the local sync server and database), we recommend the following hardware tiers.

### 🏢 Tier 1: Primary Terminals (Staff Server & Super Admin)
*These devices often act as the Local Sync Server host.*

-   **CPU:** Quad-core 2.5GHz+ (Intel i5/AMD Ryzen 5 or equivalent).
-   **RAM:** 8GB DDR4 (Minimum 4GB).
-   **Storage:** 128GB **SSD** (NVMe preferred for high transaction volume).
-   **Display:** 1080p Full HD resolution.
-   **Connectivity:** Ethernet (RJ45) strongly recommended for the Server host.

### 🛒 Tier 2: Customer Kiosks & Manager Displays
*Optimized for visual performance and touch interaction.*

-   **CPU:** Dual-core 2.0GHz+.
-   **RAM:** 4GB DDR4 (Minimum 2GB).
-   **Storage:** 32GB SSD/eMMC.
-   **Display:** 10" to 22" Touchscreen (10-point multi-touch).
-   **Peripherals:** Support for USB/Ethernet Thermal Printers (ESC/POS).

### 📦 Tier 3: Warehouse & Mobile Handhelds
*Optimized for portability and rapid scanning.*

-   **CPU:** Octa-core ARM (for Android/iOS).
-   **RAM:** 3GB+ (Minimum 2GB).
-   **Storage:** 16GB+ available space.
-   **Camera:** 8MP+ with Autofocus (for barcode/QR scanning).
-   **Battery:** 5000mAh+ (if mobile).

---

## 🖨️ Peripheral Compatibility

| Peripheral | Connection Type | Requirement |
| :--- | :--- | :--- |
| **Receipt Printer** | USB / Ethernet / BT | ESC/POS Command Set compatible |
| **Barcode Scanner** | USB / Bluetooth | HID (Keyboard) mode support |
| **Payment Terminal** | API / Network | M-Pesa Integration (handled via Software) |

---

## 🛡️ "Safe" Operation Guidelines

1.  **Database Health:** For stores handling >1,000 orders/day, use a dedicated Desktop (Linux/Windows) as the Staff Server with an SSD to prevent write-latency during sync.
2.  **Network Stability:** Avoid using Public Wi-Fi for Local Sync. Use a dedicated WPA3-secured Router or Wired Ethernet.
3.  **Power:** Kiosk terminals should be connected to a UPS (Uninterruptible Power Supply) to prevent database corruption during sudden power loss, although SQLite offers robust ACID protections.

---
*Generated for KFL Kiosk Enterprise Solution - v1.0.0*

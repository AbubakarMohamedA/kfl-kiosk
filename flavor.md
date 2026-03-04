# KFL Kiosk - Flavor Build Guide

This document outlines how to build and run the various role-based flavors of the KFL application across all 5 supported platforms (Android, iOS, macOS, Windows, and Linux). 

We use a custom multi-platform flavor implementation to allow all apps to be installed simultaneously on a single device without overwriting each other.

---

## The 6 App Roles & Entry Points
| Role | Flavor Name | App Name | Internal App ID / Executable | Entry Point |
|---|---|---|---|---|
| Super Admin | `superadmin` | SSS Admin | `com.techbizafrica.kflkiosk.superadmin` | `lib/main_superadmin.dart` |
| Manager | `manager` | SSS Manager | `com.techbizafrica.kflkiosk.manager` | `lib/main_branch.dart` |
| Staff | `staff` | SSS Staff | `com.techbizafrica.kflkiosk.staff` | `lib/main_staff.dart` |
| Warehouse | `warehouse` | SSS Warehouse | `com.techbizafrica.kflkiosk.warehouse` | `lib/main_warehouse.dart` |
| Dashboard | `dashboard` | SSS Dashboard | `com.techbizafrica.kflkiosk.dashboard` | `lib/main_dashboard.dart` |
| Kiosk | `kiosk` | SSS Kiosk | `com.techbizafrica.kflkiosk.kiosk` | `lib/main_terminal.dart` |

---

## 📱 Platform 1: Android
Android utilizes native Gradle `productFlavors` defined in `android/app/build.gradle.kts`. You can build these directly using the standard Flutter `--flavor` flag.

**Run / Debug:**
```bash
flutter run --flavor <flavor_name> -t <entry_point>
```
**Build APK / AppBundle:**
```bash
flutter build apk --flavor <flavor_name> -t <entry_point>
flutter build appbundle --flavor <flavor_name> -t <entry_point>
```
*Example (Staff Role):*
```bash
flutter build apk --flavor staff -t lib/main_staff.dart
```

---

## 🍏 Platform 2 & 3: iOS and macOS
Apple platforms are managed by our custom `set_flavor.sh` script, which safely injects the Bundle Identifiers and App Names into `project.pbxproj`, `Info.plist`, and `AppInfo.xcconfig` right before you compile.

**Step 1: Apply the Flavor Configuration**
```bash
./set_flavor.sh <flavor_name>
```

**Step 2: Run / Debug:**
```bash
flutter run -d ios -t <entry_point>
flutter run -d macos -t <entry_point>
```

**Step 3: Build Release:**
```bash
flutter build ipa -t <entry_point>
flutter build macos -t <entry_point>
```
*Example (Warehouse Role on iOS):*
```bash
./set_flavor.sh warehouse
flutter build ipa -t lib/main_warehouse.dart
```

---

## 🪟 Platform 4: Windows
Windows utilizes CMake environment variables. Standard Flutter deskop builds do not natively support the `--flavor` flag. Instead, pass the `FLAVOR` environment variable, which `CMakeLists.txt` and `Runner.rc` will read.

**Run / Debug (PowerShell / Bash):**
```bash
export FLAVOR=<flavor_name> && flutter run -d windows -t <entry_point>
```

**Build Release:**
```bash
export FLAVOR=<flavor_name> && flutter build windows -t <entry_point>
```
*Example (Super Admin Role):*
```bash
export FLAVOR=superadmin && flutter build windows -t lib/main_superadmin.dart
```
*(Note for Windows CMD users: Use `set FLAVOR=superadmin && flutter build windows ...`)*

---

## 🐧 Platform 5: Linux
Linux operates exactly the same as Windows, utilizing CMake environment variables to dynamically compile unique GTK Application IDs and binary executables.

**Run / Debug:**
```bash
export FLAVOR=<flavor_name> && flutter run -d linux -t <entry_point>
```

**Build Release:**
```bash
export FLAVOR=<flavor_name> && flutter build linux -t <entry_point>
```
*Example (Kiosk Role):*
```bash
export FLAVOR=kiosk && flutter build linux -t lib/main_terminal.dart
```

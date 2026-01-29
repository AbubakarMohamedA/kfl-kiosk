# KFM Self-Service Kiosk 🏪

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-green)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**A modern, bilingual self-service kiosk application for Kitui Flour Mills**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Architecture](#architecture) • [Contributing](#contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [Usage Guide](#usage-guide)
  - [Customer Interface](#customer-interface)
  - [Staff Panel](#staff-panel)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Technologies Used](#technologies-used)
- [Configuration](#configuration)
- [Testing](#testing)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## 🎯 Overview

KFM Self-Service Kiosk is a comprehensive point-of-sale solution designed specifically for Kitui Flour Mills. This application enables customers to browse products, place orders, and make payments through M-Pesa, while providing staff with powerful tools to manage orders and track business analytics.

### Key Highlights

- 🌍 **Bilingual Support**: Full English and Kiswahili localization
- 📱 **Multi-Platform**: Works on mobile, tablet, desktop, and web
- 💳 **M-Pesa Integration**: Seamless mobile payment processing
- 📊 **Real-Time Analytics**: Live business insights and order tracking
- 🎨 **Responsive Design**: Adaptive UI for all screen sizes
- 🔄 **Offline Capability**: Works without constant internet connection

---

## ✨ Features

### Customer Features

#### 🛒 Product Browsing
- Browse 30+ products across multiple categories
- Filter by flour type (All Purpose, Maize, Chapati, Atta, etc.)
- View detailed product information (brand, size, price, description)
- Search functionality for quick product discovery

#### 🛍️ Shopping Cart
- Add/remove items with real-time updates
- Adjust quantities on the fly
- View running totals and item counts
- Cart persistence during session

#### 💰 Payment Processing
- M-Pesa mobile money integration
- Intuitive phone number entry with validation
- Real-time payment status updates
- Automatic order generation upon successful payment

#### 🧾 Order Receipts
- Digital receipts with order details
- Unique order ID for pickup reference
- Timestamp and itemized breakdown
- Auto-return to home screen

### Staff Features

#### 📱 Order Management Dashboard
- Real-time order status tracking
- Color-coded status badges (Paid, Preparing, Ready, Fulfilled)
- One-click status updates
- Order search and filtering capabilities

#### 📊 Business Analytics
- Today's sales metrics
- Order completion rates
- Peak hour analysis
- Hourly revenue trends
- Average preparation times

#### 🔍 Advanced Filtering
- Filter by order status
- Search by Order ID or phone number
- Sort by date, time, or value
- Separate views for active orders and history

#### 📈 Live Insights Panel
- Real-time order flow visualization
- Performance metrics
- Revenue summaries
- Trend charts

---

## 📸 Screenshots

### Customer Interface

```
┌─────────────────────────────────┐
│     Welcome to KFM Kiosk        │
│  [English] [Kiswahili] Toggle   │
│                                 │
│   🏢 Kitui Flour Mills Logo     │
│                                 │
│     [Start Order Button]        │
└─────────────────────────────────┘
```

### Product Catalog

```
┌─────────────────────────────────┐
│  Select Items         🛒 Cart(3)│
├─────────────────────────────────┤
│ [All] [Flour] [Premium] [Oil]   │
├─────────────────────────────────┤
│ ┌───────┐  ┌───────┐  ┌───────┐│
│ │Product│  │Product│  │Product││
│ │Image  │  │Image  │  │Image  ││
│ │Name   │  │Name   │  │Name   ││
│ │Price  │  │Price  │  │Price  ││
│ │[Add]  │  │[Add]  │  │[Add]  ││
│ └───────┘  └───────┘  └───────┘│
└─────────────────────────────────┘
```

### Staff Panel

```
┌─────────────────────────────────────────┐
│  Staff Command Center    🕐 14:30:45    │
├───────┬─────────────────────────────────┤
│       │  Active Orders                  │
│ Dash  │  ┌──────────────────────────┐  │
│       │  │ ORD0001  [PAID]    KSh500│  │
│ Hist  │  │ 14:25  +254712345678     │  │
│       │  │ [Start Preparing]        │  │
│ Analy │  └──────────────────────────┘  │
│       │                                 │
│ Inven │  ┌──────────────────────────┐  │
│       │  │ ORD0002  [PREPARING] 750 │  │
│ Staff │  │ 14:20  +254723456789     │  │
│       │  │ [Mark as Ready]          │  │
└───────┴─────────────────────────────────┘
```

---

## 🔧 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.0 or higher)
   ```bash
   # Check Flutter installation
   flutter --version
   ```

2. **Dart SDK** (3.0 or higher) - Comes with Flutter

3. **IDE** (Choose one):
   - Visual Studio Code with Flutter/Dart extensions
   - Android Studio with Flutter plugin
   - IntelliJ IDEA with Flutter plugin

4. **Git**
   ```bash
   git --version
   ```

### Platform-Specific Requirements

#### For Android Development
- Android Studio
- Android SDK (API level 21 or higher)
- Android Emulator or physical device

#### For iOS Development (macOS only)
- Xcode (latest version)
- CocoaPods
- iOS Simulator or physical device

#### For Web Development
- Chrome browser for debugging

#### For Desktop Development
- **Windows**: Visual Studio 2019 or later with C++ tools
- **macOS**: Xcode
- **Linux**: clang, cmake, ninja-build, pkg-config, and GTK development libraries

---

## 📦 Installation

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/your-organization/kfm-kiosk.git

# Navigate to project directory
cd kfm-kiosk
```

### Step 2: Install Dependencies

```bash
# Get all Flutter packages
flutter pub get

# Verify installation
flutter doctor
```

### Step 3: Configure the Application

No additional configuration is required for basic operation. The app uses:
- In-memory data storage
- Mock payment processing
- Local state management

---

## 🚀 Running the Application

### Development Mode

#### Mobile (Android/iOS)

```bash
# Run on connected device or emulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

#### Web

```bash
# Run on web browser
flutter run -d chrome

# Or with specific port
flutter run -d chrome --web-port=8080
```

#### Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Production Build

#### Android APK

```bash
# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output location: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS

```bash
# Build iOS app
flutter build ios --release

# Output in Xcode for further processing
```

#### Web

```bash
# Build web application
flutter build web --release

# Output location: build/web/
```

#### Desktop

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 📖 Usage Guide

### Customer Interface

#### Starting an Order

1. **Launch the Application**
   - On desktop: Opens with Staff Panel by default
   - On mobile/tablet: Opens with Customer Home Screen

2. **Select Language**
   - Choose between English and Kiswahili
   - Language preference persists throughout the session

3. **Browse Products**
   - Tap "Start Order" / "Anza Oda"
   - Browse categories using the filter chips at the top
   - Scroll through product grid

4. **Add Items to Cart**
   - Tap "Add to Cart" on desired products
   - View cart count in the top-right corner
   - Items are added with quantity of 1 by default

5. **Review Cart**
   - Tap the cart icon (mobile/tablet)
   - Review items, adjust quantities using +/- buttons
   - Remove items by tapping the delete icon

6. **Proceed to Payment**
   - Tap "Proceed to Payment" / "Endelea Kulipa"
   - Review order summary in confirmation dialog (desktop)
   - Confirm order details

7. **Make Payment**
   - Enter M-Pesa phone number (9 digits)
     - Must start with 1 or 7
     - Format: +254XXXXXXXXX
   - Tap the green checkmark (✓) button
   - Wait for payment processing

8. **Receive Receipt**
   - View digital receipt with order details
   - Note your Order ID (e.g., ORD0001)
   - Screen automatically returns to home after 15 seconds

### Staff Panel

#### Accessing Staff Features

**Desktop Users:**
- Application opens directly to Staff Panel
- To access customer kiosk: Click "Customer Kiosk" in sidebar

**Mobile/Tablet Users:**
- Staff panel optimized for larger screens
- Access via separate staff device or desktop view

#### Managing Orders

##### Active Orders Dashboard

1. **View All Orders**
   - Main dashboard shows active orders by default
   - Orders displayed in reverse chronological order (newest first)

2. **Filter Orders**
   - Use dropdown to filter by status:
     - All Orders
     - Paid (🔵 Blue)
     - Preparing (🟠 Orange)
     - Ready for Pickup (🟣 Purple)

3. **Search Orders**
   - Search by Order ID (e.g., ORD0001)
   - Search by phone number
   - Real-time search results

##### Processing Orders

**Step 1: Paid Orders (🔵 Blue Badge)**
```
Action: Click "Start Preparing Order"
Result: Status changes to PREPARING
```

**Step 2: Preparing Orders (🟠 Orange Badge)**
```
Action: Click "Mark as Ready for Pickup"
Result: Status changes to READY FOR PICKUP
```

**Step 3: Ready Orders (🟣 Purple Badge)**
```
Action: Click "Mark as Fulfilled (Customer Picked Up)"
Result: Status changes to FULFILLED
Note: Customer must present Order ID at pickup counter
```

**Step 4: Fulfilled Orders (🟢 Green Badge)**
```
Status: Order Complete
Location: Moved to Order History
```

#### Order History

1. **Access History**
   - Click "Order History" in sidebar
   - View all completed orders

2. **Browse History**
   - Orders grouped by date
   - Most recent dates shown first
   - Expandable date sections

3. **View Details**
   - Click "View Details" on any order
   - See complete order breakdown
   - View customer information

#### Analytics & Insights

##### Live Insights Panel (Right Sidebar)

**Order Flow**
- Current count of orders in each status
- Real-time updates as orders progress

**Performance Metrics**
- Completion rate (percentage)
- Average preparation time
- Peak hour information

**Revenue Summary**
- Today's total sales
- Average order value
- Total number of orders

**Hourly Trends Chart**
- Visual representation of order volume
- Helps identify busy periods

##### Quick Stats (Left Sidebar)

- Today's order count
- Today's revenue
- Active orders count

---

## 📁 Project Structure

```
kfm_kiosk/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # App-wide constants
│   │   ├── error/
│   │   │   └── failures.dart            # Error handling
│   │   ├── platform/
│   │   │   └── platform_info.dart       # Platform detection
│   │   └── utils/
│   │       └── validators.dart          # Input validation
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local_cart_datasource.dart
│   │   │   ├── local_order_datasource.dart
│   │   │   ├── local_product_datasource.dart
│   │   │   └── mock_payment_datasource.dart
│   │   ├── models/
│   │   │   ├── cart_item_model.dart
│   │   │   ├── order_model.dart
│   │   │   └── product_model.dart
│   │   └── repositories/
│   │       ├── cart_repository_impl.dart
│   │       ├── order_repository_impl.dart
│   │       ├── payment_repository_impl.dart
│   │       └── product_repository_impl.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── cart_item.dart
│   │   │   ├── order.dart
│   │   │   └── product.dart
│   │   ├── repositories/
│   │   │   └── repositories.dart
│   │   └── usecases/
│   │       ├── cart_usecases.dart
│   │       ├── order_usecases.dart
│   │       ├── payment_usecases.dart
│   │       └── product_usecases.dart
│   │
│   ├── presentation/
│   │   ├── bloc/
│   │   │   ├── cart/
│   │   │   ├── language/
│   │   │   ├── order/
│   │   │   ├── payment/
│   │   │   └── product/
│   │   ├── screens/
│   │   │   ├── desktop/
│   │   │   ├── mobile/
│   │   │   ├── tablet/
│   │   │   └── web/
│   │   └── widgets/
│   │       ├── common/
│   │       ├── desktop/
│   │       └── mobile/
│   │
│   ├── di/
│   │   └── injection.dart               # Dependency injection
│   │
│   └── main.dart                        # Application entry point
│
├── test/                                # Unit and widget tests
├── integration_test/                    # Integration tests
├── assets/                              # Images and resources
├── pubspec.yaml                         # Dependencies
└── README.md                            # This file
```

### Key Directories Explained

#### `/core`
Contains shared utilities, constants, and platform-specific code used throughout the app.

#### `/data`
Implements data layer with data sources, models, and repository implementations.

#### `/domain`
Contains business logic, entities, and repository interfaces (Clean Architecture).

#### `/presentation`
UI layer with BLoC state management, screens, and widgets organized by platform.

#### `/di`
Dependency injection configuration using GetIt.

---

## 🏗️ Architecture

### Clean Architecture Pattern

The application follows Uncle Bob's Clean Architecture principles with three main layers:

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│  (BLoC, Screens, Widgets)                  │
├─────────────────────────────────────────────┤
│            Domain Layer                     │
│  (Entities, UseCases, Repositories)        │
├─────────────────────────────────────────────┤
│             Data Layer                      │
│  (Models, DataSources, Repository Impls)   │
└─────────────────────────────────────────────┘
```

### State Management

**BLoC (Business Logic Component) Pattern**

```dart
User Action → Event → BLoC → State → UI Update
```

Components:
- **Events**: User actions (AddToCart, UpdateOrderStatus)
- **States**: UI states (CartLoaded, OrdersLoaded)
- **BLoCs**: Business logic processors

### Dependency Injection

Uses **GetIt** for service locator pattern:

```dart
// Registration
getIt.registerLazySingleton<Repository>(() => RepositoryImpl());

// Usage
final repository = getIt<Repository>();
```

### Responsive Design Strategy

```dart
Width < 600px    → Mobile Layout
600-1200px       → Tablet Layout
> 1200px         → Desktop Layout
Web Platform     → Optimized Web Layout
```

---

## 🛠️ Technologies Used

### Framework & Language
- **Flutter 3.0+**: UI framework
- **Dart 3.0+**: Programming language

### State Management
- **flutter_bloc**: BLoC pattern implementation
- **equatable**: Value equality for states/events

### Architecture
- **GetIt**: Dependency injection
- **Clean Architecture**: Separation of concerns

### Data Persistence
- **In-Memory Storage**: Fast, session-based data

### UI Components
- **Material Design 3**: Modern UI components
- **Custom Widgets**: Reusable component library

### Utilities
- **intl**: Internationalization and date formatting
- **json_annotation**: JSON serialization

---

## ⚙️ Configuration

### App Constants

Edit `lib/core/constants/app_constants.dart` to customize:

```dart
class AppConstants {
  // App Information
  static const String appName = 'KFM Self-Service Kiosk';
  static const String appVersion = '1.0.0';
  
  // Timing
  static const Duration idleTimeout = Duration(minutes: 2);
  static const Duration receiptDisplayDuration = Duration(seconds: 15);
  
  // Order Status
  static const String statusPaid = 'PAID';
  static const String statusPreparing = 'PREPARING';
  // ... more statuses
  
  // Colors (in AppColors class)
  static const int primaryBlue = 0xFF0B8843;    // KFM Green
  static const int secondaryGold = 0xFF0A5730;  // Dark Green
}
```

### Product Catalog

Modify products in `lib/data/datasources/local_product_datasource.dart`:

```dart
List<ProductModel> getAllProducts() {
  return [
    const ProductModel(
      id: 'product_id',
      name: 'Product Name',
      brand: 'Brand Name',
      price: 100.0,
      size: '1kg',
      category: 'Flour',
      description: 'Product description',
    ),
    // Add more products...
  ];
}
```

### Language Strings

Add/modify translations in `lib/core/constants/app_constants.dart`:

```dart
class AppStrings {
  static const Map<String, String> en = {
    'welcome': 'Welcome to',
    'start_order': 'Start Order',
    // Add more English strings...
  };
  
  static const Map<String, String> sw = {
    'welcome': 'Karibu',
    'start_order': 'Anza Oda',
    // Add more Swahili strings...
  };
}
```

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/domain/usecases/cart_usecases_test.dart

# Run integration tests
flutter test integration_test
```

### Test Structure

```
test/
├── core/
│   ├── utils/
│   │   └── validators_test.dart
│   └── constants/
│       └── app_constants_test.dart
├── data/
│   ├── models/
│   │   ├── product_model_test.dart
│   │   ├── cart_item_model_test.dart
│   │   └── order_model_test.dart
│   ├── datasources/
│   │   └── local_cart_datasource_test.dart
│   └── repositories/
│       └── cart_repository_impl_test.dart
├── domain/
│   ├── entities/
│   │   └── product_test.dart
│   └── usecases/
│       └── cart_usecases_test.dart
└── presentation/
    ├── bloc/
    │   └── cart_bloc_test.dart
    └── widgets/
        └── product_card_test.dart
```

### Writing Tests

Example unit test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm_kiosk/domain/entities/product.dart';

void main() {
  group('Product Entity', () {
    test('should create product with correct properties', () {
      final product = Product(
        id: 'test_id',
        name: 'Test Product',
        brand: 'Test Brand',
        price: 100.0,
        size: '1kg',
        category: 'Flour',
        description: 'Test description',
      );

      expect(product.id, 'test_id');
      expect(product.name, 'Test Product');
      expect(product.price, 100.0);
    });
  });
}
```

---

## 🚢 Deployment

### Mobile Deployment

#### Android Play Store

1. **Prepare Release Build**
   ```bash
   flutter build appbundle --release
   ```

2. **Sign the App**
   - Create keystore
   - Configure signing in `android/app/build.gradle`

3. **Upload to Play Console**
   - Create app listing
   - Upload AAB file
   - Submit for review

#### iOS App Store

1. **Prepare Release Build**
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode**
   - Open `ios/Runner.xcworkspace`
   - Product → Archive

3. **Upload to App Store Connect**
   - Use Xcode Organizer
   - Submit for review

### Web Deployment

#### Build for Production

```bash
flutter build web --release
```

#### Deploy to Hosting

**Firebase Hosting:**
```bash
firebase init hosting
firebase deploy
```

**GitHub Pages:**
```bash
# Build
flutter build web --release --base-href "/kfm-kiosk/"

# Copy build/web to gh-pages branch
```

**Netlify/Vercel:**
- Connect repository
- Set build command: `flutter build web --release`
- Set publish directory: `build/web`

### Desktop Deployment

#### Windows

```bash
flutter build windows --release
```

Package with installer tool (e.g., Inno Setup, NSIS)

#### macOS

```bash
flutter build macos --release
```

Create DMG or use notarization for App Store

#### Linux

```bash
flutter build linux --release
```

Package as .deb, .rpm, or AppImage

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Flutter doctor shows issues

```bash
# Run
flutter doctor -v

# Fix Android license issues
flutter doctor --android-licenses

# Fix iOS setup (macOS)
sudo gem install cocoapods
pod setup
```

#### Issue: Build fails on first run

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

#### Issue: Hot reload not working

```bash
# Restart app
R (in terminal where flutter run is active)

# Or stop and restart
flutter run
```

#### Issue: M-Pesa payment not working

This is expected - the app uses mock payment processing. To integrate real M-Pesa:
1. Obtain M-Pesa API credentials from Safaricom
2. Implement Daraja API integration
3. Replace `MockPaymentDataSource` with real implementation

#### Issue: Products not showing

```bash
# Check ProductBloc initialization
flutter logs

# Verify data source
# Check lib/data/datasources/local_product_datasource.dart
```

#### Issue: App crashes on startup

```bash
# Check logs
flutter logs

# Common fixes:
flutter clean
flutter pub get
flutter run --verbose
```

### Platform-Specific Issues

#### Android

**Issue: Gradle build errors**
```bash
cd android
./gradlew clean
cd ..
flutter run
```

#### iOS

**Issue: CocoaPods errors**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

#### Web

**Issue: CORS errors**
- Use `--web-renderer html` flag
- Configure web server CORS headers

---

## 🤝 Contributing

We welcome contributions to the KFM Self-Service Kiosk project!

### Development Setup

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone
   git clone https://github.com/YOUR_USERNAME/kfm-kiosk.git
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow existing code style
   - Write tests for new features
   - Update documentation

4. **Test Your Changes**
   ```bash
   flutter test
   flutter analyze
   ```

5. **Commit and Push**
   ```bash
   git commit -m "Add: Brief description of changes"
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Open PR on GitHub
   - Describe changes and motivation
   - Reference any related issues

### Code Style Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Maintain consistent formatting (use `dart format`)

### Commit Message Convention

```
Type: Brief description (max 50 characters)

Detailed explanation if needed (wrap at 72 characters)

- Bullet points for multiple changes
- Reference issues: Fixes #123
```

Types: `Add`, `Fix`, `Update`, `Remove`, `Refactor`, `Doc`

---

## 📄 License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2024 Kitui Flour Mills

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Contact

### Project Maintainers

- **Project Lead**: [Your Name]
  - Email: lead@kituiflourmills.com
  - GitHub: [@yourhandle]

- **Technical Lead**: [Tech Lead Name]
  - Email: tech@kituiflourmills.com
  - GitHub: [@techleadhandle]

### Support

- **Bug Reports**: [GitHub Issues](https://github.com/your-organization/kfm-kiosk/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/your-organization/kfm-kiosk/discussions)
- **Email**: support@kituiflourmills.com
- **Documentation**: [Wiki](https://github.com/your-organization/kfm-kiosk/wiki)

### Company Information

**Kitui Flour Mills**
- Website: www.kituiflourmills.com
- Location: Kitui, Kenya
- Business Hours: Monday - Friday, 8:00 AM - 5:00 PM EAT

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Anthropic Claude for development assistance
- Kitui Flour Mills management and staff for requirements and testing
- Open-source community for various packages and tools

---

## 🗺️ Roadmap

### Version 1.1 (Q2 2024)
- [ ] Real M-Pesa API integration
- [ ] Database persistence (SQLite/Hive)
- [ ] Receipt printing support
- [ ] Multi-currency support

### Version 1.2 (Q3 2024)
- [ ] Loyalty program integration
- [ ] Inventory management
- [ ] Advanced analytics dashboard
- [ ] Customer accounts

### Version 2.0 (Q4 2024)
- [ ] Online ordering integration
- [ ] Delivery management
- [ ] Multi-store support
- [ ] API for third-party integrations

---

## 📚 Additional Resources

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [BLoC Pattern Guide](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Tutorials
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [State Management Guide](https://docs.flutter.dev/development/data-and-backend/state-mgmt)
- [Platform Integration](https://docs.flutter.dev/development/platform-integration)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit r/FlutterDev](https://www.reddit.com/r/FlutterDev/)

---

<div align="center">

**Built with ❤️ by the KFM Team**

⭐ Star us on GitHub — it helps!

[Report Bug](https://github.com/your-organization/kfm-kiosk/issues) • [Request Feature](https://github.com/your-organization/kfm-kiosk/issues) • [Documentation](https://github.com/your-organization/kfm-kiosk/wiki)


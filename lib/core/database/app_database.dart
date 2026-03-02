import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:kfm_kiosk/core/database/daos/products_dao.dart';
import 'package:kfm_kiosk/core/database/daos/orders_dao.dart';
import 'package:kfm_kiosk/core/database/daos/warehouses_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tenants_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tiers_dao.dart';
import 'package:kfm_kiosk/core/database/daos/cart_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:kfm_kiosk/core/database/daos/branches_dao.dart';
import 'package:kfm_kiosk/core/database/daos/app_config_dao.dart';

part 'app_database.g.dart';

// Keys for AppConfig
class AppConfigKeys {
  static const String licenseKey = 'license_key';
  static const String licenseStatus = 'license_status';
  static const String lastVerified = 'last_verified';
}

/// Product Table
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text()();
  RealColumn get price => real()();
  TextColumn get category => text()();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get tenantId => text().nullable()(); // Added for isolation
  TextColumn get branchId => text().nullable()(); // Added in V14 for Branch-Level isolation
  TextColumn get size => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Orders Table
class Orders extends Table {
  TextColumn get id => text()();
  RealColumn get totalAmount => real()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get tenantId => text().nullable()();
  TextColumn get branchId => text().nullable()();
  TextColumn get terminalId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Order Items Table
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text().references(Orders, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  TextColumn get productName => text()(); // Snapshot of name
  TextColumn get productVariant => text().nullable()(); // Size/Variant snapshot
  TextColumn get status => text().withDefault(const Constant('PAID'))(); // Added in V13
  TextColumn get productCategory => text().withDefault(const Constant(''))(); // Added in V13
}

/// Cart Items Table
class CartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productId => text()(); // Removed FK to Products to allow remote items
  IntColumn get quantity => integer()();
  TextColumn get tenantId => text().nullable()(); 
  TextColumn get productName => text().nullable()();
  RealColumn get productPrice => real().nullable()();
  TextColumn get productImage => text().nullable()();
}

/// App Configuration Table (Key-Value Store)
class AppConfig extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Warehouses Table
class Warehouses extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().nullable()(); // Added for isolation
  TextColumn get branchId => text()();
  TextColumn get name => text()();
  TextColumn get categories => text()(); // JSON List<String>
  TextColumn get loginUsername => text()();
  TextColumn get loginPassword => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Branches Table
class Branches extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  TextColumn get contactPhone => text()();
  TextColumn get managerName => text()();
  TextColumn get loginUsername => text()();
  TextColumn get loginPassword => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Tenants Table
class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get businessName => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get status => text()();
  TextColumn get tierId => text().withDefault(const Constant('standard'))();
  DateTimeColumn get createdDate => dateTime()();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  IntColumn get ordersCount => integer().withDefault(const Constant(0))();
  RealColumn get revenue => real().withDefault(const Constant(0.0))();
  BoolColumn get isMaintenanceMode => boolean().withDefault(const Constant(false))();
  TextColumn get enabledFeatures => text()(); // JSON List<String>
  BoolColumn get allowUpdate => boolean().nullable()();
  BoolColumn get immuneToBlocking => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tiers Table
class Tiers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get enabledFeatures => text()(); // JSON List<String>
  BoolColumn get allowUpdates => boolean().withDefault(const Constant(true))();
  BoolColumn get immuneToBlocking => boolean().withDefault(const Constant(false))();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tenant Configs Table (Syncs to Mobile)
class TenantConfigs extends Table {
  TextColumn get tenantId => text()();
  TextColumn get logoPath => text().nullable()();
  IntColumn get primaryColor => integer().nullable()();
  IntColumn get secondaryColor => integer().nullable()();
  TextColumn get backgroundPath => text().nullable()();
  TextColumn get appName => text().nullable()();
  TextColumn get welcomeMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {tenantId};
}

@DriftDatabase(
  tables: [Products, Orders, OrderItems, AppConfig, Warehouses, Branches, Tenants, Tiers, CartItems, TenantConfigs], 
  daos: [ProductsDao, OrdersDao, WarehousesDao, TenantsDao, TiersDao, CartDao, TenantConfigDao, BranchesDao, AppConfigDao]
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // For testing
  AppDatabase.connect(super.connection);

  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(warehouses);
        }
        if (from < 3) {
          await m.createTable(branches);
        }
        if (from < 4) {
          // Add tenantId to warehouses if it doesn't exist
          await m.addColumn(warehouses, warehouses.tenantId as GeneratedColumn<Object>);
        }
        if (from < 5) {
          await m.createTable(tenants);
          await m.createTable(tiers);
        }
        if (from < 6) {
          await m.createTable(cartItems);
        }
        if (from < 7) {
           await m.addColumn(products, products.tenantId as GeneratedColumn<Object>);
        }
        if (from < 8) {
           await m.createTable(tenantConfigs);
        }
        if (from < 9) {
          // Version 9: Ensure all missing columns added in previous turns are accounted for
          // Use safe migration helpers to avoid "duplicate column" errors
          await _addColumnIfNotExists(m, 'products', products.tenantId as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'orders', orders.tenantId as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'orders', orders.branchId as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'orders', orders.terminalId as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'cart_items', cartItems.tenantId as GeneratedColumn<Object>);
        }
        if (from < 10) {
           // v10 logic (if any specific structural changes were added)
        }
        if (from < 11) {
          // v11: Ensure everything is clean
        }
        if (from < 12) {
          // v12: Enrich cart items with product snapshots for robustness
          await _addColumnIfNotExists(m, 'cart_items', cartItems.productName as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'cart_items', cartItems.productPrice as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'cart_items', cartItems.productImage as GeneratedColumn<Object>);
        }
        if (from < 13) {
          // v13: Add item status and category columns to preserve CartItem integrity for warehouse routing
          await _addColumnIfNotExists(m, 'order_items', orderItems.status as GeneratedColumn<Object>);
          await _addColumnIfNotExists(m, 'order_items', orderItems.productCategory as GeneratedColumn<Object>);
        }
        if (from < 14) {
          // v14: Add branch-level isolation for products
          await _addColumnIfNotExists(m, 'products', products.branchId as GeneratedColumn<Object>);
        }
      },
      beforeOpen: (details) async {
        if (details.wasCreated || details.hadUpgrade) {
          // Perform data migrations AFTER schema is committed. 
          // Note: Use snake_case column names as Drift maps them from camelCase fields.
          await customStatement("UPDATE products SET tenant_id = 'SUPER_ADMIN' WHERE tenant_id IS NULL OR tenant_id = ''");
          await customStatement("UPDATE warehouses SET tenant_id = 'SUPER_ADMIN' WHERE tenant_id IS NULL OR tenant_id = ''");
          await customStatement("UPDATE orders SET tenant_id = 'SUPER_ADMIN' WHERE tenant_id IS NULL OR tenant_id = ''");
          await customStatement("UPDATE cart_items SET tenant_id = 'SUPER_ADMIN' WHERE tenant_id IS NULL OR tenant_id = ''");
        }
      },
    );
  }

  /// Helper to safely add a column only if it doesn't exist
  Future<void> _addColumnIfNotExists(Migrator m, String tableName, GeneratedColumn column) async {
    try {
      final tableInfo = await customSelect('PRAGMA table_info("$tableName")').get();
      final columnExists = tableInfo.any((row) => row.read<String>('name') == column.name);
      
      if (!columnExists) {
        final table = allTables.firstWhere((e) => e.entityName == tableName);
        await m.addColumn(table, column);
        debugPrint('Migration: Added column ${column.name} to $tableName');
      } else {
        debugPrint('Migration: Column ${column.name} already exists in $tableName, skipping.');
      }
    } catch (e) {
      debugPrint('Migration Warning: Could not verify/add column ${column.name} in $tableName: $e');
    }
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the app support folder
    // for your app (app data).
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'kiosk_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

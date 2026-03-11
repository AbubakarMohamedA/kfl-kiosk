import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'dart:io';

void main() {
  test('Fix Product Isolation: Assign SUPER_ADMIN to orphaned products', () async {
    final dbPath = '/home/abubakar/Documents/kiosk_db.sqlite';
    print('Checking database at $dbPath...');
    
    if (!File(dbPath).existsSync()) {
      print('Database not found, skipping fix.');
      return;
    }

    final database = AppDatabase.connect(NativeDatabase(File(dbPath)));
    
    try {
      final products = await database.select(database.products).get();
      print('Total products found: ${products.length}');
      
      int updatedCount = 0;
      for (final product in products) {
        if (product.tenantId == null || product.tenantId!.isEmpty) {
          await (database.update(database.products)..where((tbl) => tbl.id.equals(product.id)))
              .write(const ProductsCompanion(tenantId: Value('SUPER_ADMIN')));
          updatedCount++;
        }
      }
      
      print('Updated $updatedCount products to SUPER_ADMIN.');
      
      // Verify
      final distribution = await (database.selectOnly(database.products)
        ..addColumns([database.products.tenantId, database.products.id.count()]))
        .get();
        
      print('Final Distribution:');
      for (final row in distribution) {
        print('${row.read(database.products.tenantId)}: ${row.read(database.products.id.count())}');
      }
      
    } catch (e) {
      print('Error during fix: $e');
    } finally {
      await database.close();
    }
  });
}

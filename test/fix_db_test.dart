// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sss/core/database/app_database.dart';
import 'dart:io';

void main() {
  test('Fix Product Isolation: Assign SUPER_ADMIN to orphaned products', () async {
    final dbPath = '/home/abubakar/Documents/kiosk_db.sqlite';
    
    if (!File(dbPath).existsSync()) {
      return;
    }

    final database = AppDatabase.connect(NativeDatabase(File(dbPath)));
    
    try {
      final products = await database.select(database.products).get();
      
      int updatedCount = 0;
      for (final product in products) {
        if (product.tenantId == null || product.tenantId!.isEmpty) {
          await (database.update(database.products)..where((tbl) => tbl.id.equals(product.id)))
              .write(const ProductsCompanion(tenantId: Value('SUPER_ADMIN')));
          updatedCount++;
        }
      }
      
      
      // Verify
      final distribution = await (database.selectOnly(database.products)
        ..addColumns([database.products.tenantId, database.products.id.count()]))
        .get();
        
      for (final row in distribution) {
      }
      
    } finally {
      await database.close();
    }
  });
}

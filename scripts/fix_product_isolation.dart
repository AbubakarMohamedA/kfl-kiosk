// ignore_for_file: depend_on_referenced_packages, unused_local_variable

import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = '/home/abubakar/Documents/kiosk_db.sqlite';
  
  if (!File(dbPath).existsSync()) {
    return;
  }

  final db = sqlite3.open(dbPath);
  
  try {
    // Check if tenantId column exists
    final tableInfo = db.select('PRAGMA table_info(products)');
    bool hasTenantId = tableInfo.any((row) => row['name'] == 'tenantId');
    
    if (!hasTenantId) {
      db.execute('ALTER TABLE products ADD COLUMN tenantId TEXT');
    }

    // Assign SUPER_ADMIN to products with NULL tenantId
    db.execute("UPDATE products SET tenantId = 'SUPER_ADMIN' WHERE tenantId IS NULL OR tenantId = ''");
    
    final results = db.select('SELECT tenantId, COUNT(*) as count FROM products GROUP BY tenantId');
    for (final row in results) {
    }
    
  } finally {
    db.dispose();
  }
}

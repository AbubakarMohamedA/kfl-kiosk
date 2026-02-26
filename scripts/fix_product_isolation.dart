import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = '/home/abubakar/Documents/kiosk_db.sqlite';
  print('Opening database at $dbPath...');
  
  if (!File(dbPath).existsSync()) {
    print('Error: Database file not found!');
    return;
  }

  final db = sqlite3.open(dbPath);
  
  try {
    // Check if tenantId column exists
    final tableInfo = db.select('PRAGMA table_info(products)');
    bool hasTenantId = tableInfo.any((row) => row['name'] == 'tenantId');
    
    if (!hasTenantId) {
      print('TenantId column does not exist yet. Running migration...');
      db.execute('ALTER TABLE products ADD COLUMN tenantId TEXT');
    }

    // Assign SUPER_ADMIN to products with NULL tenantId
    print('Updating products with NULL tenantId to SUPER_ADMIN...');
    db.execute("UPDATE products SET tenantId = 'SUPER_ADMIN' WHERE tenantId IS NULL OR tenantId = ''");
    
    final results = db.select('SELECT tenantId, COUNT(*) as count FROM products GROUP BY tenantId');
    print('Update complete. Current product distribution:');
    for (final row in results) {
      print('${row['tenantId']}: ${row['count']}');
    }
    
  } catch (e) {
    print('Failed to migrate data: $e');
  } finally {
    db.dispose();
  }
}

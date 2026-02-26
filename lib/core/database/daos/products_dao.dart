import 'package:drift/drift.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  final AppDatabase db;

  ProductsDao(this.db) : super(db);

  /// Fetch all products (optional filtering by tenant/branch)
  Future<List<Product>> getAllProducts({String? tenantId, String? branchId}) {
    var query = select(products);
    if (tenantId != null) {
      query = query..where((tbl) => tbl.tenantId.equals(tenantId));
    }
    if (branchId != null) {
      query = query..where((tbl) => tbl.branchId.equals(branchId));
    }
    return query.get();
  }

  /// Watch all products (stream)
  Stream<List<Product>> watchAllProducts({String? tenantId, String? branchId}) {
    var query = select(products);
    if (tenantId != null) {
      query = query..where((tbl) => tbl.tenantId.equals(tenantId));
    }
    if (branchId != null) {
      query = query..where((tbl) => tbl.branchId.equals(branchId));
    }
    return query.watch();
  }

  /// Fetch product by ID
  Future<Product?> getProductById(String id) {
    return (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert a product
  Future<int> insertProduct(ProductsCompanion product) => into(products).insert(product);

  /// Insert multiple products
  Future<void> insertProducts(List<ProductsCompanion> productsList) async {
    await batch((batch) {
      batch.insertAll(products, productsList);
    });
  }

  /// Update a product
  Future<bool> updateProduct(ProductsCompanion product) => update(products).replace(product);

  /// Delete a product
  Future<int> deleteProduct(String id) =>
      (delete(products)..where((tbl) => tbl.id.equals(id))).go();
      
  /// Clear all products
  Future<int> clearProducts() => delete(products).go();
}

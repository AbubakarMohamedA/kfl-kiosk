import 'package:sss/core/database/app_database.dart' hide Warehouse;
import 'package:sss/features/warehouse/domain/entities/warehouse.dart';
import 'package:sss/core/database/daos/warehouses_dao.dart';
import 'package:sss/core/database/daos/products_dao.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';

class WarehouseService {
  final WarehousesDao _dao;
  final ProductsDao _productsDao;

  WarehouseService(AppDatabase db) 
    : _dao = db.warehousesDao,
      _productsDao = db.productsDao;

  // Sync warehouses from products categories
  Future<void> syncWarehousesFromProducts(String tenantId, String branchId) async {
    // 1. Fetch all products for the tenant
    final products = await _productsDao.getAllProducts(tenantId: tenantId);
    
    // 2. Extract unique categories
    final Set<String> categories = {};
    for (final product in products) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    
    // 3. Fetch existing warehouses for the branch
    final existingWarehouses = await _dao.getWarehousesForBranch(branchId);
    final existingCategories = <String>{};
    for (final warehouse in existingWarehouses) {
      existingCategories.addAll(warehouse.categories);
    }
    
    // 4. Create new warehouses for missing categories
    for (final category in categories) {
      if (!existingCategories.contains(category)) {
        final newWarehouse = Warehouse(
          id: '${DateTime.now().millisecondsSinceEpoch}_${category.hashCode}',
          tenantId: tenantId,
          branchId: branchId,
          name: '$category Warehouse',
          categories: [category],
          loginUsername: '${category.toLowerCase().replaceAll(' ', '_')}_wh',
          loginPassword: '1234',
          isActive: true,
        );
        await _dao.saveWarehouse(newWarehouse);
        // Sync to cloud
        await TenantService().syncWarehouseToCloud(newWarehouse);
      }
    }
  }

  // Create or Update Warehouse
  Future<void> saveWarehouse(Warehouse warehouse) async {
    await _dao.saveWarehouse(warehouse);
    // Sync to cloud
    final tenantService = TenantService();
    await tenantService.syncWarehouseToCloud(warehouse);
  }

  // Get all warehouses for a branch
  Future<List<Warehouse>> getWarehousesForBranch(String branchId) async {
    return await _dao.getWarehousesForBranch(branchId);
  }

  // Authenticate Staff
  Future<Warehouse?> authenticate(String username, String password) async {
    return await _dao.authenticate(username, password);
  }

  // Delete Warehouse
  Future<void> deleteWarehouse(String id) async {
    await _dao.deleteWarehouse(id);
  }
}

import 'package:sss/features/products/data/datasources/product_remote_datasource.dart';
import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart' hide Product;
import 'package:sss/core/database/daos/products_dao.dart';
import 'package:sss/features/products/data/models/product_model.dart';
 
class LocalProductDataSource implements ProductDataSource {
  final ProductsDao _productsDao;
 
  LocalProductDataSource(this._productsDao);
 
  // Seed data (preserved for initialization)
  final List<ProductModel> _seedProducts = [
      // Unga Wa Dola - All Purpose Flour
      const ProductModel(
        id: 'uwd_ap_flour_2kg',
        name: 'Premium All Purpose Flour',
        brand: 'Unga Wa Dola',
        price: 240,
        size: '2kg',
        category: 'Flour',
        description: 'Vitamins and Minerals',
        imageUrl: 'assets/images/uwd_ap_2kg.png',
      ),
      
      // Unga Wa Dola - Chapati Flour
      const ProductModel(
        id: 'uwd_chapati_2kg',
        name: 'Premium Chapati Flour',
        brand: 'Unga Wa Dola',
        price: 180,
        size: '2kg',
        category: 'Flour',
        description: 'Delicious soft',
        imageUrl: 'assets/images/uwd_chapati_2kg.png',
      ),
      
      // Unga Wa Dola - Maize Flour
      const ProductModel(
        id: 'uwd_maize_2kg',
        name: 'Premium Maize Flour',
        brand: 'Unga Wa Dola',
        price: 200,
        size: '2kg',
        category: 'Flour',
        description: 'Fineness in colour and texture',
        imageUrl: 'assets/images/uwd_maize_2kg.png',
      ),
      
      // Unga Wa Dola - Atta
      const ProductModel(
        id: 'uwd_atta_2kg',
        name: 'Premium Atta Mark 1 Flour',
        brand: 'Unga Wa Dola',
        price: 190,
        size: '2kg',
        category: 'Flour',
        description: 'protein and fiber',
        imageUrl: 'assets/images/uwd_atta_2kg.png',
      ),
      
      // Dola Gold
      const ProductModel(
        id: 'dola_gold_2kg',
        name: 'Dola Gold',
        brand: 'Unga Wa Dola',
        price: 200,
        size: '2kg',
        category: 'Premium Flour',
        description: 'Finer, whiter, tastier',
        imageUrl: 'assets/images/dola_gold_2kg.png',
      ),
      
      // Jahazi - All Purpose
      const ProductModel(
        id: 'jahazi_ap_2kg',
        name: 'All Purpose Flour',
        brand: 'Jahazi',
        price: 220,
        size: '2kg',
        category: 'Flour',
        description: 'For flawless rounded Chapatis',
        imageUrl: 'assets/images/jahazi_ap_2kg.png',
      ),
      
      // Jahazi - Maize
      const ProductModel(
        id: 'jahazi_maize_2kg',
        name: 'Maize Flour',
        brand: 'Jahazi',
        price: 190,
        size: '2kg',
        category: 'Flour',
        description: 'Tasty and nutritious combination',
        imageUrl: 'assets/images/jahazi_maize_2kg.png',
      ),
      
      // Jahazi - Atta
      const ProductModel(
        id: 'jahazi_atta_2kg',
        name: 'Atta Mark 1',
        brand: 'Jahazi',
        price: 170,
        size: '2kg',
        category: 'Flour',
        description: 'Soft and fluffy brown chapatis',
        imageUrl: 'assets/images/jahazi_atta_2kg.png',
      ),
      
      // Bakers Flour
      const ProductModel(
        id: 'baker_premium_ap_50kg',
        name: 'Premium All Purpose Bakers Flour',
        brand: 'Unga Wa Dola',
        price: 5600,
        size: '50kg',
        category: 'Bakers Flour',
        description: 'Top quality bread baking',
        imageUrl: 'assets/images/baker_premium_50kg.png',
      ),
      
      // Ziwa Premium
      const ProductModel(
        id: 'ziwa_ap_2kg',
        name: 'Premium All Purpose Flour',
        brand: 'Ziwa Premium',
        price: 130,
        size: '2kg',
        category: 'Flour',
        description: 'Ingredient in bread',
        imageUrl: 'assets/images/ziwa_ap_2kg.png',
      ),
      const ProductModel(
        id: 'ziwa_maize_2kg',
        name: 'Premium Maize Flour',
        brand: 'Ziwa Premium',
        price: 105,
        size: '2kg',
        category: 'Flour',
        description: 'Soft and sweet to the palate',
        imageUrl: 'assets/images/ziwa_maize_2kg.png',
      ),
      
      // Chenga
      const ProductModel(
        id: 'chenga_1kg',
        name: 'Chenga Flour',
        brand: 'KFM',
        price: 80,
        size: '1kg',
        category: 'Flour',
        description: 'Raha ya mama, Furaha ya jamii',
        imageUrl: 'assets/images/chenga_1kg.png',
      ),
      
      // Golden Drop
      const ProductModel(
        id: 'golden_drop_20l',
        name: 'Golden Drop Cooking Oil',
        brand: 'KFM',
        price: 3200,
        size: '20L',
        category: 'Cooking Oil',
        description: 'Premium cooking oil',
        imageUrl: 'assets/images/golden_drop_20l.png',
      ),
  ];
 
  @override
  Future<List<ProductModel>> fetchProducts({String? tenantId}) async {
    await _ensureSeeded();
    final dbProducts = await _productsDao.getAllProducts(tenantId: tenantId);
    return dbProducts.map((p) => ProductModel(
      id: p.id,
      name: p.name,
      brand: p.brand,
      price: p.price,
      category: p.category,
      size: p.size,
      description: p.description,
      imageUrl: p.imageUrl ?? '',
    )).toList();
  }
 
  @override
  Future<ProductModel?> getProductById(String id) async {
    await _ensureSeeded();
    final p = await _productsDao.getProductById(id);
    if (p == null) return null;
    return ProductModel(
      id: p.id,
      name: p.name,
      brand: p.brand,
      price: p.price,
      category: p.category,
      size: p.size,
      description: p.description,
      imageUrl: p.imageUrl ?? '',
    );
  }
 
  Future<void> _ensureSeeded() async {
    final existing = await _productsDao.getAllProducts();
    if (existing.isEmpty) {
      await _productsDao.insertProducts(_seedProducts.map((p) => ProductsCompanion(
        id: Value(p.id),
        name: Value(p.name),
        brand: Value(p.brand),
        price: Value(p.price),
        category: Value(p.category),
        size: Value(p.size),
        description: Value(p.description),
        imageUrl: Value(p.imageUrl),
      )).toList());
    }
  }
 
  @override
  Future<void> addProduct(ProductModel product) async {
    await _productsDao.insertProduct(ProductsCompanion(
      id: Value(product.id),
      name: Value(product.name),
      brand: Value(product.brand),
      price: Value(product.price),
      category: Value(product.category),
      size: Value(product.size),
      description: Value(product.description),
      imageUrl: Value(product.imageUrl),
      tenantId: Value(product.tenantId),
    ));
  }
 
  @override
  Future<void> updateProduct(ProductModel product) async {
    await _productsDao.updateProduct(ProductsCompanion(
      id: Value(product.id),
      name: Value(product.name),
      brand: Value(product.brand),
      price: Value(product.price),
      category: Value(product.category),
      size: Value(product.size),
      description: Value(product.description),
      imageUrl: Value(product.imageUrl),
      tenantId: Value(product.tenantId),
    ));
  }
 
  @override
  Future<void> deleteProduct(String id) async {
    await _productsDao.deleteProduct(id);
  }
}
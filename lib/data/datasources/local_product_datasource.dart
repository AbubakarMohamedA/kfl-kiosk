import 'package:kfm_kiosk/data/models/product_model.dart';

class LocalProductDataSource {
  // This simulates a local database or API
  // In a real app, this could be fetched from an API or local database
  
  List<ProductModel> getAllProducts() {
    return [
      // Unga Wa Dola - All Purpose Flour
      const ProductModel(
        id: 'uwd_ap_flour_500g',
        name: 'Premium All Purpose Flour',
        brand: 'Unga Wa Dola',
        price: 60,
        size: '1/2kg',
        category: 'Flour',
        description: 'Fortified with Vitamins and Minerals',
      ),
      const ProductModel(
        id: 'uwd_ap_flour_1kg',
        name: 'Premium All Purpose Flour',
        brand: 'Unga Wa Dola',
        price: 120,
        size: '1kg',
        category: 'Flour',
        description: 'Fortified with Vitamins and Minerals',
      ),
      const ProductModel(
        id: 'uwd_ap_flour_2kg',
        name: 'Premium All Purpose Flour',
        brand: 'Unga Wa Dola',
        price: 240,
        size: '2kg',
        category: 'Flour',
        description: 'Fortified with Vitamins and Minerals',
      ),
      
      // Unga Wa Dola - Chapati Flour
      const ProductModel(
        id: 'uwd_chapati_2kg',
        name: 'Premium Chapati Flour',
        brand: 'Unga Wa Dola',
        price: 180,
        size: '2kg',
        category: 'Flour',
        description: 'For delicious soft layered chapatis',
      ),
      
      // Unga Wa Dola - Maize Flour
      const ProductModel(
        id: 'uwd_maize_500g',
        name: 'Premium Maize Flour',
        brand: 'Unga Wa Dola',
        price: 50,
        size: '1/2kg',
        category: 'Flour',
        description: 'Fineness in colour and texture',
      ),
      const ProductModel(
        id: 'uwd_maize_1kg',
        name: 'Premium Maize Flour',
        brand: 'Unga Wa Dola',
        price: 100,
        size: '1kg',
        category: 'Flour',
        description: 'Fineness in colour and texture',
      ),
      const ProductModel(
        id: 'uwd_maize_2kg',
        name: 'Premium Maize Flour',
        brand: 'Unga Wa Dola',
        price: 200,
        size: '2kg',
        category: 'Flour',
        description: 'Fineness in colour and texture',
      ),
      const ProductModel(
        id: 'uwd_maize_5kg',
        name: 'Premium Maize Flour',
        brand: 'Unga Wa Dola',
        price: 500,
        size: '5kg',
        category: 'Flour',
        description: 'Fineness in colour and texture',
      ),
      const ProductModel(
        id: 'uwd_maize_10kg',
        name: 'Premium Maize Flour',
        brand: 'Unga Wa Dola',
        price: 1000,
        size: '10kg',
        category: 'Flour',
        description: 'Fineness in colour and texture',
      ),
      
      // Unga Wa Dola - Atta
      const ProductModel(
        id: 'uwd_atta_2kg',
        name: 'Premium Atta Mark 1 Flour',
        brand: 'Unga Wa Dola',
        price: 190,
        size: '2kg',
        category: 'Flour',
        description: 'High protein and fiber content',
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
      ),
      
      // Jahazi - All Purpose
      const ProductModel(
        id: 'jahazi_ap_500g',
        name: 'All Purpose Flour',
        brand: 'Jahazi',
        price: 55,
        size: '1/2kg',
        category: 'Flour',
        description: 'For flawless rounded Chapatis',
      ),
      const ProductModel(
        id: 'jahazi_ap_1kg',
        name: 'All Purpose Flour',
        brand: 'Jahazi',
        price: 110,
        size: '1kg',
        category: 'Flour',
        description: 'For flawless rounded Chapatis',
      ),
      const ProductModel(
        id: 'jahazi_ap_2kg',
        name: 'All Purpose Flour',
        brand: 'Jahazi',
        price: 220,
        size: '2kg',
        category: 'Flour',
        description: 'For flawless rounded Chapatis',
      ),
      
      // Jahazi - Maize
      const ProductModel(
        id: 'jahazi_maize_500g',
        name: 'Maize Flour',
        brand: 'Jahazi',
        price: 48,
        size: '1/2kg',
        category: 'Flour',
        description: 'Tasty and nutritious combination',
      ),
      const ProductModel(
        id: 'jahazi_maize_1kg',
        name: 'Maize Flour',
        brand: 'Jahazi',
        price: 95,
        size: '1kg',
        category: 'Flour',
        description: 'Tasty and nutritious combination',
      ),
      const ProductModel(
        id: 'jahazi_maize_2kg',
        name: 'Maize Flour',
        brand: 'Jahazi',
        price: 190,
        size: '2kg',
        category: 'Flour',
        description: 'Tasty and nutritious combination',
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
      ),
      
      // Bakers Flour
      const ProductModel(
        id: 'baker_premium_ap_25kg',
        name: 'Premium All Purpose Bakers Flour',
        brand: 'Unga Wa Dola',
        price: 2800,
        size: '25kg',
        category: 'Bakers Flour',
        description: 'Top quality bread baking',
      ),
      const ProductModel(
        id: 'baker_premium_ap_50kg',
        name: 'Premium All Purpose Bakers Flour',
        brand: 'Unga Wa Dola',
        price: 5600,
        size: '50kg',
        category: 'Bakers Flour',
        description: 'Top quality bread baking',
      ),
      
      // Ziwa Premium
      const ProductModel(
        id: 'ziwa_ap_2kg',
        name: 'Premium All Purpose Flour',
        brand: 'Ziwa Premium',
        price: 130,
        size: '2kg',
        category: 'Flour',
        description: 'Essential ingredient in bread',
      ),
      const ProductModel(
        id: 'ziwa_maize_2kg',
        name: 'Premium Maize Flour',
        brand: 'Ziwa Premium',
        price: 105,
        size: '2kg',
        category: 'Flour',
        description: 'Soft and sweet to the palate',
      ),
      
      // Baba Lao
      const ProductModel(
        id: 'babalao_ap_1kg',
        name: 'All Purpose Wheat Flour',
        brand: 'Baba Lao',
        price: 85,
        size: '1kg',
        category: 'Flour',
        description: 'Exceptionally good and healthy',
      ),
      const ProductModel(
        id: 'babalao_maize_1kg',
        name: 'Premium Maize Flour',
        brand: 'Baba Lao',
        price: 75,
        size: '1kg',
        category: 'Flour',
        description: 'Tasty and Nutritious flour',
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
      ),
    ];
  }

  Future<List<ProductModel>> fetchProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return getAllProducts();
  }

  Future<ProductModel?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return getAllProducts().firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}
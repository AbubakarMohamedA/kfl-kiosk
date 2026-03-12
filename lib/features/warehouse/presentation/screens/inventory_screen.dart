import 'package:flutter/material.dart';
import 'package:sss/core/constants/app_constants.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _showLowStock = false;

  final List<Map<String, dynamic>> _inventory = [
    {
      'id': 'uwd_ap_flour_500g',
      'name': 'Premium All Purpose Flour',
      'brand': 'Unga Wa Dola',
      'category': 'Flour',
      'size': '1/2kg',
      'currentStock': 45,
      'minStock': 20,
      'maxStock': 100,
      'unitCost': 50.0,
      'sellingPrice': 60.0,
      'supplier': 'KFM Distribution',
      'lastRestocked': DateTime.now().subtract(const Duration(days: 3)),
      'expiryDate': DateTime.now().add(const Duration(days: 180)),
      'sku': 'UWD-APF-500',
      'location': 'Aisle 1, Shelf A',
    },
    {
      'id': 'uwd_maize_2kg',
      'name': 'Premium Maize Flour',
      'brand': 'Unga Wa Dola',
      'category': 'Flour',
      'size': '2kg',
      'currentStock': 12,
      'minStock': 15,
      'maxStock': 80,
      'unitCost': 165.0,
      'sellingPrice': 200.0,
      'supplier': 'KFM Distribution',
      'lastRestocked': DateTime.now().subtract(const Duration(days: 5)),
      'expiryDate': DateTime.now().add(const Duration(days: 150)),
      'sku': 'UWD-MF-2KG',
      'location': 'Aisle 1, Shelf B',
    },
    {
      'id': 'golden_drop_20l',
      'name': 'Golden Drop Cooking Oil',
      'brand': 'KFM',
      'category': 'Cooking Oil',
      'size': '20L',
      'currentStock': 8,
      'minStock': 10,
      'maxStock': 30,
      'unitCost': 2800.0,
      'sellingPrice': 3200.0,
      'supplier': 'KFM Distribution',
      'lastRestocked': DateTime.now().subtract(const Duration(days: 7)),
      'expiryDate': DateTime.now().add(const Duration(days: 365)),
      'sku': 'GD-OIL-20L',
      'location': 'Aisle 3, Shelf A',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInventoryTab(),
                      _buildStockAlertsTab(),
                      _buildSupplierTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: const Color(AppColors.primaryBlue),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppColors.primaryBlue),
            const Color(0xFF0A6F38),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Real-time stock tracking & management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting inventory...')),
              );
            },
            icon: const Icon(Icons.file_download),
            label: const Text('Export Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final totalItems = _inventory.length;
    final lowStockItems = _inventory.where((item) => 
      item['currentStock'] <= item['minStock']
    ).length;
    final totalValue = _inventory.fold<double>(
      0,
      (sum, item) => sum + (item['currentStock'] * item['unitCost']),
    );

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarItem(0, Icons.inventory, 'Stock'),
          _buildSidebarItem(1, Icons.warning_amber, 'Alerts'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                _buildQuickStat('Total Items', '$totalItems', Icons.inventory_2),
                const SizedBox(height: 12),
                _buildQuickStat('Low Stock', '$lowStockItems', Icons.warning_amber, 
                  color: lowStockItems > 0 ? Colors.orange : null),
                const SizedBox(height: 12),
                _buildQuickStat('Total Value', 'KSh ${(totalValue / 1000).toStringAsFixed(0)}K', 
                  Icons.attach_money),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;

    return InkWell(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(AppColors.primaryBlue).withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? const Color(AppColors.primaryBlue)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(AppColors.primaryBlue)
                  : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(AppColors.primaryBlue)
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, {Color? color}) {
    final statColor = color ?? const Color(AppColors.primaryBlue);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: statColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    final filteredInventory = _getFilteredInventory();

    return Column(
      children: [
        _buildControlsBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Product Inventory'),
                const SizedBox(height: 16),
                _buildInventoryTable(filteredInventory),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildControlsBar() {
    final categories = ['All', ...{..._inventory.map((item) => item['category'])}];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, or category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value!),
              items: categories.map<DropdownMenuItem<String>>((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              underline: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              onChanged: (value) => setState(() => _sortBy = value!),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                DropdownMenuItem(value: 'stock', child: Text('Sort by Stock')),
                DropdownMenuItem(value: 'price', child: Text('Sort by Price')),
                DropdownMenuItem(value: 'expiry', child: Text('Sort by Expiry')),
              ],
              underline: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('Low Stock Only'),
            selected: _showLowStock,
            onSelected: (value) => setState(() => _showLowStock = value),
            selectedColor: Colors.orange[100],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('Product', flex: 3),
                _buildTableHeaderCell('SKU', flex: 1),
                _buildTableHeaderCell('Stock', flex: 1),
                _buildTableHeaderCell('Status', flex: 1),
                _buildTableHeaderCell('Price', flex: 1),
                _buildTableHeaderCell('Value', flex: 1),
                _buildTableHeaderCell('Actions', flex: 1),
              ],
            ),
          ),
          ...items.map((item) => _buildInventoryRow(item)),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInventoryRow(Map<String, dynamic> item) {
    final stockLevel = _getStockLevel(item);
    final stockColor = _getStockColor(stockLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['brand']} • ${item['size']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item['sku'],
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['currentStock']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: stockColor,
                  ),
                ),
                Text(
                  'Min: ${item['minStock']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: stockColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                stockLevel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: stockColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'KSh ${item['sellingPrice'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'KSh ${(item['currentStock'] * item['unitCost']).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(AppColors.primaryBlue),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Colors.grey,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 40),
                elevation: 8,
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showDetailsDialog(item);
                      break;
                    case 'edit':
                      _showEditDialog(item);
                      break;
                    case 'restock':
                      _showRestockDialog(item);
                      break;
                    case 'history':
                      _showHistoryDialog(item);
                      break;
                    case 'duplicate':
                      _duplicateProduct(item);
                      break;
                    case 'delete':
                      _confirmDelete(item);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 12),
                        const Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 12),
                        const Text('Edit Product'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'restock',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: Colors.purple[700],
                        ),
                        const SizedBox(width: 12),
                        const Text('Restock'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        const Text('View History'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(
                          Icons.content_copy,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        const Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlertsTab() {
    final lowStockItems = _inventory.where((item) => 
      item['currentStock'] <= item['minStock']
    ).toList();

    final expiringItems = _inventory.where((item) {
      final expiryDate = item['expiryDate'] as DateTime;
      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Stock Alerts'),
          const SizedBox(height: 16),
          if (lowStockItems.isNotEmpty) ...[
            _buildAlertSection(
              'Low Stock Alerts',
              lowStockItems.length,
              Colors.orange,
              lowStockItems,
            ),
            const SizedBox(height: 24),
          ],
          if (expiringItems.isNotEmpty) ...[
            _buildAlertSection(
              'Expiring Soon',
              expiringItems.length,
              Colors.red,
              expiringItems,
            ),
          ],
          if (lowStockItems.isEmpty && expiringItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Good!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No stock alerts at this time',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertSection(
    String title,
    int count,
    Color color,
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'} need attention',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          ...items.map((item) => _buildAlertItem(item, color)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> item, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['brand']} • ${item['size']} • ${item['sku']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stock: ${item['currentStock']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Min: ${item['minStock']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _showRestockDialog(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.primaryBlue),
              foregroundColor: Colors.white,
            ),
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierTab() {
    final suppliers = _getSuppliers();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Suppliers'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              return _buildSupplierCard(suppliers[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Color(AppColors.primaryBlue),
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  supplier['status'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            supplier['name'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            supplier['contact'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${supplier['productsCount']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${supplier['ordersCount']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredInventory() {
    var filtered = _inventory.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['sku'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['category'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          item['category'] == _selectedCategory;

      final matchesLowStock = !_showLowStock ||
          item['currentStock'] <= item['minStock'];

      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'stock':
          return a['currentStock'].compareTo(b['currentStock']);
        case 'price':
          return a['sellingPrice'].compareTo(b['sellingPrice']);
        case 'expiry':
          return a['expiryDate'].compareTo(b['expiryDate']);
        default:
          return a['name'].compareTo(b['name']);
      }
    });

    return filtered;
  }

  String _getStockLevel(Map<String, dynamic> item) {
    final current = item['currentStock'];
    final min = item['minStock'];
    final max = item['maxStock'];

    if (current <= min) return 'LOW';
    if (current >= max * 0.8) return 'OPTIMAL';
    return 'GOOD';
  }

  Color _getStockColor(String level) {
    switch (level) {
      case 'LOW':
        return Colors.red;
      case 'OPTIMAL':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  List<Map<String, dynamic>> _getSuppliers() {
    return [
      {
        'name': 'KFM Distribution',
        'contact': '+254 700 123 456',
        'status': 'Active',
        'productsCount': 25,
        'ordersCount': 145,
      },
      {
        'name': 'Premium Supplies Ltd',
        'contact': '+254 700 234 567',
        'status': 'Active',
        'productsCount': 12,
        'ordersCount': 78,
      },
      {
        'name': 'East Africa Traders',
        'contact': '+254 700 345 678',
        'status': 'Active',
        'productsCount': 8,
        'ordersCount': 34,
      },
    ];
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Product Name')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'SKU')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Category')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Initial Stock')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Unit Cost')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Selling Price')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product added successfully')),
              );
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item['name']}'),
        content: const Text('Edit functionality coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${item['currentStock']}'),
            Text('Minimum Stock: ${item['minStock']}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Quantity to Add',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully')),
              );
            },
            child: const Text('Update Stock'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('SKU', item['sku']),
              _buildDetailRow('Brand', item['brand']),
              _buildDetailRow('Category', item['category']),
              _buildDetailRow('Size', item['size']),
              _buildDetailRow('Current Stock', '${item['currentStock']}'),
              _buildDetailRow('Min Stock', '${item['minStock']}'),
              _buildDetailRow('Max Stock', '${item['maxStock']}'),
              _buildDetailRow('Unit Cost', 'KSh ${item['unitCost']}'),
              _buildDetailRow('Selling Price', 'KSh ${item['sellingPrice']}'),
              _buildDetailRow('Supplier', item['supplier']),
              _buildDetailRow('Location', item['location']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock History'),
        content: const Text('History view coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _duplicateProduct(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating ${item['name']}...'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {},
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${item['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
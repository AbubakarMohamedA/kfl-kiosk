import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_event.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_state.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:kfm_kiosk/core/repositories/image_repository.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/features/products/presentation/widgets/app_image.dart';
import 'package:kfm_kiosk/core/database/daos/app_config_dao.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  bool _isUploading = false;
  bool _isEnterprise = false;
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    // Load products if not already loaded
    context.read<ProductBloc>().add(const LoadProducts());
  }

  Future<void> _loadConfig() async {
    final configRepo = getIt<ConfigurationRepository>();
    final config = await configRepo.getConfiguration();
    if (mounted) {
      setState(() {
        _isEnterprise = config.tierId == 'enterprise';
        _isLoadingConfig = false;
      });
    }
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final nameController = TextEditingController(text: product?.name);
    final brandController = TextEditingController(text: product?.brand);
    final priceController = TextEditingController(text: product?.price.toString());
    final sizeController = TextEditingController(text: product?.size);
    final categoryController = TextEditingController(text: product?.category);
    final descController = TextEditingController(text: product?.description);

    // Clear previous selection
    _selectedImageFile = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog state
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Preview & Picker
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateDialog(() {
                            _selectedImageFile = File(image.path);
                            // Update controller if you want to show path, but better to just use file
                            // We can leave controller empty or set it to 'Uploading...' later
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _selectedImageFile != null
                            ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                            : AppImage(
                                imageUrl: product?.imageUrl ?? 'assets/images/fallback.svg',
                                fit: product?.imageUrl != null ? BoxFit.cover : BoxFit.contain,
                                color: product?.imageUrl != null ? null : Colors.grey[400],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isUploading) const LinearProgressIndicator(),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      readOnly: _isEnterprise,
                    ),
                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(labelText: 'Brand'),
                      readOnly: _isEnterprise,
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      readOnly: _isEnterprise,
                    ),
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(labelText: 'Size'),
                      readOnly: _isEnterprise,
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                      readOnly: _isEnterprise,
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      readOnly: _isEnterprise,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                    final name = nameController.text;
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    
                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid name and price')),
                      );
                      return;
                    }

                    String finalImageUrl = '';

                    // Handle Image Upload
                    if (_selectedImageFile != null) {
                      setStateDialog(() {
                        _isUploading = true;
                      });
                      try {
                        final repo = getIt<ImageRepository>();
                        final uploadedUrl = await repo.uploadImage(_selectedImageFile!);
                        finalImageUrl = uploadedUrl;
                      } catch (e) {
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upload failed: $e')),
                          );
                        }
                        setStateDialog(() {
                          _isUploading = false;
                        });
                        return; // Stop save if upload fails
                      }
                      setStateDialog(() {
                        _isUploading = false;
                      });
                    }

                    final newProduct = Product(
                      id: product?.id ?? const Uuid().v4(),
                      name: name,
                      brand: brandController.text,
                      price: price,
                      size: sizeController.text,
                      category: categoryController.text.isEmpty ? 'General' : categoryController.text,
                      description: descController.text,
                      imageUrl: finalImageUrl.isEmpty ? (product?.imageUrl ?? 'assets/images/fallback.svg') : finalImageUrl,
                      // Preserve or inherit tenantId if needed, logic is in Repo/Bloc
                      tenantId: product?.tenantId, 
                    );

                    if (context.mounted) {
                      if (product == null) {
                        context.read<ProductBloc>().add(AddProductEvent(newProduct));
                      } else {
                        context.read<ProductBloc>().add(UpdateProductEvent(newProduct));
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(_isUploading ? 'Uploading...' : 'Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProductEvent(productId));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSapConfigDialog() async {
    final configRepo = getIt<ConfigurationRepository>();
    final config = await configRepo.getConfiguration();
    final tenantId = config.tenantId;

    if (tenantId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot configure SAP: No tenant ID found.')),
        );
      }
      return;
    }

    final appConfigDao = getIt<AppConfigDao>();
    final enabledKey = 'sap_enabled_$tenantId';
    final urlKey = 'sap_base_url_$tenantId';

    final isEnabledStr = await appConfigDao.getValue(enabledKey);
    final isEnabled = isEnabledStr == 'true';
    final baseUrl = await appConfigDao.getValue(urlKey) ?? '';

    final urlController = TextEditingController(text: baseUrl);
    bool currentEnabled = isEnabled;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('SAP Configuration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Enable SAP Integration'),
                    value: currentEnabled,
                    onChanged: (val) {
                      setStateDialog(() {
                        currentEnabled = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'SAP Base URL',
                      hintText: 'e.g., http://your-sap-server:8080/products',
                    ),
                    enabled: currentEnabled,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await appConfigDao.setValue(enabledKey, currentEnabled.toString());
                    await appConfigDao.setValue(urlKey, urlController.text);
                    if (mounted) {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SAP Configuration saved.')),
                      );
                      // Force reload to apply new data source
                      context.read<ProductBloc>().add(const LoadProducts());
                    }
                  },
                  child: const Text('Save Configure'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          if (_isEnterprise)
            TextButton.icon(
              icon: const Icon(Icons.settings_applications),
              label: const Text('SAP Config'),
              onPressed: _showSapConfigDialog,
              style: TextButton.styleFrom(
                // Allow it to inherit the default AppBar icon/text color
                foregroundColor: Colors.black87,
              ),
            ),
          if (!_isEnterprise)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showProductDialog(context),
              tooltip: 'Add Product',
            ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is ProductLoaded) {
            final products = state.filteredProducts;
            if (products.isEmpty) {
              return const Center(child: Text('No products found. Add one!'));
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: AppImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.brand} - \$${product.price}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(context, product: product),
                      ),
                      if (!_isEnterprise)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, product.id),
                        ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: !_isEnterprise
          ? FloatingActionButton(
              onPressed: () => _showProductDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

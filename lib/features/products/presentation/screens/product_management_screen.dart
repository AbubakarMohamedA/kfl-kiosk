import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:sss/features/products/presentation/bloc/product/product_event.dart';
import 'package:sss/features/products/presentation/bloc/product/product_state.dart';
import 'package:sss/features/products/domain/entities/product.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sss/core/repositories/image_repository.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/features/products/presentation/widgets/app_image.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/core/services/sap_auth_service.dart';

import '../../domain/repositories/product_repository.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  bool _isUploading = false;
  bool _isEnterprise = false;
  bool _isLoadingConfig = true;

  int _currentPage = 0;
  static const int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadConfig();

    // ✅ Only fire LoadProducts if state is completely fresh (ProductInitial)
    // Prevents double-fetch which causes SAP to invalidate the first session
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<ProductBloc>().state;
      if (state is ProductInitial) {
        context.read<ProductBloc>().add(const LoadProducts());
      }
    });
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

  // ─── Product Dialog ───────────────────────────────────────────────────────
  // Enterprise: only image is editable, all other fields are read-only
  // Non-enterprise: full add/edit

  void _showProductDialog(BuildContext context, {Product? product}) {
    if (_isEnterprise && product != null) {
      _showSapProductEditImageDialog(context, product);
      return;
    }

    final nameController = TextEditingController(text: product?.name);
    final brandController = TextEditingController(text: product?.brand);
    final priceController =
        TextEditingController(text: product?.price.toString());
    final sizeController = TextEditingController(text: product?.size);
    final categoryController = TextEditingController(text: product?.category);
    final descController = TextEditingController(text: product?.description);
    final itemCodeController = TextEditingController(text: product?.id ?? '');

    _selectedImageFile = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setStateDialog(() {
                            _selectedImageFile = File(image.path);
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
                                imageUrl: product?.imageUrl ??
                                    'assets/images/fallback.svg',
                                fit: BoxFit.contain,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isUploading) const LinearProgressIndicator(),
                    const SizedBox(height: 10),
                    TextField(
                      controller: itemCodeController,
                      readOnly: product != null,
                      decoration: InputDecoration(
                        labelText: 'Item Code',
                        hintText: 'e.g. ITM00050',
                        helperText: product != null
                            ? 'Item code cannot be changed'
                            : 'Must be unique in SAP',
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Code',
                        hintText: 'e.g. LS00001',
                      ),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Unit of Measure',
                        hintText: 'e.g. Unit, Pcs, Kg',
                      ),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: descController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
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
                  onPressed: _isUploading
                      ? null
                      : () async {
                          final itemCode = itemCodeController.text.trim();
                          final name = nameController.text.trim();
                          final price =
                              double.tryParse(priceController.text) ?? 0.0;

                          if (itemCode.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item Code is required'),
                              ),
                            );
                            return;
                          }

                          if (name.isEmpty || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter valid name and price'),
                              ),
                            );
                            return;
                          }

                          String finalImageUrl =
                              product?.imageUrl ?? 'assets/images/fallback.svg';

                          if (_selectedImageFile != null) {
                            setStateDialog(() => _isUploading = true);
                            try {
                              final repo = getIt<ImageRepository>();
                              finalImageUrl =
                                  await repo.uploadImage(_selectedImageFile!);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Upload failed: $e')),
                                );
                              }
                              setStateDialog(() => _isUploading = false);
                              return;
                            }
                            setStateDialog(() => _isUploading = false);
                          }

                          final newProduct = Product(
                            id: itemCode,
                            name: name,
                            brand: brandController.text.trim(),
                            price: price,
                            size: sizeController.text.trim(),
                            category:
                                categoryController.text.trim().isEmpty
                                    ? 'General'
                                    : categoryController.text.trim(),
                            description: descController.text.trim(),
                            imageUrl: finalImageUrl,
                            tenantId: product?.tenantId,
                          );

                          if (context.mounted) {
                            if (product == null) {
                              context
                                  .read<ProductBloc>()
                                  .add(AddProductEvent(newProduct));
                            } else {
                              context
                                  .read<ProductBloc>()
                                  .add(UpdateProductEvent(newProduct));
                            }
                            Navigator.pop(context);
                          }
                        },
                  child: Text(_isUploading ? 'Uploading...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── SAP Product: Only Image Editable ─────────────────────────────────────

  void _showSapProductEditImageDialog(BuildContext context, Product product) {
    _selectedImageFile = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'SAP',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Editable Image ────────────────────────────────────
                    Column(
                      children: [
                        const Text(
                          'Product Image',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setStateDialog(() {
                                _selectedImageFile = File(image.path);
                              });
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border:
                                      Border.all(color: Colors.blue),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _selectedImageFile != null
                                      ? Image.file(_selectedImageFile!,
                                          fit: BoxFit.cover)
                                      : AppImage(
                                          imageUrl: product.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap image to change',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    if (_isUploading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 4),
                      const Text('Uploading image...',
                          style: TextStyle(fontSize: 12)),
                    ],

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // ── Read-Only SAP Fields ──────────────────────────────
                    _readOnlyField('Item Code', product.id),
                    _readOnlyField('Name', product.name),
                    _readOnlyField('Category', product.category),
                    _readOnlyField(
                        'Supplier',
                        product.brand.isEmpty ? '—' : product.brand),
                    _readOnlyField(
                        'Price',
                        'KSh ${product.price.toStringAsFixed(2)}'),
                    _readOnlyField(
                        'Unit',
                        product.size.isEmpty ? '—' : product.size),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline,
                              color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Product details are managed in SAP B1. Only the image can be updated here.',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      (_isUploading || _selectedImageFile == null)
                          ? null
                          : () async {
                              setStateDialog(() => _isUploading = true);
                              try {
                                final repo = getIt<ImageRepository>();
final uploadedUrl = await repo.uploadImage(_selectedImageFile!);

if (context.mounted) {
  // ✅ Local only — never touches SAP, never kills the session
  context.read<ProductBloc>().add(
    UpdateProductImageLocalEvent(product.id, uploadedUrl),
  );
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Image updated successfully'),
      backgroundColor: Colors.green,
    ),
  );
}
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Upload failed: $e')),
                                  );
                                }
                              }
                              setStateDialog(() => _isUploading = false);
                            },
                  icon: const Icon(Icons.save),
                  label: Text(
                      _isUploading ? 'Uploading...' : 'Save Image'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Read-Only Field Widget ───────────────────────────────────────────────

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          suffixIcon: const Icon(Icons.lock_outline,
              size: 16, color: Colors.grey),
        ),
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  // ─── Delete Confirmation ──────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          _isEnterprise
              ? 'This will delete the item from SAP B1. This cannot be undone.'
              : 'Are you sure you want to delete this product?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context
                  .read<ProductBloc>()
                  .add(DeleteProductEvent(productId));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── SAP Config Dialog ────────────────────────────────────────────────────

  Future<void> _showSapConfigDialog() async {
    final sapAuth = getIt<SapAuthService>();
    final creds = await sapAuth.loadCredentials();

    final serverIpController = TextEditingController(
      text: creds['serverIp'] ?? 'b1su0206.cloudtaktiks.com',
    );
    final companyDbController = TextEditingController(
      text: creds['companyDb'] ?? '',
    );
    final usernameController = TextEditingController(
      text: creds['username'] ?? '',
    );
    final passwordController = TextEditingController(
      text: creds['password'] ?? '',
    );
    final walkInCardCodeController = TextEditingController( // NEW
      text: creds['walkInCardCode'] ?? 'LC00017',
    );
    final currencyCodeController = TextEditingController( // NEW
      text: creds['currencyCode'] ?? 'KSh',
    );
    final warehouseController = TextEditingController( // NEW
      text: creds['warehouseCode'] ?? '',
    );
    final bplIdController = TextEditingController( // NEW
      text: creds['bplId'] ?? '',
    );
    final taxCodeController = TextEditingController( // NEW
      text: creds['taxCode'] ?? 'O1',
    );
    final paymentGlAccountController = TextEditingController( // NEW
      text: creds['paymentGlAccount'] ?? '',
    );

    bool isLoggingIn = false;
    bool obscurePassword = true;
    String? errorMessage;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.settings_applications,
                        color: Colors.blue[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('SAP B1 Configuration'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: serverIpController,
                      decoration: InputDecoration(
                        labelText: 'Server IP / Hostname',
                        hintText: 'e.g. b1su0206.cloudtaktiks.com',
                        prefixIcon: const Icon(Icons.dns),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: companyDbController,
                      decoration: InputDecoration(
                        labelText: 'CompanyDB',
                        hintText: 'e.g. SBODemoKE',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: paymentGlAccountController,
                      decoration: InputDecoration(
                        labelText: 'Payment GL Account (M-Pesa)',
                        hintText: 'e.g. 160000, Cash Account',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: taxCodeController,
                      decoration: InputDecoration(
                        labelText: 'Default Tax Code (VatGroup)',
                        hintText: 'e.g. O1, VT01',
                        prefixIcon: const Icon(Icons.receipt_long),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: warehouseController,
                      decoration: InputDecoration(
                        labelText: 'Warehouse Code',
                        hintText: 'e.g. 01, WH01',
                        prefixIcon: const Icon(Icons.warehouse),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bplIdController,
                      decoration: InputDecoration(
                        labelText: 'Business Place ID (BPLId)',
                        hintText: 'e.g. 1, 2 (Required if Multi-Branch enabled)',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: currencyCodeController,
                      decoration: InputDecoration(
                        labelText: 'Document Currency',
                        hintText: 'e.g. KSH, USD, EUR',
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: walkInCardCodeController,
                      decoration: InputDecoration(
                        labelText: 'Default Walk-In BP Code',
                        hintText: 'e.g. C99999 or WalkIn',
                        prefixIcon: const Icon(Icons.person_pin_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'UserName',
                        hintText: 'SAP B1 username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setStateDialog(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (isLoggingIn) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 4),
                      const Text(
                        'Connecting to SAP...',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoggingIn ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isLoggingIn
                      ? null
                      : () async {
                          await sapAuth.clearConfig();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('SAP configuration cleared.'),
                              ),
                            );
                          }
                        },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoggingIn
                      ? null
                      : () async {
                          final serverIp =
                              serverIpController.text.trim();
                          final companyDb =
                              companyDbController.text.trim();
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();
                          final walkInCardCode = walkInCardCodeController.text.trim();
                          final currencyCode = currencyCodeController.text.trim();
                          final warehouseCode = warehouseController.text.trim();
                          final bplId = bplIdController.text.trim();
                          final taxCode = taxCodeController.text.trim(); // NEW
                          final paymentGlAccount = paymentGlAccountController.text.trim(); // NEW

                          if (serverIp.isEmpty ||
                              companyDb.isEmpty ||
                              username.isEmpty ||
                              password.isEmpty) {
                            setStateDialog(() {
                              errorMessage = 'All fields are required.';
                            });
                            return;
                          }

                          setStateDialog(() {
                            isLoggingIn = true;
                            errorMessage = null;
                          });

                          await sapAuth.saveCredentials(
                            serverIp: serverIp,
                            companyDb: companyDb,
                            username: username,
                            password: password,
                            walkInCardCode: walkInCardCode,
                            currencyCode: currencyCode,
                            warehouseCode: warehouseCode,
                            bplId: bplId,
                            taxCode: taxCode, // NEW
                            paymentGlAccount: paymentGlAccount, // NEW
                          );

                          final result = await sapAuth.login();

                          if (context.mounted) {
                            if (result.success) {
  Navigator.pop(context);

  // ✅ Works now since invalidateDataSource is on the interface
  getIt<ProductRepository>().invalidateDataSource();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Connected to SAP B1 successfully!'),
      backgroundColor: Colors.green,
    ),
  );

  context.read<ProductBloc>().add(const LoadProducts());
} else {
                              setStateDialog(() {
                                isLoggingIn = false;
                                errorMessage = result.message;
                              });
                            }
                          }
                        },
                  icon: const Icon(Icons.login),
                  label: Text(isLoggingIn
                      ? 'Connecting...'
                      : 'Connect & Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
          if (_isEnterprise) ...[
            // Sync button
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync from SAP',
              onPressed: () {
                context.read<ProductBloc>().add(const LoadProducts());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing products from SAP...'),
                  ),
                );
              },
            ),
            // SAP Config button
            TextButton.icon(
              icon: const Icon(Icons.settings_applications),
              label: const Text('SAP Config'),
              onPressed: _showSapConfigDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
            ),
          ],
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            );
          } else if (state is ProductError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<ProductBloc>()
                        .add(const LoadProducts()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  if (_isEnterprise) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showSapConfigDialog,
                      child: const Text('Reconfigure SAP'),
                    ),
                  ],
                ],
              ),
            );
          } else if (state is ProductLoaded) {
            final products = state.filteredProducts;
            final totalPages = (products.length / _itemsPerPage).ceil();

            int activePage = _currentPage;
            if (activePage >= totalPages && totalPages > 0) {
              activePage = totalPages - 1;
            }

            final paginatedProducts = products
                .skip(activePage * _itemsPerPage)
                .take(_itemsPerPage)
                .toList();

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      _isEnterprise
                          ? 'No products found in SAP.\nCheck your SAP configuration.'
                          : 'No products found. Add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .read<ProductBloc>()
                          .add(const LoadProducts()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
                    ),
                    if (_isEnterprise) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _showSapConfigDialog,
                        child: const Text('Reconfigure SAP'),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape = constraints.maxWidth > constraints.maxHeight;
                      final int columns = isLandscape ? 5 : 4;
                      final int rows = (_itemsPerPage / columns).ceil();
                      
                      const double spacing = 8.0;
                      // Calculate available space minus paddings and spacings
                      final availableWidth = constraints.maxWidth - 16.0 - (spacing * (columns - 1));
                      final availableHeight = constraints.maxHeight - 16.0 - (spacing * (rows - 1));
                      
                      final cellWidth = availableWidth / columns;
                      final cellHeight = availableHeight / rows;
                      
                      double aspectRatio = cellHeight > 0 ? (cellWidth / cellHeight) : 1.0;
                      if (aspectRatio <= 0.1) aspectRatio = 1.0; // fallback if constraint logic breaks
                      
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(), // Disables scrolling perfectly
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemCount: paginatedProducts.length,
                        itemBuilder: (context, index) {
                          final product = paginatedProducts[index];
                          return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: AppImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (_isEnterprise)
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.blue[200]!),
                                          ),
                                          child: Text(
                                            'SAP',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.category} • KSh ${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _isEnterprise
                                              ? Icons.camera_alt
                                              : Icons.edit,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        tooltip: _isEnterprise
                                            ? 'Update Image'
                                            : 'Edit Product',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showProductDialog(
                                            context,
                                            product: product),
                                      ),
                                      if (!_isEnterprise) ...[
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          tooltip: 'Delete',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _confirmDelete(
                                              context, product.id),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (totalPages > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: activePage > 0
                              ? () => setState(
                                  () => _currentPage = activePage - 1)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Page ${activePage + 1} of ${totalPages > 0 ? totalPages : 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: activePage < totalPages - 1
                              ? () => setState(
                                  () => _currentPage = activePage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/core/services/license_service.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/features/auth/domain/entities/tenant.dart';
import 'package:sss/features/dashboard/presentation/screens/enterprise_dashboard.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';
import 'package:sss/features/orders/presentation/screens/staff_panel.dart'; // Ensure this import is correct based on your project structure. If StaffPanelDesktop is in orders, keeping it.

class TenantSetupScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantSetupScreen({super.key, required this.tenant});

  @override
  State<TenantSetupScreen> createState() => _TenantSetupScreenState();
}

class _TenantSetupScreenState extends State<TenantSetupScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _licenseKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _processSetupAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      // 1. Verify License Key
      final licenseService = getIt<LicenseService>();
      final key = _licenseKeyController.text.trim();
      final isValid = await licenseService.verifyLicense(key);

      if (!isValid) {
        throw Exception("Invalid or expired license key.");
      }

      // 2. Prepare Configuration
      final configRepo = getIt<ConfigurationRepository>();
      final currentConfig = await configRepo.getConfiguration();

      final newConfig = currentConfig.copyWith(
        isConfigured: true,
        tenantId: widget.tenant.id,
        tierId: widget.tenant.tierId,
        businessName: widget.tenant.businessName,
        contactEmail: widget.tenant.email,
        contactPhone: widget.tenant.phone,
        businessAddress: '', // Default empty if not provided
        currency: 'KSH', // Default
        statusTrackingMode: widget.tenant.tierId == 'enterprise' 
            ? StatusTrackingMode.itemLevel 
            : StatusTrackingMode.orderLevel,
      );

      // 3. Save Configuration
      await configRepo.saveConfiguration(newConfig);
      
      // 4. Reload Orders
      if (mounted) {
         context.read<OrderBloc>().add(const LoadOrders());
      }

      if (mounted) {
        // 5. Navigate
        final isEnterprise = widget.tenant.tierId == 'enterprise';
        if (isEnterprise) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const EnterpriseDashboard()),
              (route) => false,
            );
        } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const StaffPanel()),
              (route) => false,
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activation Failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppColors.primaryBlue),
              const Color(AppColors.primaryBlue).withValues(alpha: 0.8),
              const Color(0xFF0A6F38),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildLicenseStep(),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppColors.primaryBlue),
            const Color(0xFF0A6F38),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
           Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activate Terminal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Setting up ${widget.tenant.businessName}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter License Key',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your KFL license key to activate this terminal and link it to your account.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _licenseKeyController,
              decoration: InputDecoration(
                labelText: 'License Key',
                hintText: 'KFL-XXXX-XXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key, color: Color(AppColors.primaryBlue)),
                filled: true,
                fillColor: Colors.grey[50],
                helperText: 'You can find your license key in your administrator dashboard.',
              ),
              validator: (v) => v!.trim().isEmpty ? 'License key is required' : null,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tier: ${widget.tenant.tierId.toUpperCase()}\nCurrency: KSH (KES)',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _processSetupAndSave,
            icon: _isSaving 
               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
               : const Icon(Icons.check_circle),
            label: Text(_isSaving ? 'Activating...' : 'Activate & Launch'),
            style: ElevatedButton.styleFrom(
               backgroundColor: const Color(AppColors.primaryBlue),
               foregroundColor: Colors.white,
               padding: const EdgeInsets.symmetric(vertical: 16),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
          ),
          const SizedBox(height: 16),
          Text(
            'By activating, you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

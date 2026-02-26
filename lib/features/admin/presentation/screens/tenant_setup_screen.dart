import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/core/services/license_service.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/screens/enterprise_dashboard.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_desktop.dart'; // Ensure this import is correct based on your project structure. If StaffPanelDesktop is in orders, keeping it.

class TenantSetupScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantSetupScreen({super.key, required this.tenant});

  @override
  State<TenantSetupScreen> createState() => _TenantSetupScreenState();
}

class _TenantSetupScreenState extends State<TenantSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form keys for validation
  final _businessFormKey = GlobalKey<FormState>();
  final _settingsFormKey = GlobalKey<FormState>();
  final _licenseFormKey = GlobalKey<FormState>();

  // Form controllers
  final _businessNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _licenseKeyController = TextEditingController();

  // Settings
  String _selectedCurrency = 'KSH';
  String? _selectedWarehouse;
  bool _enableNotifications = true;
  StatusTrackingMode _statusTrackingMode = StatusTrackingMode.orderLevel;

  final List<String> _currencies = ['KSH', 'USD', 'EUR', 'GBP', 'TZS', 'UGX'];
  final List<String> _warehouses = ['Main Warehouse', 'Flour Warehouse', 'Oil Warehouse', 'Premium Warehouse'];

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
    
    // Pre-fill data from Tenant object
    _businessNameController.text = widget.tenant.businessName;
    _contactEmailController.text = widget.tenant.email;
    _contactPhoneController.text = widget.tenant.phone;
    
    // Auto-set tracking mode based on Tier
    if (widget.tenant.tierId == 'enterprise') {
      _statusTrackingMode = StatusTrackingMode.itemLevel;
    } else {
      _statusTrackingMode = StatusTrackingMode.orderLevel;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _businessNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _businessAddressController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _processSetupAndSave() async {
    if (!_licenseFormKey.currentState!.validate()) return;
    
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
        tenantId: widget.tenant.id, // Use actual tenant ID
        tierId: widget.tenant.tierId,
        businessName: _businessNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        defaultWarehouse: widget.tenant.tierId == 'enterprise' ? _selectedWarehouse : null,
        currency: _selectedCurrency,
        enableNotifications: _enableNotifications,
        statusTrackingMode: _statusTrackingMode,
      );

      // 3. Save Configuration
      await configRepo.saveConfiguration(newConfig);
      
      // 4. Reload Orders to reflect new config
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
              MaterialPageRoute(builder: (_) => const StaffPanelDesktop()),
              (route) => false,
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup Failed: ${e.toString().replaceAll("Exception: ", "")}'),
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (_businessFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_settingsFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
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
                  constraints: const BoxConstraints(maxWidth: 900),
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
                      _buildProgressIndicator(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStep(),
                      ),
                      _buildNavigationButtons(),
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
                  'Welcome to SSS Kiosk',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Setting up for ${widget.tenant.businessName} (${widget.tenant.tierId.toUpperCase()} Tier)",
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

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Business Info', Icons.business),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Configuration', Icons.settings_suggest),
          _buildStepLine(1),
          _buildStepIndicator(2, 'License & Review', Icons.verified_user),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(AppColors.primaryBlue)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: const Color(AppColors.primaryBlue).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(AppColors.primaryBlue) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isActive ? const Color(AppColors.primaryBlue) : Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBusinessInfoStep();
      case 1:
        return _buildSettingsStep();
      case 2:
        return _buildReviewAndLicenseStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessInfoStep() {
    return Padding(
      key: const ValueKey('business'),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _businessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
            ),
            const SizedBox(height: 8),
            Text('Confirm your business details from your account', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _businessNameController,
              label: 'Business Name',
              hint: 'Enter your business name',
              icon: Icons.business,
              readOnly: true, // Pre-filled from Account
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _contactEmailController,
              label: 'Contact Email',
              hint: 'email@example.com',
              icon: Icons.email,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _contactPhoneController,
              label: 'Contact Phone',
              hint: '+254 700 000 000',
              icon: Icons.phone,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessAddressController,
              label: 'Business Address',
              hint: 'Enter your business address',
              icon: Icons.location_on,
              maxLines: 2,
              validator: (v) => v!.isEmpty ? 'Address is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsStep() {
    final isEnterprise = widget.tenant.tierId == 'enterprise';
    
    return Padding(
      key: const ValueKey('settings'),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _settingsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Configuration',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
            ),
            const SizedBox(height: 8),
            Text(
              isEnterprise ? 'Configure Enterprise features' : 'Configure Standard features',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            
            _buildDropdownField(
              label: 'Currency',
              icon: Icons.attach_money,
              value: _selectedCurrency,
              items: _currencies,
              onChanged: (value) => setState(() => _selectedCurrency = value!),
            ),
            
            if (isEnterprise) ...[
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Default Warehouse',
                icon: Icons.warehouse,
                value: _selectedWarehouse,
                items: _warehouses,
                hint: 'Select a warehouse',
                onChanged: (value) => setState(() => _selectedWarehouse = value),
              ),
              const SizedBox(height: 16),
               Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                     const Icon(Icons.info_outline, color: Colors.blue),
                     const SizedBox(width: 12),
                     const Expanded(child: Text("Enterprise Tier includes Advanced Warehouse Management.", style: TextStyle(color: Colors.blue))),
                  ],
                ),
               )
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            _buildDropdownField(
              label: 'Order Tracking Mode',
              icon: Icons.track_changes,
              value: _statusTrackingMode == StatusTrackingMode.orderLevel ? 'Order Level' : 'Item Level',
              items: const ['Order Level', 'Item Level'],
              onChanged: (value) => setState(() {
                _statusTrackingMode = value == 'Order Level'
                    ? StatusTrackingMode.orderLevel
                    : StatusTrackingMode.itemLevel;
              }),
            ),
            const SizedBox(height: 24),
            _buildSwitchTile(
              title: 'Enable Notifications',
              subtitle: 'Receive alerts for new orders and updates',
              icon: Icons.notifications_active,
              value: _enableNotifications,
              onChanged: (value) => setState(() => _enableNotifications = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewAndLicenseStep() {
    return Padding(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _licenseFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Final Verification',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
            ),
            const SizedBox(height: 8),
            Text('Enter your license key to activate the terminal', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            
            // License Input
            TextFormField(
              controller: _licenseKeyController,
              decoration: InputDecoration(
                labelText: 'License Key',
                hintText: 'KFL-XXXX-XXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key, color: Color(AppColors.primaryBlue)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (v) => v!.trim().isEmpty ? 'License key is required' : null,
            ),

            const SizedBox(height: 32),
            _buildReviewSection(
              'Configuration Summary',
              Icons.list_alt,
              [
                _buildReviewItem('Business Name', _businessNameController.text),
                _buildReviewItem('Tier', widget.tenant.tierId.toUpperCase()),
                _buildReviewItem('Currency', _selectedCurrency),
                if (_selectedWarehouse != null)
                   _buildReviewItem('Warehouse', _selectedWarehouse!),
                _buildReviewItem('Tracking', _statusTrackingMode == StatusTrackingMode.orderLevel ? 'Order Level' : 'Item Level'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(String title, IconData icon, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(AppColors.primaryBlue), size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 24),
          ...items,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[200] : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    String? hint,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: hint != null ? Text(hint) : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: const Color(AppColors.primaryBlue)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(onPressed: _previousStep, child: const Text('Back')),
          const Spacer(),
          if (_currentStep < 2)
            ElevatedButton(
               onPressed: _nextStep, 
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(AppColors.primaryBlue),
                 foregroundColor: Colors.white,
               ),
               child: const Text('Next'),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _processSetupAndSave,
              icon: _isSaving 
                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                 : const Icon(Icons.check_circle),
              label: Text(_isSaving ? 'Activating...' : 'Complete & Launch'),
              style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(AppColors.primaryBlue),
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               ),
            ),
        ],
      ),
    );
  }
}

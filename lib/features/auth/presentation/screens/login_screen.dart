import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/core/configuration/domain/entities/app_configuration.dart';
import 'package:kfm_kiosk/core/services/local_server_service.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/staff_panel_desktop.dart';
import 'package:kfm_kiosk/features/admin/presentation/screens/tenant_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/branch.dart';
import 'package:kfm_kiosk/features/dashboard/presentation/screens/enterprise_dashboard.dart';
import 'package:kfm_kiosk/features/warehouse/domain/services/warehouse_service.dart';
import 'package:kfm_kiosk/features/warehouse/domain/entities/warehouse.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/staff_panel_warehouse.dart';
import 'package:kfm_kiosk/di/injection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Client ID
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    setState(() => _isLoading = true);

    // 1. Check Warehouse Staff Login
    try {
      final warehouseService = getIt<WarehouseService>();
      final warehouse = await warehouseService.authenticate(email, password);
      
      if (warehouse != null) {
         if (!mounted) return;
         await _onWarehouseAuthSuccess(warehouse);
         return;
      }
    } catch (e) {
      debugPrint('Warehouse Login Error: $e');
    }
    
    // Check if it's a Branch Manager Login
    final tenantService = TenantService();
    Branch? matchedBranch;
    Tenant? branchTenant;
    
    for (var t in tenantService.getTenants()) {
       final branches = await tenantService.getBranchesForTenant(t.id);
       try {
         final branch = branches.firstWhere((b) => 
           b.loginUsername.toLowerCase() == email.toLowerCase() && 
           b.loginPassword == password
         );
         matchedBranch = branch;
         branchTenant = t;
         break;
       } catch (_) {}
    }
    
    if (matchedBranch != null && branchTenant != null) {
      _onBranchAuthSuccess(branchTenant, matchedBranch);
      return;
    }
    
    // Standard Tenant/Admin Login
    if (!mounted) return;
    context.read<AuthBloc>().add(LoginRequested(email, password));
  }

  Future<void> _onWarehouseAuthSuccess(Warehouse warehouse) async {
    final tenantService = TenantService();
    final tenant = await tenantService.getTenantForBranch(warehouse.branchId);
    
    if (tenant == null) {
       if (!mounted) return;
       setState(() {
         _errorMessage = 'Configuration Error: Associated Tenant not found.';
         _isLoading = false;
       });
       return;
    }

    if (!mounted) return;
    final repo = context.read<OrderBloc>().configurationRepository;
    var config = await repo.getConfiguration();
    
    config = config.copyWith(
      tenantId: tenant.id,
      branchId: warehouse.branchId,
      warehouseId: warehouse.id, // NEW: Track Warehouse Session
      tierId: tenant.tierId,
      businessName: tenant.businessName,
      contactEmail: tenant.email,
      contactPhone: tenant.phone,
      statusTrackingMode: StatusTrackingMode.itemLevel,
      isConfigured: true, 
    );
    
    await repo.saveConfiguration(config);
    // Set Local Server context for syncing tablets
    getIt<LocalServerService>().setActiveTenantId(
      tenant.id, 
      branchId: warehouse.branchId,
      warehouseId: warehouse.id, // NEW: Broadcast Warehouse State
      tierId: 'enterprise',
    );

    // Only apply the tier styling constraints if they are NOT the parent branch manager navigating into their own warehouse.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StaffPanelWarehouse(warehouse: warehouse)),
      );
    }
  }

  Future<void> _onBranchAuthSuccess(Tenant tenant, Branch branch) async {
      if (!mounted) return;
      final repo = context.read<OrderBloc>().configurationRepository;
      var config = await repo.getConfiguration();
      
      config = config.copyWith(
        tenantId: tenant.id,
        branchId: branch.id,
        clearWarehouseId: true, // Branches map up to their enterprise parent's tier
        tierId: 'enterprise',
        businessName: tenant.businessName,
        contactEmail: tenant.email,
        contactPhone: tenant.phone,
        isConfigured: true, 
      );
      
      await repo.saveConfiguration(config);
      // Notify Local Server (Desktop only)
      getIt<LocalServerService>().setActiveTenantId(
        tenant.id, 
        branchId: branch.id,
        warehouseId: null,
        tierId: 'enterprise',
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffPanelDesktop()),
        );
      }
  }

  Future<void> _onAuthSuccess(Tenant tenant) async {
    final isEnterprise = tenant.tierId == 'enterprise';
    final tierId = tenant.tierId;
    
    final repo = context.read<OrderBloc>().configurationRepository;
    var config = await repo.getConfiguration();

    final wasConfigured = config.isConfigured;
    
    config = config.copyWith(
      tenantId: tenant.id,
      clearBranchId: true, // Tenant-level logins never have an active branch context.
      tierId: tierId,
      isConfigured: true,
    );
    
    getIt<LocalServerService>().setActiveTenantId(
      tenant.id, 
      branchId: null,
      warehouseId: null,
      tierId: tierId,
    );
    
    await repo.saveConfiguration(config);
    
    if (mounted) {
      if (tenant.id == 'SUPER_ADMIN') {
         var adminConfig = config.copyWith(isConfigured: true);
         await repo.saveConfiguration(adminConfig);
         if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffPanelDesktop()),
        );
      } else if (isEnterprise) {
         if (!wasConfigured) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TenantSetupScreen(tenant: tenant),
              ),
            );
         } else {
             if (!mounted) return;
             Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const EnterpriseDashboard()),
              (route) => false,
            );
         }
      } else {
        if (!wasConfigured) {
           if (!mounted) return;
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TenantSetupScreen(tenant: tenant),
            ),
          );
        } else {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StaffPanelDesktop()),
          );
        }
      }
    }
  }

  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data cleared!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _onAuthSuccess(state.tenant);
        } else if (state is AuthFailure) {
           setState(() {
             _errorMessage = state.message;
             _isLoading = false;
           });
        } else if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // Desktop / Tablet Landscape Layout
              return Row(
                children: [
                  Expanded(flex: 1, child: _buildBrandingPanel()),
                  Expanded(flex: 1, child: _buildLoginForm(constraints)),
                ],
              );
            } else {
              // Mobile / Tablet Portrait Layout
              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _buildBrandingPanel(),
                    ),
                    _buildLoginForm(constraints),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      color: const Color(0xFF1a237e),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'SSS Kiosk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage your business with ease',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: TextButton.icon(
              onPressed: _clearData,
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              label: const Text('Clear Local Data (Dev)', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BoxConstraints constraints) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a237e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your credentials to access your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Client ID',
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Use your Tenant ID as password',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Client ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a237e),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

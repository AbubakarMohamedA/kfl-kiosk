import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/auth/domain/services/tenant_service.dart';
import 'package:sss/features/home/presentation/screens/home_screen.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/core/services/local_server_service.dart';
import 'package:sss/features/orders/presentation/screens/staff_panel.dart';
import 'package:sss/features/admin/presentation/screens/tenant_setup_screen.dart';
import 'package:sss/features/warehouse/domain/entities/warehouse.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sss/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sss/features/auth/domain/entities/tenant.dart';
import 'package:sss/core/services/cloud_heartbeat_service.dart';
import 'package:sss/features/auth/domain/entities/branch.dart';
import 'package:sss/features/dashboard/presentation/screens/enterprise_dashboard.dart';
import 'package:sss/features/warehouse/presentation/screens/staff_panel_warehouse.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/core/config/app_role.dart';

import '../../domain/repositories/auth_repository.dart';

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
    
    try {
      final roleConfig = getIt<RoleConfig>();
      final tenantService = TenantService();

      // NEW: Primary Cloud Authentication with Local Super Admin Fallback (All Platforms)
      Map<String, dynamic>? cloudAuth;
      final isSuperAdminEmail = email.toLowerCase() == 'admin@sss.com';

      if (isSuperAdminEmail) {
        final localTenant = tenantService.login(email, password);
        if (localTenant != null && localTenant.id == 'SUPER_ADMIN') {
          cloudAuth = {
            'type': 'tenant',
            'id': localTenant.id,
            'data': {
              'email': localTenant.email,
              'businessName': localTenant.businessName,
              'phone': localTenant.phone,
              'status': localTenant.status,
              'tierId': localTenant.tierId,
            }
          };
        }
      } else {
        cloudAuth = await tenantService.cloudLogin(email, password, roleConfig.role);

        // Fallback: try from local DB if cloud is unavailable
        cloudAuth ??= await tenantService.localLogin(email, password, roleConfig.role);
      }
      
      if (cloudAuth != null) {
         final type = cloudAuth['type'];
         final data = cloudAuth['data'] as Map<String, dynamic>;
         final id = cloudAuth['id'];
         
         if (type == 'tenant') {
            final tenant = Tenant(
              id: id,
              name: data['businessName'] ?? 'Admin', // Use businessName as name fallback
              email: data['email'],
              phone: data['phone'],
              businessName: data['businessName'],
              tierId: data['tierId'],
              status: data['status'] ?? 'Active',
              createdDate: DateTime.now(), // Fallback if missing
            );
            await _onAuthSuccess(tenant);
            return;
         } else if (type == 'branch') {
            final tenantId = cloudAuth['tenantId'];
            final tData = cloudAuth['tenantData'] as Map<String, dynamic>?;
            
            Tenant? tenant;
            try {
              tenant = tenantService.getTenants().firstWhere((t) => t.id == tenantId);
            } catch (e) {
              if (tData != null) {
                tenant = Tenant(
                  id: tenantId,
                  name: tData['name'] ?? tData['businessName'] ?? 'Admin',
                  email: tData['email'] ?? '',
                  phone: tData['phone'] ?? '',
                  businessName: tData['businessName'] ?? '',
                  tierId: tData['tierId'] ?? 'enterprise',
                  status: tData['status'] ?? 'Active',
                  createdDate: DateTime.now(),
                  enabledFeatures: List<String>.from(tData['enabledFeatures'] ?? []),
                );
                await tenantService.addTenant(tenant);
              }
            }

            if (tenant == null) {
              _showError('Configuration Error: Associated Tenant not found.');
              return;
            }

            final branch = Branch(
              id: id,
              tenantId: tenantId,
              name: data['name'] ?? '',
              location: data['location'] ?? '',
              contactPhone: data['contactPhone'] ?? '',
              managerName: data['managerName'] ?? '',
              loginUsername: data['loginUsername'] ?? '',
              loginPassword: data['loginPassword'] ?? '',
            );
            
            await tenantService.addBranch(branch);

            _onBranchAuthSuccess(tenant, branch);
            return;
         } else if (type == 'warehouse') {
             final warehouse = Warehouse(
               id: id,
               tenantId: cloudAuth['tenantId'],
               branchId: cloudAuth['branchId'],
               name: data['name'] ?? '',
               categories: List<String>.from((data['categories'] as List<dynamic>?) ?? []),
               loginUsername: data['loginUsername'] ?? '',
               loginPassword: data['loginPassword'] ?? '',
             );
             await _onWarehouseAuthSuccess(warehouse, cloudAuth);
             return;
         }
      }

      _showError('Invalid credentials or cloud service unavailable. Please check your internet connection.');

    } catch (e) {
      _showError('An unexpected error occurred during login: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _onWarehouseAuthSuccess(Warehouse warehouse, Map<String, dynamic> cloudAuth) async {
    final tenantService = TenantService();
    final tenantId = warehouse.tenantId;
    final branchId = warehouse.branchId;
    
    Tenant? tenant;
    try {
      tenant = tenantService.getTenants().firstWhere((t) => t.id == tenantId);
    } catch (_) {
      final tData = cloudAuth['tenantData'] as Map<String, dynamic>?;
      if (tData != null) {
        tenant = Tenant(
          id: tenantId,
          name: tData['name'] ?? tData['businessName'] ?? 'Admin',
          email: tData['email'] ?? '',
          phone: tData['phone'] ?? '',
          businessName: tData['businessName'] ?? '',
          tierId: tData['tierId'] ?? 'enterprise',
          status: tData['status'] ?? 'Active',
          createdDate: DateTime.now(),
          enabledFeatures: List<String>.from(tData['enabledFeatures'] ?? []),
        );
        await tenantService.addTenant(tenant);
      }
    }

    if (tenant == null) {
       _showError('Configuration Error: Associated Tenant not found.');
       return;
    }
    
    Branch? branch = await tenantService.getBranchById(branchId);
    if (branch == null) {
      final bData = cloudAuth['branchData'] as Map<String, dynamic>?;
      if (bData != null) {
        branch = Branch(
          id: branchId,
          tenantId: tenantId,
          name: bData['name'] ?? '',
          location: bData['location'] ?? '',
          contactPhone: bData['contactPhone'] ?? '',
          managerName: bData['managerName'] ?? '',
          loginUsername: bData['loginUsername'] ?? '',
          loginPassword: bData['loginPassword'] ?? '',
        );
        await tenantService.addBranch(branch);
      }
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
    // Persist Session
    await getIt<AuthRepository>().saveSession(tenant);
    getIt<CloudHeartbeatService>().start(); // START HEARTBEAT

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
      // Persist Session
      await getIt<AuthRepository>().saveSession(tenant);
      getIt<CloudHeartbeatService>().start(); // START HEARTBEAT

      // Notify Local Server (Desktop only)
      getIt<LocalServerService>().setActiveTenantId(
        tenant.id, 
        branchId: branch.id,
        warehouseId: null,
        tierId: 'enterprise',
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffPanel()),
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
    
    // Persist Session
    await getIt<AuthRepository>().saveSession(tenant);
    getIt<CloudHeartbeatService>().start(); // START HEARTBEAT
    
    if (mounted) {
      if (tenant.id == 'SUPER_ADMIN') {
         var adminConfig = config.copyWith(isConfigured: true);
         await repo.saveConfiguration(adminConfig);
         if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
            MaterialPageRoute(builder: (_) => const StaffPanel()),
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
          final roleConfig = getIt<RoleConfig>();
          final isSuperAdmin = state.tenant.id == 'SUPER_ADMIN';

          // Super Admin Build Enforcement (Bypassed on Linux to allow initial tenant setup)
          if (!Platform.isLinux) {
            if (isSuperAdmin && roleConfig.role != AppRole.superAdmin) {
              _showError('Access Denied: Please use the Super Admin App to log in.');
              context.read<AuthBloc>().add(LogoutRequested()); 
              return;
            } else if (!isSuperAdmin && roleConfig.role == AppRole.superAdmin) {
              _showError('Access Denied: This app is restricted to Super Administrators only.');
              context.read<AuthBloc>().add(LogoutRequested()); 
              return;
            }
          }
          
          // Enterprise Dashboard Build Enforcement
          if (roleConfig.role == AppRole.dashboard && !isSuperAdmin) {
            final isEnterprise = state.tenant.tierId == 'enterprise';
            if (!isEnterprise) {
              _showError('Access Denied: The Enterprise Dashboard requires an Enterprise Tier subscription.');
              context.read<AuthBloc>().add(LogoutRequested());
              return;
            }
          }

          _onAuthSuccess(state.tenant);
        } else if (state is AuthFailure) {
           _showError(state.message);
        } else if (state is AuthLoading) {
           setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        } else if (state is AuthUnauthenticated) {
            // Unauthenticated state reset
            setState(() {
              _isLoading = false;
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
          // Positioned(
          //   bottom: 20,
          //   left: 20,
          //   child: TextButton.icon(
          //     onPressed: _clearData,
          //     icon: const Icon(Icons.delete_outline, color: Colors.white54),
          //     label: const Text('Clear Local Data (Dev)', style: TextStyle(color: Colors.white54)),
          //   ),
          // ),
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

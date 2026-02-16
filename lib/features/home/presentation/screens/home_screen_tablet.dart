import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kfm_kiosk/features/orders/data/datasources/local_order_datasource.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_state.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/catalog_screen_tablet.dart';
import 'package:kfm_kiosk/features/auth/presentation/bloc/auth_bloc.dart';

class HomeScreenTablet extends StatefulWidget {
  const HomeScreenTablet({super.key});

  @override
  State<HomeScreenTablet> createState() => _HomeScreenTabletState();
}

class _HomeScreenTabletState extends State<HomeScreenTablet> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  void _checkConnection() {
    final orderDataSource = getIt<LocalOrderDataSource>();
    setState(() {
      _isConnected = orderDataSource.isOnline;
    });
  }

  void _showServerUrlDialog() {
    final orderDataSource = getIt<LocalOrderDataSource>();
    final controller = TextEditingController(text: orderDataSource.serverUrl ?? '');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B7A43).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Sync Server'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://192.168.1.100:8080',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isConnected ? Colors.green[200]! : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.check_circle : Icons.info_outline,
                        color: _isConnected ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isConnected
                              ? 'Connected! Orders will sync.'
                              : 'Enter server URL and connect',
                          style: TextStyle(
                            color: _isConnected ? Colors.green[800] : Colors.orange[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  await orderDataSource.setServerUrl(controller.text);
                  await Future.delayed(const Duration(seconds: 1));
                  
                  setState(() {
                    _isConnected = orderDataSource.isOnline;
                  });
                  setDialogState(() {});
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          orderDataSource.isOnline
                              ? 'Connected to server!'
                              : 'Could not connect. Check server.',
                        ),
                        backgroundColor: orderDataSource.isOnline ? Colors.green : Colors.red,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7A43),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Connect'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tenant Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Tenant ID'),
              obscureText: true,
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
              context.read<AuthBloc>().add(
                    LoginRequested(
                      emailController.text,
                      passwordController.text,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome, ${state.tenant.name}!'), backgroundColor: Colors.green),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B7A43), // Base green color
        ),
        child: Stack(
          children: [
            // Pattern background
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/Pattern.svg',
                fit: BoxFit.cover,
              ),
            ),
            
            // Settings and Auth buttons at top right
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Auth Status / Logout
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated) {
                          return GestureDetector(
                            onTap: () {
                              context.read<AuthBloc>().add(LogoutRequested());
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.tenant.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.logout, color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                          );
                        }
                        return GestureDetector(
                          onTap: _showLoginDialog,
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.login, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Login', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Connection Status & Settings
                    GestureDetector(
                      onTap: _showServerUrlDialog,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isConnected ? Icons.cloud_done : Icons.cloud_off,
                              color: _isConnected ? Colors.greenAccent : Colors.white70,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: BlocBuilder<LanguageCubit, LanguageState>(
                  builder: (context, languageState) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo at center above welcome text
                        SizedBox(
                          width: size.width * 0.15,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: size.height * 0.04),

                        // WELCOME TEXT (without "TO")
                        Text(
                          'WELCOME',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.05,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: size.height * 0.05),

                        // START ORDER BUTTON (Only if authenticated)
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is! AuthAuthenticated) {
                              return Text(
                                'Please login to start taking orders',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: size.width * 0.02,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CatalogScreenTablet(
                                      language: languageState.languageCode,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.08,
                                  vertical: size.height * 0.025,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8562A),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  languageState.translate('start_order'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size.width * 0.03,
                                    fontStyle: FontStyle.italic,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: size.height * 0.03),

                        // LANGUAGE BUTTONS (Custom implementation to match design)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLanguageButton(
                              context,
                              'English',
                              languageState.languageCode == 'en',
                              () {
                                context.read<LanguageCubit>().changeLanguage('en');
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildLanguageButton(
                              context,
                              'Swahili',
                              languageState.languageCode == 'sw',
                              () {
                                context.read<LanguageCubit>().changeLanguage('sw');
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final size = MediaQuery.sizeOf(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.045,
          vertical: size.height * 0.018,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFE8562A) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontSize: size.width * 0.018,
            fontWeight: FontWeight.w600,
            fontFamily: 'Lato',
          ),
        ),
      ),
    );
  }
}
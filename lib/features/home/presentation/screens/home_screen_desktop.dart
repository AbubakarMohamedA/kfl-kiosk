import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'package:kfm_kiosk/features/orders/data/datasources/local_order_datasource.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_state.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/catalog_screen_desktop.dart';
import 'package:kfm_kiosk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kfm_kiosk/core/services/sync_service.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_event.dart';

class HomeScreenDesktop extends StatefulWidget {
  const HomeScreenDesktop({super.key});

  @override
  State<HomeScreenDesktop> createState() => _HomeScreenDesktopState();
}

class _HomeScreenDesktopState extends State<HomeScreenDesktop> {
  bool _isConnected = false;
  
  String? _backgroundPath;
  String? _logoPath;
  Color _primaryColor = const Color(0xFF1B7A43);
  String _terminalName = '';
  StreamSubscription<TenantConfig?>? _configSubscription;
  int _cloudTapCount = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _autoConnect();
    _setupStream();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _tapResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _setupStream() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('last_synced_tenant_id');
    final tName = prefs.getString('terminal_name') ?? '';
    
    setState(() {
       _terminalName = tName;
    });

    if (tenantId != null) {
      _configSubscription?.cancel();
      _configSubscription = getIt<TenantConfigDao>().watchConfig(tenantId).listen((config) async {
        if (config != null && mounted) {
          String? validBgPath = config.backgroundPath;
          String? validLogoPath = config.logoPath;
          
          if (validLogoPath != null && validLogoPath.isNotEmpty) {
            final file = File(validLogoPath);
            if (!await file.exists()) {
               validLogoPath = null;
            }
          }

          setState(() {
            _backgroundPath = validBgPath;
            _logoPath = validLogoPath;
            if (config.primaryColor != null) {
              _primaryColor = Color(config.primaryColor!);
            }
          });
        }
      });
    }
  }

  Future<void> _autoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp != null && savedIp.isNotEmpty) {
      final syncService = getIt<SyncService>();
      final result = await syncService.connectAndSync(savedIp);
      if (mounted) {
        setState(() {
          _isConnected = result.success;
        });
        if (result.success) {
          syncService.startAutoSync(savedIp);
        }
      }
    }
  }

  void _checkConnection() {
    final orderDataSource = getIt<LocalOrderDataSource>();
    setState(() {
      _isConnected = orderDataSource.isOnline;
    });
  }

  void _showServerUrlDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip') ?? '';
    final controller = TextEditingController(text: savedIp);
    final terminalController = TextEditingController(text: _terminalName);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B7A43).withValues(alpha: 0.1),
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
                    labelText: 'Server IP Address',
                    hintText: 'e.g. 192.168.1.10',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: terminalController,
                  decoration: InputDecoration(
                    labelText: 'Terminal Name (Optional)',
                    hintText: 'e.g. Kiosk 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.badge),
                  ),
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
                          overflow: TextOverflow.ellipsis,
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
                  final ip = controller.text.trim();
                  final tName = terminalController.text.trim();
                  if (ip.isEmpty) return;

                  if (tName.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('terminal_name', tName);
                  }

                  final syncService = getIt<SyncService>();
                  final result = await syncService.connectAndSync(ip);
                  
                  if (context.mounted) {
                    setState(() {
                      _isConnected = result.success;
                    });
                    setDialogState(() {});
                    
                    if (result.success) {
                      syncService.startAutoSync(ip);
                      _setupStream(); // Register stream listener on fresh install
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.success
                              ? 'Connected to server!'
                              : (result.troubleshootingStep ?? result.message),
                        ),
                        backgroundColor: result.success ? Colors.green : Colors.red,
                      ),
                    );
                    if (result.success) Navigator.pop(context);
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


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Desktop uses slightly smaller multiplier relative to width for ultra-wide monitors
    final logoWidth = size.width * 0.12; 
    final welcomeSize = size.width * 0.035;
    final buttonPaddingH = size.width * 0.05;
    final buttonPaddingV = size.height * 0.03;
    final buttonTextSize = size.width * 0.02;
    final langPaddingH = size.width * 0.025;
    final langPaddingV = size.height * 0.012;
    final langTextSize = size.width * 0.012;

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
        decoration: BoxDecoration(
          color: _primaryColor, // Base green color or custom from config
        ),
        child: Stack(
          children: [
            // Pattern background
            Positioned.fill(
              child: _backgroundPath != null && _backgroundPath!.isNotEmpty && _backgroundPath!.endsWith('.svg')
                  ? SvgPicture.asset(
                      _backgroundPath!,
                      fit: BoxFit.cover,
                    )
                  : SvgPicture.asset(
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
                    // Connection Status & Settings (Login removed for standard flow sync)
                    GestureDetector(
                      onTap: () {
                        _tapResetTimer?.cancel();
                        setState(() {
                          _cloudTapCount++;
                        });
                        if (_cloudTapCount >= 5) {
                          setState(() {
                            _cloudTapCount = 0;
                          });
                          _showServerUrlDialog();
                        } else {
                          _tapResetTimer = Timer(const Duration(seconds: 2), () {
                            if (mounted) {
                              setState(() {
                                _cloudTapCount = 0;
                              });
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
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
                          width: logoWidth,
                          child: _logoPath != null && _logoPath!.isNotEmpty
                              ? Image.file(
                                  File(_logoPath!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                        SizedBox(height: size.height * 0.04),

                        // WELCOME TEXT 
                        Text(
                          'WELCOME',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: welcomeSize,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: size.height * 0.05),

                        // START ORDER BUTTON (Now always visible)
                        GestureDetector(
                          onTap: () {
                            // Refresh products before entering catalogue
                            context.read<ProductBloc>().add(const LoadProducts());

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CatalogScreenDesktop(
                                  language: languageState.languageCode,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
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
                                fontSize: buttonTextSize,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),

                        // LANGUAGE BUTTONS
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
                              langPaddingH,
                              langPaddingV,
                              langTextSize,
                            ),
                            const SizedBox(width: 16),
                            _buildLanguageButton(
                              context,
                              'Swahili',
                              languageState.languageCode == 'sw',
                              () {
                                context.read<LanguageCubit>().changeLanguage('sw');
                              },
                              langPaddingH,
                              langPaddingV,
                              langTextSize,
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
    double padH,
    double padV,
    double textSize,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: padH,
          vertical: padV,
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
            fontSize: textSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Lato',
          ),
        ),
      ),
    );
  }
}
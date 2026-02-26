import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:kfm_kiosk/core/services/local_server_service.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MobileConfigScreen extends StatefulWidget {
  const MobileConfigScreen({super.key});

  @override
  State<MobileConfigScreen> createState() => _MobileConfigScreenState();
}

class _MobileConfigScreenState extends State<MobileConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _welcomeController = TextEditingController();
  
  String? _logoPath;
  Color _primaryColor = const Color(0xFF1a237e);
  Color _secondaryColor = const Color(0xFFffd700);
  
  String? _backgroundPath;
  final List<String> _availableBackgrounds = [
    'assets/bg/Pattern_Blue.svg',
    'assets/bg/Pattern_Gold.svg',
    'assets/bg/Pattern_Green.svg',
    'assets/bg/Pattern_Indigo.svg',
    'assets/bg/Pattern_Orange.svg',
    'assets/bg/Pattern_Pink.svg',
    'assets/bg/Pattern_Purple.svg',
    'assets/bg/Pattern_Red.svg',
    'assets/bg/Pattern_Teal.svg',
  ];
  
  String _serverIp = 'Loading...';
  bool _isLoading = true;
  String? _tenantId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _appNameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final serverService = getIt<LocalServerService>();
    final configDao = getIt<TenantConfigDao>();
    final configRepo = getIt<ConfigurationRepository>();
    final currentConfig = await configRepo.getConfiguration();
    
    // 1. Priority: Use already configured tenant
    if (currentConfig.tenantId != null) {
      _tenantId = currentConfig.tenantId;
    } 
    // 2. Fallback: Use 'current' or first tenant found (Seed data context)
    else {
      final tenantService = TenantService(); // Assuming singleton or provider access
      final tenants = tenantService.getTenants();
      if (tenants.isNotEmpty) {
        _tenantId = tenants.first.id;
      }
    }

    final ip = await serverService.getDeviceIp();
    
    TenantConfig? config;
    if (_tenantId != null) {
      config = await configDao.getConfig(_tenantId!);
    }

    if (mounted) {
      setState(() {
        _serverIp = ip ?? 'Unknown';
        if (config != null) {
          _appNameController.text = config.appName ?? '';
          _welcomeController.text = config.welcomeMessage ?? '';
          _logoPath = config.logoPath;
          _backgroundPath = config.backgroundPath;
          if (config.primaryColor != null) _primaryColor = Color(config.primaryColor!);
          if (config.secondaryColor != null) _secondaryColor = Color(config.secondaryColor!);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoPath = image.path;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_tenantId == null) return;
    
    final configDao = getIt<TenantConfigDao>();
    final config = TenantConfigsCompanion(
      tenantId: drift.Value(_tenantId!),
      appName: drift.Value(_appNameController.text),
      welcomeMessage: drift.Value(_welcomeController.text),
      logoPath: drift.Value(_logoPath),
      backgroundPath: drift.Value(_backgroundPath),
      primaryColor: drift.Value(_primaryColor.value), // ignore: deprecated_member_use
      secondaryColor: drift.Value(_secondaryColor.value), // ignore: deprecated_member_use
    );

    await configDao.saveConfig(config);
    
    // Refresh active tenant
    getIt<LocalServerService>().setActiveTenantId(_tenantId!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration Saved! Terminal will update on next sync.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.grey[50], // Or theme based
      appBar: AppBar(
        title: const Text('Terminal Configuration'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          _buildConnectedTerminalsButton(context),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Configuration Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Branding & customization',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        // Logo Picker
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _logoPath != null ? FileImage(File(_logoPath!)) : null,
                              child: _logoPath == null
                                  ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(child: Text('Tap to change Logo')),
                        // const SizedBox(height: 24),

                        // TextFormField(
                        //   controller: _appNameController,
                        //   decoration: const InputDecoration(
                        //     labelText: 'App Name',
                        //     border: OutlineInputBorder(),
                        //     prefixIcon: Icon(Icons.smartphone),
                        //   ),
                        //   onChanged: (value) => setState(() {}),
                        // ),
                        // const SizedBox(height: 16),
                        // TextFormField(
                        //   controller: _welcomeController,
                        //   decoration: const InputDecoration(
                        //     labelText: 'Welcome Message',
                        //     border: OutlineInputBorder(),
                        //     prefixIcon: Icon(Icons.message),
                        //   ),
                        //   onChanged: (value) => setState(() {}),
                        // ),
                        // const SizedBox(height: 24),

                        const Text('Theme Colors', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildColorPicker('Primary', _primaryColor, (c) => setState(() => _primaryColor = c)),
                            const SizedBox(width: 24),
                            _buildColorPicker('Secondary', _secondaryColor, (c) => setState(() => _secondaryColor = c)),
                          ],
                        ),
                        
                        
                        
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _saveConfig,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Configuration'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a237e),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Right Panel: Connection Info & Preview
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
              child: Column(
                children: [
                  // Server Info Card
                  Card(
                    color: const Color(0xFF1a237e),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(Icons.wifi_tethering, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Connect Terminal',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter this IP Address in the Terminal to sync:',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _serverIp, // IP ADDRESS
                              style: const TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Live Preview
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        color: _primaryColor,
                        child: Stack(
                          children: [
                            // Pattern background
                            Positioned.fill(
                              child: _backgroundPath != null && _backgroundPath!.isNotEmpty
                                  ? SvgPicture.asset(
                                      _backgroundPath!,
                                      fit: BoxFit.cover,
                                    )
                                  : SvgPicture.asset(
                                      'assets/images/Pattern.svg',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            
                            // Content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo
                                  SizedBox(
                                    height: 60,
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
                                  const SizedBox(height: 16),
                                  
                                  // Welcome message
                                  Text(
                                    _welcomeController.text.isNotEmpty 
                                        ? _welcomeController.text 
                                        : 'WELCOME',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Start Order Button mock
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8562A),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Start Order',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildColorPicker(String label, Color color, Function(Color) onChanged) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            // Simple color cycler for now, or could open a dialog
            // For MVP, just cycling through a few presets
            final presets = [
              const Color(0xFF1a237e), // Blue
              const Color(0xFFb71c1c), // Red
              const Color(0xFF1b5e20), // Green
              const Color(0xFFf57f17), // Orange
              const Color(0xFF212121), // Black
            ];
            final currentIndex = presets.indexOf(color);
            final nextColor = presets[(currentIndex + 1) % presets.length];
            onChanged(nextColor);
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
              boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
            ),
          ),
        ),
      ],
    );
  }

  int _getOnlineTerminalsCount() {
    try {
      final terminals = getIt<LocalServerService>().getConnectedTerminals();
      return terminals.where((t) => t.isOnline).length;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildConnectedTerminalsButton(BuildContext context) {
    final count = _getOnlineTerminalsCount();
    return Tooltip(
      message: 'Connected Terminals',
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.devices_rounded, color: Color(0xFF1a237e)),
            onPressed: () => _showConnectedTerminalsDialog(context),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showConnectedTerminalsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Timer? dialogRefreshTimer;
            dialogRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
               if (context.mounted) {
                 setStateDialog(() {});
               } else {
                 dialogRefreshTimer?.cancel();
               }
            });
            
            final terminals = getIt<LocalServerService>().getConnectedTerminals();
            
            return AlertDialog(
              title: const Row(
                children: [
                   Icon(Icons.devices_other_rounded, color: Colors.blue),
                   SizedBox(width: 12),
                   Text('Connected Terminals'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: terminals.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No terminals are currently connected.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: terminals.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final terminal = terminals[index];
                          final isOnline = terminal.isOnline;
                          
                          return ListTile(
                            leading: Icon(
                              isOnline ? Icons.tablet_mac_rounded : Icons.tablet_rounded,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                            title: Text(terminal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('IP: ${terminal.ip}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogRefreshTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

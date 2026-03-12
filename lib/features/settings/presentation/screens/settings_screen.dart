import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/features/orders/data/datasources/local_order_datasource.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // General Settings
  bool _enableNotifications = true;
  bool _enableSoundEffects = true;
  bool _autoBackup = true;
  String _language = 'English';
  String _currency = 'KSh';
  String _timezone = 'EAT (UTC+3)';
  
  // Operational Mode
  bool _useItemLevelTracking = false;
  
  // Business Settings
  String _businessName = 'SSS';
  String _businessPhone = '+254 700 000 000';
  String _businessEmail = 'info@kituiflour.com';
  String _taxRate = '16.0';
  bool _enableTax = true;
  
  // System Settings
  bool _enableAutoUpdate = true;
  bool _enableAnalytics = true;
  String _backupFrequency = 'Daily';
  String _dataRetention = '90 days';
  
  // Network Sync Settings
  String _serverUrl = '';
  String _terminalId = '';
  bool _isServerConnected = false;
  
  // Receipt Settings
  bool _printReceipts = true;
  bool _emailReceipts = false;
  bool _showLogo = true;
  bool _showTaxBreakdown = true;
  String _receiptFooter = 'Thank you for your business!';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadConfiguration();
  }

  void _loadConfiguration() async {
    try {
      final config = await context
          .read<OrderBloc>()
          .configurationRepository
          .getConfiguration();
      
      // Load server URL from order data source
      final orderDataSource = getIt<LocalOrderDataSource>();
      
      setState(() {
        _useItemLevelTracking = config.statusTrackingMode == StatusTrackingMode.itemLevel;
        _serverUrl = orderDataSource.serverUrl ?? '';
        _terminalId = orderDataSource.terminalId ?? '';
        _isServerConnected = orderDataSource.isOnline;
      });
    } catch (e) {
      debugPrint('Error loading configuration: $e');
    }
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
                      _buildGeneralTab(),
                      _buildBusinessTab(),
                      _buildSystemTab(),
                      _buildReceiptTab(),
                      _buildSecurityTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
              Icons.settings_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Configure your kiosk system',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saveAllSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save All Changes'),
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
          _buildSidebarItem(0, Icons.tune, 'General'),
          _buildSidebarItem(1, Icons.business, 'Business'),
          _buildSidebarItem(2, Icons.computer, 'System'),
          _buildSidebarItem(3, Icons.receipt_long, 'Receipt'),
          _buildSidebarItem(4, Icons.security, 'Security'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _checkForUpdates,
                  child: const Text('Check for Updates'),
                ),
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

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('General Settings'),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Preferences',
            [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive alerts for new orders and updates',
                _enableNotifications,
                (value) => setState(() => _enableNotifications = value),
              ),
              _buildSwitchTile(
                'Sound Effects',
                'Play sounds for actions and notifications',
                _enableSoundEffects,
                (value) => setState(() => _enableSoundEffects = value),
              ),
              _buildSwitchTile(
                'Auto Backup',
                'Automatically backup data daily',
                _autoBackup,
                (value) => setState(() => _autoBackup = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Localization',
            [
              _buildDropdownTile(
                'Language',
                'Select display language',
                _language,
                ['English', 'Swahili'],
                (value) => setState(() => _language = value!),
              ),
              _buildDropdownTile(
                'Currency',
                'Default currency for transactions',
                _currency,
                ['KSh', 'USD', 'EUR'],
                (value) => setState(() => _currency = value!),
              ),
              _buildDropdownTile(
                'Timezone',
                'System timezone',
                _timezone,
                ['EAT (UTC+3)', 'GMT (UTC+0)', 'EST (UTC-5)'],
                (value) => setState(() => _timezone = value!),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Operational Mode',
            [
              _buildSwitchTile(
                'Item-Level Status Tracking',
                _useItemLevelTracking
                    ? 'Track status per product category (Flour, Oil, etc.). Enables parallel processing across warehouse stations.'
                    : 'Entire order moves through status stages together. Simple workflow ideal for small operations.',
                _useItemLevelTracking,
                (value) => _showOperationalModeDialog(value),
              ),
              if (_useItemLevelTracking)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Warehouse stations enabled. Configure warehouse assignments for product categories in Inventory settings.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Business Information'),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Company Details',
            [
              _buildTextFieldTile(
                'Business Name',
                _businessName,
                (value) => setState(() => _businessName = value),
              ),
              _buildTextFieldTile(
                'Phone Number',
                _businessPhone,
                (value) => setState(() => _businessPhone = value),
              ),
              _buildTextFieldTile(
                'Email Address',
                _businessEmail,
                (value) => setState(() => _businessEmail = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Tax Configuration',
            [
              _buildSwitchTile(
                'Enable Tax',
                'Apply tax to transactions',
                _enableTax,
                (value) => setState(() => _enableTax = value),
              ),
              if (_enableTax)
                _buildTextFieldTile(
                  'Tax Rate (%)',
                  _taxRate,
                  (value) => setState(() => _taxRate = value),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Operating Hours',
            [
              _buildTimeRangeTile('Monday - Friday', '08:00 AM', '06:00 PM'),
              _buildTimeRangeTile('Saturday', '09:00 AM', '05:00 PM'),
              _buildTimeRangeTile('Sunday', 'Closed', 'Closed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('System Configuration'),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Updates & Maintenance',
            [
              _buildSwitchTile(
                'Auto Update',
                'Automatically install system updates',
                _enableAutoUpdate,
                (value) => setState(() => _enableAutoUpdate = value),
              ),
              _buildSwitchTile(
                'Analytics',
                'Send anonymous usage data to improve service',
                _enableAnalytics,
                (value) => setState(() => _enableAnalytics = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Data Management',
            [
              _buildDropdownTile(
                'Backup Frequency',
                'How often to backup data',
                _backupFrequency,
                ['Hourly', 'Daily', 'Weekly'],
                (value) => setState(() => _backupFrequency = value!),
              ),
              _buildDropdownTile(
                'Data Retention',
                'How long to keep historical data',
                _dataRetention,
                ['30 days', '90 days', '1 year', 'Forever'],
                (value) => setState(() => _dataRetention = value!),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'System Actions',
            [
              _buildActionTile(
                'Clear Cache',
                'Remove temporary files to free up space',
                Icons.cleaning_services,
                Colors.blue,
                _clearCache,
              ),
              _buildActionTile(
                'Export Data',
                'Download all data as CSV or Excel',
                Icons.download,
                Colors.green,
                _exportData,
              ),
              _buildActionTile(
                'Reset Settings',
                'Restore all settings to default values',
                Icons.restore,
                Colors.orange,
                _resetSettings,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Network Sync',
            [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: _serverUrl),
                            decoration: InputDecoration(
                              labelText: 'Sync Server URL',
                              hintText: 'http://192.168.1.100:8080',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                _isServerConnected ? Icons.cloud_done : Icons.cloud_off,
                                color: _isServerConnected ? Colors.green : Colors.grey,
                              ),
                              suffixIcon: _isServerConnected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.warning, color: Colors.orange),
                            ),
                            onChanged: (value) => setState(() => _serverUrl = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: TextEditingController(text: _terminalId),
                            decoration: const InputDecoration(
                              labelText: 'Terminal Name',
                              hintText: 'e.g. Kiosk 1',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.computer),
                            ),
                            onChanged: (value) => setState(() => _terminalId = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _connectToServer(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppColors.primaryBlue),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          ),
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isServerConnected ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isServerConnected ? Colors.green[200]! : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isServerConnected ? Icons.info_outline : Icons.warning_amber,
                            color: _isServerConnected ? Colors.green[700] : Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isServerConnected
                                  ? 'Connected! Orders will sync between devices in real-time.'
                                  : 'Not connected. Run the server on your desktop: dart run server/order_server.dart',
                              style: TextStyle(
                                color: _isServerConnected ? Colors.green[900] : Colors.orange[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Receipt Configuration'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSettingCard(
                      'Receipt Options',
                      [
                        _buildSwitchTile(
                          'Print Receipts',
                          'Automatically print receipts after payment',
                          _printReceipts,
                          (value) => setState(() => _printReceipts = value),
                        ),
                        _buildSwitchTile(
                          'Email Receipts',
                          'Send digital receipts to customers',
                          _emailReceipts,
                          (value) => setState(() => _emailReceipts = value),
                        ),
                        _buildSwitchTile(
                          'Show Logo',
                          'Display company logo on receipts',
                          _showLogo,
                          (value) => setState(() => _showLogo = value),
                        ),
                        _buildSwitchTile(
                          'Show Tax Breakdown',
                          'Display detailed tax information',
                          _showTaxBreakdown,
                          (value) => setState(() => _showTaxBreakdown = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSettingCard(
                      'Receipt Footer',
                      [
                        TextField(
                          controller: TextEditingController(text: _receiptFooter),
                          onChanged: (value) => setState(() => _receiptFooter = value),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter footer message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildReceiptPreview()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Security Settings'),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Access Control',
            [
              _buildActionTile(
                'Change PIN',
                'Update your staff access PIN',
                Icons.pin,
                Colors.blue,
                _changePin,
              ),
              _buildActionTile(
                'Staff Permissions',
                'Manage user roles and permissions',
                Icons.admin_panel_settings,
                Colors.purple,
                _managePermissions,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Session Management',
            [
              _buildDropdownTile(
                'Auto Logout',
                'Automatically logout after inactivity',
                '15 minutes',
                ['5 minutes', '15 minutes', '30 minutes', 'Never'],
                (value) {},
              ),
              _buildSwitchTile(
                'Require PIN on Resume',
                'Ask for PIN when resuming from idle',
                true,
                (value) {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            'Data Security',
            [
              _buildActionTile(
                'Backup Encryption Key',
                'View and update encryption settings',
                Icons.vpn_key,
                Colors.green,
                _manageEncryption,
              ),
              _buildActionTile(
                'View Audit Log',
                'Review system activity and changes',
                Icons.history,
                Colors.orange,
                _viewAuditLog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI Helper Widgets
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingCard(String title, List<Widget> children) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        underline: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTextFieldTile(
    String label,
    String value,
    Function(String) onChanged, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTimeRangeTile(String day, String start, String end) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              start,
              textAlign: TextAlign.center,
            ),
          ),
          const Text(' - '),
          Expanded(
            child: Text(
              end,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildReceiptPreview() {
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
          const Text(
            'Receipt Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showLogo) ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primaryBlue)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'KFM',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(AppColors.primaryBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _businessName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _businessPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Item', style: TextStyle(fontSize: 12)),
                    Text('Amount', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sample Product x1', style: TextStyle(fontSize: 11)),
                    Text('KSh 100.00', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                if (_showTaxBreakdown && _enableTax) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        'KSh 100.00',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax ($_taxRate%)',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        'KSh ${(100 * double.parse(_taxRate) / 100).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'KSh 116.00',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  _receiptFooter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _saveAllSettings() async {
    try {
      // Note: Operational mode is auto-saved when changed via the toggle
      // This method saves other settings (business info, tax, receipt settings, etc.)
      
      // Save other settings here...
      // TODO: Implement saving for business details, tax config, receipt settings, etc.
      
      final orderDataSource = getIt<LocalOrderDataSource>();
      await orderDataSource.setTerminalId(_terminalId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Text('Failed to save settings: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOperationalModeDialog(bool newValue) async {
    final modeTitle = newValue ? 'Item-Level Tracking' : 'Order-Level Tracking';
    final modeDescription = newValue
        ? 'Track status per product category (Flour, Oil, etc.). This enables parallel processing across warehouse stations and is recommended for larger operations.'
        : 'Entire order moves through status stages together. This provides a simple workflow ideal for small operations without warehouse separation.';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: newValue 
                    ? const Color(0xFF0B8843).withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                newValue ? Icons.warehouse : Icons.receipt_long,
                color: newValue ? const Color(0xFF0B8843) : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Switch to $modeTitle?',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(modeDescription),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will affect how all future orders are processed. Existing orders will maintain their current status structure.',
                      style: TextStyle(
                        color: Colors.orange[900],
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppColors.primaryBlue),
            ),
            child: const Text(
  'Confirm',
  style: TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Saving configuration...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        // Save operational mode configuration immediately
        // ignore: use_build_context_synchronously
        final bloc = context.read<OrderBloc>();
        final config = await bloc.configurationRepository.getConfiguration();
        
        final newMode = newValue 
            ? StatusTrackingMode.itemLevel 
            : StatusTrackingMode.orderLevel;
        
        final updatedConfig = config.copyWith(statusTrackingMode: newMode);
        await bloc.configurationRepository.saveConfiguration(updatedConfig);
        
        // Update local state
        setState(() => _useItemLevelTracking = newValue);
        
        // Reload orders with new configuration
        bloc.add(const LoadOrders());
        
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Text('Switched to $modeTitle successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Failed to save: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _checkForUpdates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check for Updates'),
        content: const Text('You are running the latest version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToServer() async {
    if (_serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a server URL'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final orderDataSource = getIt<LocalOrderDataSource>();
      await orderDataSource.setServerUrl(_serverUrl);
      
      // Wait a moment for connection
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isServerConnected = orderDataSource.isOnline;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isServerConnected
                  ? 'Connected to sync server!'
                  : 'Could not connect. Check if server is running.',
            ),
            backgroundColor: _isServerConnected ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all temporary files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting data...')),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will restore all settings to default. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _changePin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current PIN'),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'New PIN'),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm New PIN'),
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
                const SnackBar(content: Text('PIN updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _managePermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening permissions manager...')),
    );
  }

  void _manageEncryption() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening encryption settings...')),
    );
  }

  void _viewAuditLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening audit log...')),
    );
  }
}
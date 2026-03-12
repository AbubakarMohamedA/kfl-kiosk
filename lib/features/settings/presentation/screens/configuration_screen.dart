import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  late Future<AppConfiguration> _configurationFuture;
  StatusTrackingMode? _selectedMode;

  @override
  void initState() {
    super.initState();
    // Fetch config from repository
    _configurationFuture = Future.delayed(Duration.zero, () {
      // ignore: use_build_context_synchronously
      return context.read<OrderBloc>().configurationRepository.getConfiguration();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
           constraints: const BoxConstraints(maxWidth: 900),
           child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FutureBuilder<AppConfiguration>(
                  future: _configurationFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final config = snapshot.data!;
                    _selectedMode ??= config.statusTrackingMode;
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           // Display Current Config Info (Read-Only)
                           Container(
                             padding: const EdgeInsets.all(16),
                             margin: const EdgeInsets.only(bottom: 24),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.grey[200]!),
                             ),
                             child: Column(
                               children: [
                                 _buildInfoRow('Branch ID', config.branchId ?? 'Not Set', Icons.store),
                                 const Divider(),
                                 _buildInfoRow('License Status', 'Active', Icons.verified_user, valueColor: Colors.green),
                               ],
                             ),
                           ),

                          _buildSectionHeader('Status Tracking Configuration'),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Status Tracking Mode',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose how order statuses are tracked in your system:',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  _buildModeOption(
                                    mode: StatusTrackingMode.orderLevel,
                                    title: 'Order-Level Tracking',
                                    description: 'Entire order moves through status stages together. Simple workflow ideal for small operations without warehouse separation.',
                                    icon: Icons.receipt_long,
                                    color: Colors.blue,
                                    isSelected: _selectedMode == StatusTrackingMode.orderLevel,
                                    onTap: () => setState(() => _selectedMode = StatusTrackingMode.orderLevel),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildModeOption(
                                    mode: StatusTrackingMode.itemLevel,
                                    title: 'Item/Warehouse-Level Tracking',
                                    description: 'Track status per product category (Flour, Oil, etc.). Enables parallel processing across warehouse stations. Recommended for larger operations.',
                                    icon: Icons.warehouse,
                                    color: const Color(0xFF0B8843),
                                    isSelected: _selectedMode == StatusTrackingMode.itemLevel,
                                    onTap: () => setState(() => _selectedMode = StatusTrackingMode.itemLevel),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  
                                  _buildWarningMessage(_selectedMode ?? config.statusTrackingMode),
                                  
                                  const SizedBox(height: 24),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _selectedMode != config.statusTrackingMode 
                                          ? () => _saveConfiguration(context)
                                          : null,
                                      icon: const Icon(Icons.save),
                                      label: const Text(
                                        'Save Configuration Changes',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(AppColors.primaryBlue),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          _buildSectionHeader('How It Works'),
                           const SizedBox(height: 16),
                                  _buildModeExplanation(
                                    title: 'Order-Level Tracking',
                                    steps: [
                                      'Customer places order → Status: PAID',
                                      'Staff prepares entire order → Status: PREPARING',
                                      'Order ready for pickup → Status: READY FOR PICKUP',
                                      'Customer collects order → Status: FULFILLED'
                                    ],
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildModeExplanation(
                                    title: 'Item/Warehouse-Level Tracking',
                                    steps: [
                                      'Customer places order → All items: PAID',
                                      'Flour warehouse prepares flour items → Flour items: PREPARING → READY',
                                      'Oil warehouse prepares oil items → Oil items: PREPARING → READY',
                                      'Customer collects all items → All items: FULFILLED',
                                      'System shows order complete when ALL items are fulfilled'
                                    ],
                                    color: const Color(0xFF0B8843),
                                  ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
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
            color: Colors.black.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_suggest, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Configuration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Configure operational settings',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Settings'),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildModeOption({
    required StatusTrackingMode mode,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningMessage(StatusTrackingMode mode) {
    final isChangingToItemLevel = 
        _selectedMode == StatusTrackingMode.itemLevel && 
        mode == StatusTrackingMode.orderLevel;
    
    if (!isChangingToItemLevel) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[800]),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Switching to Item-Level Tracking will enable warehouse stations. You\'ll need to configure warehouse assignments for product categories in the Inventory settings.',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeExplanation({
    required String title,
    required List<String> steps,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info, color: color),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _saveConfiguration(BuildContext context) async {
    if (_selectedMode == null) return;
    
    try {
      final bloc = context.read<OrderBloc>();
      final config = await bloc.configurationRepository.getConfiguration();
      final updatedConfig = config.copyWith(statusTrackingMode: _selectedMode!);
      
      await bloc.configurationRepository.saveConfiguration(updatedConfig);
      
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuration saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        
        bloc.add(const LoadOrders());
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
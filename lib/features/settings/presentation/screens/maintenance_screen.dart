import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';
import 'package:sss/features/auth/presentation/screens/login_screen.dart';

class MaintenanceScreen extends StatelessWidget {
  final VoidCallback? onAdminAccess;
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const MaintenanceScreen({
    super.key, 
    this.onAdminAccess,
    this.title = 'System Under Maintenance',
    this.message = 'We are currently performing scheduled maintenance.\nPlease try again later.',
    this.icon = Icons.construction,
    this.iconColor = const Color(0xFFF57C00), // orange[700]
  });

  Future<void> _handleLogout(BuildContext context) async {
    // Clear configuration
    final repo = context.read<OrderBloc>().configurationRepository;
    await repo.saveConfiguration(AppConfiguration());

    if (context.mounted) {
      context.read<OrderBloc>().add(const ClearOrders());
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a237e),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50], // Light red background
                    foregroundColor: Colors.red, // Red text/icon
                    elevation: 0,
                    side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

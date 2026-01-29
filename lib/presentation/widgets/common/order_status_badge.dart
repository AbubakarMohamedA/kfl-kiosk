import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 12,
        vertical: isLarge ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(isLarge ? 12 : 20),
        border: Border.all(
          color: statusInfo['borderColor'],
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            size: isLarge ? 20 : 16,
            color: statusInfo['textColor'],
          ),
          SizedBox(width: isLarge ? 8 : 6),
          Text(
            status,
            style: TextStyle(
              fontSize: isLarge ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: statusInfo['textColor'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case AppConstants.statusPaid:
        return {
          'color': Colors.blue[50],
          'borderColor': Colors.blue[300],
          'textColor': Colors.blue[900],
          'icon': Icons.payment,
        };
      case AppConstants.statusPreparing:
        return {
          'color': Colors.orange[50],
          'borderColor': Colors.orange[300],
          'textColor': Colors.orange[900],
          'icon': Icons.autorenew,
        };
      case AppConstants.statusReadyForPickup:
        return {
          'color': Colors.purple[50],
          'borderColor': Colors.purple[300],
          'textColor': Colors.purple[900],
          'icon': Icons.inventory_2,
        };
      case AppConstants.statusFulfilled:
        return {
          'color': Colors.green[50],
          'borderColor': Colors.green[300],
          'textColor': Colors.green[900],
          'icon': Icons.check_circle,
        };
      default:
        return {
          'color': Colors.grey[50],
          'borderColor': Colors.grey[300],
          'textColor': Colors.grey[900],
          'icon': Icons.help_outline,
        };
    }
  }
}
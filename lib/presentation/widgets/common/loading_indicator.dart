import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final bool showMessage;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 50.0,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size > 40 ? 4 : 3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(AppColors.primaryBlue),
              ),
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class KFMLoadingOverlay extends StatelessWidget {
  final String? message;

  const KFMLoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingIndicator(
                  size: 60,
                  showMessage: false,
                ),
                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sss/core/config/api_config.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    String finalUrl = imageUrl;
    
    // Resolve local paths from ImageRepository
    if (finalUrl.startsWith('local:')) {
      final filename = finalUrl.substring(6);
      
      // 1. Try direct file access if we are on the host machine
      if (ApiConfig.localImagesDir != null) {
        final localPath = p.join(ApiConfig.localImagesDir!, filename);
        final file = File(localPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            color: color,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
        }
      }

      // 2. Fallback to network URL (for kiosk terminals)
      finalUrl = '${ApiConfig.baseUrl}/api/v1/products/images/$filename';
    }

    final isSvg = finalUrl.toLowerCase().endsWith('.svg');
    final isAsset = finalUrl.startsWith('assets/');

    if (isSvg) {
      if (isAsset) {
        return SvgPicture.asset(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (context) => _buildFallback(),
        );
      } else {
        return SvgPicture.network(
          finalUrl,
          width: width,
          height: height,
          fit: fit,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (context) => _buildFallback(),
        );
      }
    } else {
      if (isAsset) {
        return Image.asset(
          finalUrl,
          width: width,
          height: height,
          fit: fit,
          color: color,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } else {
        return Image.network(
          finalUrl,
          width: width,
          height: height,
          fit: fit,
          color: color,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
    }
  }

  Widget _buildFallback() {
    return SvgPicture.asset(
      'assets/images/fallback.svg',
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}

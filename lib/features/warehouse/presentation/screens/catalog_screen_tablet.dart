import 'package:flutter/material.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/catalog_screen_desktop.dart';

class CatalogScreenTablet extends StatelessWidget {
  final String language;

  const CatalogScreenTablet({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    // For now, use desktop version with larger grid
    return CatalogScreenDesktop(language: language);
  }
}
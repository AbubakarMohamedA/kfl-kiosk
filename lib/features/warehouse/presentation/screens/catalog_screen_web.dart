import 'package:flutter/material.dart';
import 'package:kfm_kiosk/features/warehouse/presentation/screens/catalog_screen_desktop.dart';

class CatalogScreenWeb extends StatelessWidget {
  final String language;

  const CatalogScreenWeb({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return CatalogScreenDesktop(language: language);
  }
}
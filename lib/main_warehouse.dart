import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/config/app_role.dart';
import 'package:kfm_kiosk/main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.mainWithRole(AppRole.warehouse);
}

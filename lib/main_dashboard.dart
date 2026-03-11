import 'package:flutter/material.dart';
import 'package:kfm_kiosk/core/config/app_role.dart';
import 'package:kfm_kiosk/main.dart' as app;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  app.mainWithRole(AppRole.dashboard);
}

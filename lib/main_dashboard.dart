import 'package:flutter/material.dart';
import 'package:sss/core/config/app_role.dart';
import 'package:sss/main.dart' as app;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  app.mainWithRole(AppRole.dashboard);
}

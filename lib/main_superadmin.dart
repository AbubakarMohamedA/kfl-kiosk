import 'package:flutter/material.dart';
import 'package:sss/core/config/app_role.dart';
import 'package:sss/main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.mainWithRole(AppRole.superAdmin);
}

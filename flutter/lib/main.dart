import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'widgets/app_shell.dart';
import 'widgets/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.bootstrap();
  runApp(FoodSafeApp(controller: controller));
}

class FoodSafeApp extends StatelessWidget {
  const FoodSafeApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemma 4 Food-Safe',
      theme: buildAppTheme(),
      home: FoodSafeShell(controller: controller),
    );
  }
}

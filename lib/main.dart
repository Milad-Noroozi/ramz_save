import 'package:flutter/material.dart';
import 'package:ramz_save/views/main_page.dart';
import 'config/app_theme.dart';

void main() {
  runApp(const RamzSaveApp());
}

class RamzSaveApp extends StatelessWidget {
  const RamzSaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ramz Save',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainPage(),
    );
  }
}

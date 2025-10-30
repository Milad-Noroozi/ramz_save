import 'package:flutter/material.dart';
import 'package:ramz_save/views/profile/profile_view.dart';
import 'package:ramz_save/views/settings/settings_view.dart';
import '../views/widgets/bottom_nav_bar.dart';
import '../views/home/home_view.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeView(),
    ProfileView(),
    HomeView(),
    ProfileView(),
    SettingView(),
    ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

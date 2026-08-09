import 'package:flutter/material.dart';

import 'home/home_view.dart';
import 'vault/add_vault_view.dart';
import 'vault/all_vault_view.dart';
import 'vault/password_generator_view.dart';
import 'vault/vault_health_view.dart';
import 'widgets/bottom_nav_bar.dart';

/// The tab shell.
///
/// Index 2 is the raised add button. It pushes a route instead of switching
/// tabs — adding an entry is a task the user finishes and returns from, not a
/// place they stay, and treating it as a tab left the previous screen's state
/// stranded behind it.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  static const _tabs = <int, Widget>{
    0: HomeView(),
    1: AllVaultView(),
    3: PasswordGeneratorView(),
    4: VaultHealthView(),
  };

  /// The order IndexedStack sees. Index 2 has no page, so the map keys are
  /// flattened to a list and the add button is routed around.
  static const _order = [0, 1, 3, 4];

  Future<void> _onNavTap(int index) async {
    if (index == 2) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddVaultView()),
      );
      return;
    }
    if (index != _index) setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack, not a swap: scroll offsets and the search field's text
      // survive a trip to another tab and back.
      body: IndexedStack(
        index: _order.indexOf(_index),
        children: [for (final i in _order) _tabs[i]!],
      ),
      extendBody: true,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _index,
        onTap: _onNavTap,
      ),
    );
  }
}

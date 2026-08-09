import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';

/// Destinations in the bottom bar, in visual order.
///
/// Index 2 is the raised add button, which is why the two halves of the row are
/// built separately rather than from one uniform list.
enum NavTab { home, vaults, add, generator, health }

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<double> _slide;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
      value: 1,
    );
    _slide = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  static const _icons = <int, (IconData, IconData, String)>{
    0: (Icons.home_outlined, Icons.home_rounded, AppStrings.appName),
    1: (Icons.lock_outline, Icons.lock_rounded, AppStrings.allVaults),
    3: (Icons.autorenew_outlined, Icons.autorenew_rounded,
        AppStrings.generatorTitle),
    4: (Icons.shield_outlined, Icons.shield_rounded, AppStrings.vaultsHealth),
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.darkBgSeccondry,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 5;
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildIndicator(itemWidth),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        SizedBox(
                          width: itemWidth,
                          child: i == 2
                              ? _buildAddButton()
                              : _buildNavItem(i),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(double itemWidth) {
    if (widget.currentIndex == 2 || _previousIndex == 2) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) {
        final start = _previousIndex * itemWidth;
        final end = widget.currentIndex * itemWidth;
        final position = start + (end - start) * _slide.value;

        // `start`, not `left`: in RTL the first tab sits on the right, and a
        // physical-left offset would slide the pill to the wrong tab.
        return PositionedDirectional(
          start: position + itemWidth / 2 - 24,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index) {
    final (icon, activeIcon, label) = _icons[index]!;
    final isSelected = widget.currentIndex == index;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkResponse(
        onTap: () => widget.onTap(index),
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey(isSelected),
              color: isSelected ? AppColors.green : AppColors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final isSelected = widget.currentIndex == 2;

    return Semantics(
      label: AppStrings.addVaultTitle,
      button: true,
      child: GestureDetector(
        onTap: () => widget.onTap(2),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutBack,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: AppColors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

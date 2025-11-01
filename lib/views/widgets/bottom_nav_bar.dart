import 'package:flutter/material.dart';
import 'package:ramz_save/config/app_colors.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkBgSeccondry,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_outlined, Icons.home, 0),
                      _buildNavItem(Icons.lock_outline, Icons.lock, 1),
                      _buildAddButton(),
                      _buildNavItem(Icons.edit_outlined, Icons.edit, 3),
                      _buildNavItem(Icons.shield_outlined, Icons.shield, 4),
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
    if (widget.currentIndex == 2 || _previousIndex == 2) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        final startPos = _previousIndex * itemWidth;
        final endPos = widget.currentIndex * itemWidth;
        final currentPos = startPos + (endPos - startPos) * _slideAnimation.value;

        return Positioned(
          left: currentPos + itemWidth / 2 - 24,
          top: 6,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            isSelected ? activeIcon : icon,
            key: ValueKey<bool>(isSelected),
            color: isSelected ? AppColors.green : AppColors.textSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final isSelected = widget.currentIndex == 2;

    return GestureDetector(
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
                color: AppColors.green.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

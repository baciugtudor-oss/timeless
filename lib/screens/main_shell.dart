import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xl,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23252A) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.calculate_rounded,
              label: 'Calculator',
              isSelected: navigationShell.currentIndex == 0,
              onTap: () => _onTap(0),
            ),
            _NavBarItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: navigationShell.currentIndex == 1,
              onTap: () => _onTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

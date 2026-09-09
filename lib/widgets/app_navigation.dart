import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

// V2 Floating Pill — adapted with center FAB elevated above bar
// Tab count: 4 visible (Home, Search, [FAB center], Profile) + stub Notifications
// Branch count: 3 (Home, Search, Profile)

class _TabSpec {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? branchIndex; // null = stub

  const _TabSpec({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.branchIndex,
  });
}

const List<_TabSpec> _tabs = [
  _TabSpec(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
    branchIndex: 0,
  ),
  _TabSpec(
    icon: Icons.search_rounded,
    selectedIcon: Icons.search_rounded,
    label: 'Search',
    branchIndex: 1,
  ),
  _TabSpec(
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    label: 'Alerts',
    branchIndex: null, // stub
  ),
  _TabSpec(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Profile',
    branchIndex: 2,
  ),
];

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  void _onTabTapped(int visualIndex) {
    final spec = _tabs[visualIndex];
    if (spec.branchIndex == null) return; // stub — silent ignore
    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      spec.branchIndex!,
      initialLocation: spec.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync visual index with actual shell index
    final currentBranch = widget.navigationShell.currentIndex;
    final matching = _tabs.indexWhere((t) => t.branchIndex == currentBranch);
    if (matching != -1 && matching != _selectedVisualIndex) {
      _selectedVisualIndex = matching;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.gold.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tab row — split around center FAB slot
            Row(
              children: [
                // Left 2 tabs
                Expanded(child: Row(children: [_buildTab(0), _buildTab(1)])),
                // Center FAB slot
                const SizedBox(width: 72),
                // Right 2 tabs
                Expanded(child: Row(children: [_buildTab(2), _buildTab(3)])),
              ],
            ),
            // Center FAB
            _buildCenterFab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int visualIndex) {
    final spec = _tabs[visualIndex];
    final isActive = _selectedVisualIndex == visualIndex;
    final isStub = spec.branchIndex == null;
    final opacity = isStub ? 0.4 : 1.0;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(visualIndex),
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? spec.selectedIcon : spec.icon,
                  size: 22,
                  color: isActive ? AppTheme.gold : AppTheme.textMuted,
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? AppTheme.gold : AppTheme.textMuted,
                  ),
                  child: Text(spec.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.askAQuestionScreen),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.goldLight, AppTheme.gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withAlpha(102),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Color(0xFF0A0A0A),
          size: 26,
        ),
      ),
    );
  }
}

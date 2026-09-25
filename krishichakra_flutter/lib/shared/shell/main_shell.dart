import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Adaptive shell: bottom nav on mobile, nav rail on wide screens.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n?.home ?? 'Home',
      l10n?.markets ?? 'Markets',
      l10n?.myLots ?? 'My Lots',
      l10n?.profile ?? 'Profile',
    ];

    const icons = [
      _NavIcons(Icons.home_outlined, Icons.home),
      _NavIcons(Icons.storefront_outlined, Icons.storefront, badge: 'LIVE'),
      _NavIcons(Icons.inventory_2_outlined, Icons.inventory_2),
      _NavIcons(Icons.person_outlined, Icons.person),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                backgroundColor: AppColors.surfaceContainerLowest,
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _onTap,
                labelType: NavigationRailLabelType.all,
                indicatorColor: AppColors.secondaryContainer,
                destinations: List.generate(icons.length, (i) {
                  return NavigationRailDestination(
                    icon: Icon(icons[i].icon),
                    selectedIcon: Icon(icons[i].selectedIcon),
                    label: Text(labels[i]),
                  );
                }),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: shell),
            ],
          ),
        );
      }

      return Scaffold(
        body: shell,
        bottomNavigationBar: _KrishiBottomNav(
          currentIndex: shell.currentIndex,
          onTap: _onTap,
          labels: labels,
          icons: icons,
        ),
      );
    });
  }
}

class _KrishiBottomNav extends StatelessWidget {
  const _KrishiBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    required this.icons,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;
  final List<_NavIcons> icons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainer, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(icons.length, (index) {
              final d = icons[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? d.selectedIcon : d.icon,
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                          if (d.badge != null)
                            Positioned(
                              top: -4,
                              right: -12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  d.badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavIcons {
  const _NavIcons(this.icon, this.selectedIcon, {this.badge});
  final IconData icon;
  final IconData selectedIcon;
  final String? badge;
}

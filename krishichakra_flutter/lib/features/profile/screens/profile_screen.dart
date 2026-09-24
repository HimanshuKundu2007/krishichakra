import 'package:flutter/material.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: AppSpacing.headerHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: KcAppBar(
              title: 'My Profile',
              subtitle: 'Farmer Account',
            ),
            toolbarHeight: AppSpacing.headerHeight,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Avatar + name card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'RS',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Rajesh Sharma',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.verified,
                                    size: 16,
                                    color: AppColors.secondaryFixed),
                              ],
                            ),
                            Text(
                              '+91 98765 43210',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryFixedDim),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.secondaryContainer,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'VERIFIED FARMER',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Stats row
                Row(
                  children: [
                    Expanded(
                        child: _StatTile('Land', '3.5 Acres',
                            Icons.landscape)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                        child: _StatTile('District', 'Pune',
                            Icons.location_city)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                        child: _StatTile(
                            'State', 'Maharashtra', Icons.map)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Profile fields
                _SectionLabel('Account Details'),
                _ProfileRow(Icons.phone, 'Phone Number',
                    '+91 98765 43210', true),
                _ProfileRow(Icons.location_on, 'Village',
                    'Junnar, Pune, Maharashtra', false),
                _ProfileRow(Icons.account_balance, 'Bank Account',
                    'SBI ••••4892 (Linked)', true),
                _ProfileRow(Icons.badge, 'Aadhaar KYC',
                    'Verified ✓', true),
                _ProfileRow(Icons.language, 'Language Preference',
                    'Hindi (हिन्दी)', false),
                const SizedBox(height: AppSpacing.md),
                _SectionLabel('FPO Membership'),
                _ProfileRow(Icons.group, 'FPO Name',
                    'Junnar Shetkari FPO', true),
                _ProfileRow(Icons.numbers, 'Member ID',
                    'JNR-FPO-2024-0034', false),
                const SizedBox(height: AppSpacing.md),
                // Actions
                _SectionLabel('Account Actions'),
                _ActionTile(
                  icon: Icons.notifications_outlined,
                  label: 'Price Alert Settings',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.download,
                  label: 'Download Transaction Report',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.support_agent,
                  label: 'Contact Kisan Advisor',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () {},
                  isDestructive: true,
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 3),
          Text(value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.icon, this.label, this.value, this.verified);
  final IconData icon;
  final String label;
  final String value;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
              ],
            ),
          ),
          if (verified)
            Icon(Icons.verified, size: 16, color: AppColors.secondary),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.errorContainer.withOpacity(0.3)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : AppColors.onSurface)),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

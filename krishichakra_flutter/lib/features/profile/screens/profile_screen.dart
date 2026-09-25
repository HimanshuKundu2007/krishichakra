import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Profile Screen — fully localized (EN / MR / HI)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLangLabel = ref.read(languageProvider.notifier).currentLanguageLabel;
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
              title: l10n?.myProfile ?? 'My Profile',
              subtitle: l10n?.farmerAccount ?? 'Farmer Account',
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: LanguageSelectorButton(),
                ),
              ],
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
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n?.verifiedFarmer ?? 'VERIFIED FARMER',
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
                        child: _StatTile(l10n?.landHolding ?? 'Land',
                            '3.5 Acres', Icons.landscape)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                        child: _StatTile(l10n?.district ?? 'District', 'Pune',
                            Icons.location_city)),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                        child: _StatTile(
                            l10n?.state ?? 'State',
                            'Maharashtra',
                            Icons.map)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Profile fields
                _SectionLabel(l10n?.accountDetails ?? 'Account Details'),
                _ProfileRow(Icons.phone, l10n?.language != null ? 'Phone Number' : 'Phone Number',
                    '+91 98765 43210', true),
                _ProfileRow(Icons.location_on, l10n?.location ?? 'Village',
                    'Junnar, Pune, Maharashtra', false),
                _ProfileRow(Icons.account_balance, 'Bank Account',
                    'SBI ••••4892 (Linked)', true),
                _ProfileRow(Icons.badge, 'Aadhaar KYC', 'Verified ✓', true),
                _ProfileRow(
                  Icons.language,
                  l10n?.languagePreference ?? 'Language Preference',
                  currentLangLabel,
                  false,
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
                  onTap: () => _showLanguageModal(context, ref),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionLabel(l10n?.fpoMembership ?? 'FPO Membership'),
                _ProfileRow(Icons.group, 'FPO Name', 'Junnar Shetkari FPO', true),
                _ProfileRow(Icons.numbers, 'Member ID', 'JNR-FPO-2024-0034', false),
                const SizedBox(height: AppSpacing.md),
                // Actions
                _SectionLabel(l10n?.accountActions ?? 'Account Actions'),
                _ActionTile(
                  icon: Icons.notifications_outlined,
                  label: l10n?.priceAlertSettings ?? 'Price Alert Settings',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.download,
                  label: l10n?.downloadTransactionReport ??
                      'Download Transaction Report',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.support_agent,
                  label: l10n?.contactKisanAdvisor ?? 'Contact Kisan Advisor',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.logout,
                  label: l10n?.logout ?? 'Logout',
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

  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.read(languageProvider);
    final notifier = ref.read(languageProvider.notifier);

    final languages = [
      (const Locale('en'), '🌐', 'English', 'English'),
      (const Locale('hi'), '🌐', 'हिन्दी', 'Hindi'),
      (const Locale('mr'), '🌐', 'मराठी', 'Marathi'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.selectLanguage ?? 'Select Language',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...languages.map((lang) {
                final isSelected = lang.$1.languageCode == currentLocale.languageCode;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isSelected ? AppColors.secondaryContainer.withOpacity(0.4) : Colors.transparent,
                  leading: Text(lang.$2, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    lang.$3,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    lang.$4,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    notifier.setLocale(lang.$1);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
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
              style:
                  TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
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
  const _ProfileRow(
    this.icon,
    this.label,
    this.value,
    this.verified, {
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final rowContent = Container(
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
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: rowContent,
      );
    }
    return rowContent;
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
                      color:
                          isDestructive ? color : AppColors.onSurface)),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

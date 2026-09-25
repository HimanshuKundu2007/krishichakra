import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/repositories/mandi_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_widgets.dart';
import '../../../shared/widgets/krishichakra_logo.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../core/providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Screen 2 — Farmer Home Dashboard
/// Recreates the Stitch farmer home dashboard exactly:
///   - "5G MandiLink" live header
///   - Farmer greeting card with location
///   - Voice search bar ("Bolie")
///   - Active trade strip (amber)
///   - Live mandi pulse (horizontal scroll connected to backend)
///   - 4 action cards
class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Sticky Header ────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            expandedHeight: AppSpacing.headerHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: _DashboardHeader(),
            toolbarHeight: AppSpacing.headerHeight,
            surfaceTintColor: Colors.transparent,
          ),

          // ── Body content ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.sm),
                // ── Global Language Selector Strip (1-tap switch) ─────────
                const _HomeLanguageBar(),
                const SizedBox(height: AppSpacing.sm),
                // ── Farmer greeting card ──────────────────────────────────
                _FarmerGreetingCard(),
                const SizedBox(height: AppSpacing.md),
                // ── Voice search bar ──────────────────────────────────────
                Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return VoiceSearchBar(
                    hint: l10n?.tapToSpeak ??
                        "Tap to speak: 'Sell 20Q Onion' or 'Check Vashi Bhav'",
                    isListening: _isListening,
                    onMicTap: () =>
                        setState(() => _isListening = !_isListening),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                // ── Active trade strip ────────────────────────────────────
                _ActiveTradeStrip(),
                const SizedBox(height: AppSpacing.md),
                // ── Live mandi pulse section ──────────────────────────────
                Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return _SectionHeader(
                    title: l10n?.liveMandiPulse ?? 'Live Mandi Pulse',
                    actionLabel: l10n?.viewAll ?? 'View All',
                    onAction: () => ctx.go(AppRoutes.markets),
                  );
                }),
                const SizedBox(height: AppSpacing.xs),
                const _MandiPulseRow(),
                const SizedBox(height: AppSpacing.md),
                // ── Action cards ──────────────────────────────────────────
                Builder(builder: (ctx) {
                  final l10n = AppLocalizations.of(ctx);
                  return _SectionHeader(title: l10n?.whatWouldYouLikeToDo ?? 'What would you like to do?');
                }),
                const SizedBox(height: AppSpacing.xs),
                _ActionCards(),
                const SizedBox(height: AppSpacing.md),
                // ── Gov trust strip ───────────────────────────────────────
                _TrustStrip(),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          child: Row(
            children: [
              // Actual KrishiChakra logo
              const KrishiChakraLogo(size: 36),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KrishiChakra',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                   Row(
                    children: [
                      LivePulsingDot(color: AppColors.secondary, size: 6),
                      const SizedBox(width: 4),
                      Builder(builder: (ctx) {
                        final l10n = AppLocalizations.of(ctx);
                        return Text(
                          l10n?.mandiLinkSubtitle ?? '5G MandiLink',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Language selector
              const LanguageSelectorButton(),
              const SizedBox(width: AppSpacing.xs),
              // Toll-free
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.support_agent,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      const Text(
                        '1800-180-1551',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Notification bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.notifications_outlined,
                        color: AppColors.onSurfaceVariant, size: 22),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'RS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Global Language Selector Strip ──────────────────────────────────────────

class _HomeLanguageBar extends ConsumerWidget {
  const _HomeLanguageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final notifier = ref.read(languageProvider.notifier);

    final languages = [
      (const Locale('en'), 'English'),
      (const Locale('mr'), 'मराठी'),
      (const Locale('hi'), 'हिंदी'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🌐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            'Language / भाषा:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: languages.map((lang) {
                final isSelected = lang.$1.languageCode == currentLocale.languageCode;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () => notifier.setLocale(lang.$1),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        lang.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Farmer Greeting Card ──────────────────────────────────────────────────────

class _FarmerGreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Rajesh Sharma',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified,
                              size: 10, color: AppColors.secondary),
                          const SizedBox(width: 2),
                          Text(
                            'VERIFIED FARMER',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      'Junnar, Pune',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Builder(builder: (ctx) {
                      final l10n = AppLocalizations.of(ctx);
                      return Text(
                        l10n?.change ?? '[Change]',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // Audio button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.volume_up,
                size: 18, color: AppColors.primaryContainer),
          ),
        ],
      ),
    );
  }
}

// ── Active Trade Strip ────────────────────────────────────────────────────────

class _ActiveTradeStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tertiaryFixedDim.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          LivePulsingDot(
              color: AppColors.tertiaryContainer, size: 10),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lot #ON-9021 • 20Q Onion',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Builder(builder: (ctx) {
                  return const Text(
                    '2 Offers Waiting • Top Bid ₹2,600/Q',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  );
                }),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Builder(builder: (ctx) {
                final l10n = AppLocalizations.of(ctx);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SmallActionButton(
                      label: l10n?.reviewOffers ?? 'Review Offers',
                      onTap: () {},
                    ),
                    const SizedBox(height: 4),
                    _SmallActionButton(
                      label: l10n?.trackTransit ?? 'Track Transit',
                      onTap: () {},
                      isSecondary: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton(
      {required this.label, required this.onTap, this.isSecondary = false});
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSecondary
              ? AppColors.surfaceContainerLow
              : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSecondary ? AppColors.primary : AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              actionLabel!,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

// ── Mandi Pulse Row ───────────────────────────────────────────────────────────

class _MandiPulseItem {
  const _MandiPulseItem({
    required this.name,
    required this.commodity,
    this.normalizedName,
    required this.market,
    required this.price,
    this.change,
    required this.advisory,
    required this.isUp,
    required this.source,
    this.arrivalDate,
  });

  final String name;
  final String commodity;
  final String? normalizedName;
  final String market;
  final double price;
  final double? change;
  final String advisory;
  final bool isUp;
  final String source;
  final String? arrivalDate;
}

class _MandiPulseRow extends ConsumerWidget {
  const _MandiPulseRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(mandiStatusProvider);
    final pulseAsync = ref.watch(mandiPulseProvider('Maharashtra'));

    final status = statusAsync.asData?.value;
    final isLive = status?.isLive ?? false;
    final isFailed = status?.hasFailedSync ?? false;
    final lastUpdated = status?.lastSuccessfulSync ?? status?.lastSync;

    return pulseAsync.when(
      loading: () => SizedBox(
        height: 146,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (_, __) => Container(
            width: 212,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Builder(builder: (ctx) {
              final l10n = AppLocalizations.of(ctx);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.loadingGovData ?? 'Loading government market data...',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      error: (err, _) => Container(
        height: 100,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Builder(builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);
          return Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.govSourceUnavailable ?? 'Government source temporarily unavailable.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(mandiStatusProvider);
                  ref.invalidate(mandiPulseProvider);
                },
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          );
        }),
      ),
      data: (prices) {
        if (prices.isEmpty) {
          return Container(
            height: 100,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: Builder(builder: (ctx) {
                final l10n = AppLocalizations.of(ctx);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.noMarketDataAvailable ?? 'No market data available for this commodity.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }),
            ),
          );
        }

        final validPrices = prices.where((m) => m.modalPrice > 0).toList();
        if (validPrices.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                l10n?.noMarketDataAvailable ?? 'No market data available.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final items = validPrices.map((m) {
          final normName = m.normalizedName ?? m.commodity;
          final pct = m.priceChangePct;
          return _MandiPulseItem(
            name: normName,
            commodity: normName,
            normalizedName: m.normalizedName,
            market: m.market,
            price: m.modalPrice,
            change: pct,
            advisory: m.market,
            isUp: (pct ?? 0.0) >= 0,
            source: m.source,
            arrivalDate: m.arrivalDate,
          );
        }).toList();

        return SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (ctx, i) => _MandiPulseCard(
              item: items[i],
              isLive: isLive,
              isLastAvailable: isFailed,
              lastUpdated: lastUpdated,
            ),
          ),
        );
      },
    );
  }
}

class _MandiPulseCard extends StatelessWidget {
  const _MandiPulseCard({
    required this.item,
    required this.isLive,
    required this.isLastAvailable,
    this.lastUpdated,
  });

  final _MandiPulseItem item;
  final bool isLive;
  final bool isLastAvailable;
  final String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(
          '${AppRoutes.markets}?commodity=${Uri.encodeComponent(item.commodity)}',
        );
      },
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CommodityIcon(
                  commodity: item.commodity,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          formatInr(item.price),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '/Q',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                PriceChangeBadge(changePercent: item.change),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                item.advisory,
                style: TextStyle(
                  fontSize: 11,
                  color: item.change == null
                      ? AppColors.onSurfaceVariant
                      : (item.isUp ? AppColors.secondary : AppColors.tertiary),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            DataSourceTag(
              source: item.source,
              isLive: isLive,
              isLastAvailable: isLastAvailable,
              lastUpdated: lastUpdated,
              arrivalDate: item.arrivalDate,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Cards ──────────────────────────────────────────────────────────────

class _ActionCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _ActionCard(
          icon: Icons.inventory_2_outlined,
          title: l10n?.sellProduceGetBuyerBids ?? 'Sell Produce & Get Buyer Bids',
          subtitle: l10n?.createHarvestLot ?? 'Create Harvest Lot',
          tag: l10n?.recommended ?? 'RECOMMENDED',
          tagColor: AppColors.secondary,
          onTap: () => context.push(AppRoutes.produceListing),
          isRecommended: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        _ActionCard(
          icon: Icons.calculate_outlined,
          title: l10n?.netProfitMandiCalculator ?? 'Net Profit & Mandi Calculator',
          subtitle: l10n?.findHighestPayingMandi ?? 'Find Highest Paying Mandi',
          onTap: () => context.push(AppRoutes.netRealization),
        ),
        const SizedBox(height: AppSpacing.xs),
        _ActionCard(
          icon: Icons.warehouse_outlined,
          title: l10n?.coldStorageInstantLoan ?? 'Cold Storage & 70% Instant Cash Loan',
          subtitle: l10n?.coldStorageSubtitle ?? 'e-NWR • MSWC • Book Storage & Apply for Loan',
          onTap: () => context.push(AppRoutes.storageBooking),
        ),
        const SizedBox(height: AppSpacing.xs),
        _ActionCard(
          icon: Icons.local_shipping_outlined,
          title: l10n?.discountedTransport ?? 'Discounted Return-Truck Transport',
          subtitle: l10n?.discountedTransportSubtitle ?? '35% freight discount • Book Logistics',
          onTap: () => context.push(AppRoutes.logisticsBooking),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
    this.tagColor,
    this.isRecommended = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? tag;
  final Color? tagColor;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: isRecommended
              ? AppColors.primaryContainer.withOpacity(0.08)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: isRecommended
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isRecommended
                    ? AppColors.primaryContainer.withOpacity(0.2)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 22,
                  color: isRecommended ? AppColors.primary : AppColors.secondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor ?? AppColors.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Trust Strip ───────────────────────────────────────────────────────────────

class _TrustStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 14, color: AppColors.secondary),
          const SizedBox(width: 4),
          Flexible(
            child: Builder(builder: (ctx) {
              final l10n = AppLocalizations.of(ctx);
              return Text(
                l10n?.govAgriStackReady ?? 'Government Agri Stack Ready • e-NAM & MSWC Integrated',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

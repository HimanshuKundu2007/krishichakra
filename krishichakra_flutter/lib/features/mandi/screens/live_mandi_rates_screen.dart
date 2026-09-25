import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/mandi_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/kc_widgets.dart';
import '../../../l10n/app_localizations.dart';

/// Screen 3 — Live Mandi Rates
/// Reproduces Stitch screen with:
///   - Search bar + voice
///   - Commodity ribbon (horizontal scroll)
///   - Radius filter buttons
///   - SVG-style map area with price pins
///   - Audio rate summary bar
///   - Mandi cards with min/modal/max + CTA
///   - Government Mandi trade feed
/// Strictly displays verified Government Market Data (AGMARKNET / data.gov.in)
/// without fake or dummy prices in the live flow.
class LiveMandiRatesScreen extends ConsumerStatefulWidget {
  const LiveMandiRatesScreen({super.key, this.initialCommodity});

  final String? initialCommodity;

  @override
  ConsumerState<LiveMandiRatesScreen> createState() =>
      _LiveMandiRatesScreenState();
}

class _LiveMandiRatesScreenState extends ConsumerState<LiveMandiRatesScreen> {
  late String _selectedCommodity;
  int _radiusIdx = 1; // 0=50km, 1=150km, 2=All MH
  bool _isListening = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchFilter = '';

  String? _selectedState = 'Maharashtra';
  String? _selectedDistrict;
  String? _selectedMarket;
  String? _selectedVariety;
  bool _isAllIndia = false;

  List<String> _radiusLabels(AppLocalizations l10n) => [
    l10n.within50km,
    l10n.within150km,
    l10n.allMaharashtraLabel,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCommodity = (widget.initialCommodity != null && widget.initialCommodity!.isNotEmpty)
        ? widget.initialCommodity!
        : 'onion';
  }

  @override
  void didUpdateWidget(covariant LiveMandiRatesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCommodity != null &&
        widget.initialCommodity!.isNotEmpty &&
        widget.initialCommodity != oldWidget.initialCommodity) {
      setState(() {
        _selectedCommodity = widget.initialCommodity!;
        _searchFilter = '';
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _FilterOptionSheet(
        title: title,
        options: options,
        selectedValue: selectedValue,
        onSelected: (val) {
          Navigator.of(ctx).pop();
          onSelected(val);
        },
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(mandiStatusProvider);
    ref.invalidate(filteredMandiPricesProvider);
    ref.invalidate(latestMandiPricesProvider);
    ref.invalidate(availableMandiFiltersProvider);
    ref.invalidate(dynamicMandiFiltersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(mandiStatusProvider);

    final commodityToQuery = _searchFilter.isNotEmpty
        ? _searchFilter
        : (_selectedCommodity == 'all' ? null : _selectedCommodity);

    final cascadeQuery = (
      state: _selectedState,
      district: _selectedDistrict,
      market: _selectedMarket,
      commodity: commodityToQuery,
    );
    final filtersAsync = ref.watch(dynamicMandiFiltersProvider(cascadeQuery));
    final filterData = filtersAsync.asData?.value ?? MandiFiltersData.empty;

    final filterQuery = (
      commodity: commodityToQuery,
      state: _selectedState,
      district: _selectedDistrict,
      market: _selectedMarket,
      variety: _selectedVariety,
      limit: 100,
    );

    final pricesAsync = ref.watch(filteredMandiPricesProvider(filterQuery));

    final status = statusAsync.asData?.value;
    final isLive = status?.isLive ?? false;
    final isFailed = status?.hasFailedSync ?? false;
    final isStale = status?.isStale ?? false;
    final hasEverSynced =
        status?.hasEverSynced ?? (status?.hasGovernmentRecords ?? false);
    final sourceName =
        status?.source ?? 'Government Market Data (AGMARKNET / data.gov.in)';
    final lastUpdated = status?.lastSync;
    final lastSuccessfulSync = status?.lastSuccessfulSync;
    final latestDataDate = status?.latestDataDate;

    final availableStates = filterData.states;
    final availableDistricts = filterData.districts;
    final availableMarkets = filterData.markets;
    final availableVarieties = filterData.varieties;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header — strictly showLiveIndicator only if status.isLive == true
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: true,
              snap: true,
              expandedHeight: AppSpacing.headerHeight,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: l10n.liveMandiRates,
                subtitle: l10n.officialAgmarknetRates,
                showLiveIndicator: isLive,
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh,
                        color: AppColors.onSurfaceVariant),
                    tooltip: l10n.refreshGovRates,
                    onPressed: _refreshAll,
                  ),
                ],
              ),
              toolbarHeight: AppSpacing.headerHeight,
              surfaceTintColor: Colors.transparent,
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.md),

                  // Search bar with voice
                  VoiceSearchBar(
                    hint: l10n.searchCropHint,
                    isListening: _isListening,
                    onMicTap: () => setState(() => _isListening = !_isListening),
                    onSubmitted: (query) {
                      setState(() {
                        _searchFilter = query.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Clear provenance banner
                  Row(
                    children: [
                      Expanded(
                        child: DataSourceTag(
                          source: sourceName,
                          lastUpdated: lastUpdated,
                          lastSuccessfulSync: lastSuccessfulSync,
                          latestDataDate: latestDataDate,
                          isLive: isLive,
                          isLastAvailable: isFailed || isStale,
                          isStale: isStale || isFailed,
                          hasEverSynced: hasEverSynced,
                          compact: false,
                        ),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified,
                                  size: 12, color: AppColors.secondary),
                              const SizedBox(width: 3),
                              Text(
                                l10n.eNamVerified,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // â”€â”€ Maharashtra Focus vs All India Toggle Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _StateScopeToggle(
                    isAllIndia: _isAllIndia,
                    selectedState: _selectedState,
                    totalRecords: filterData.totalRecords,
                    onSelectMaharashtra: () => setState(() {
                      _isAllIndia = false;
                      _selectedState = 'Maharashtra';
                      _selectedDistrict = null;
                      _selectedMarket = null;
                      _selectedVariety = null;
                    }),
                    onSelectAllIndia: () => setState(() {
                      _isAllIndia = true;
                      _selectedState = null;
                      _selectedDistrict = null;
                      _selectedMarket = null;
                      _selectedVariety = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // â”€â”€ Dynamic Commodity ribbon from unified backend catalogue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Builder(
                    builder: (context) {
                      final availableCrops = filterData.availableCommodities;
                      final List<(String, String, String)> dynamicCommodities = [
                        ('all', '🧺', 'All Crops'),
                      ];

                      if (availableCrops.isNotEmpty) {
                        for (final crop in availableCrops) {
                          final icon = filterData.commodityIcons[crop] ?? CommodityIcon.getEmoji(crop);
                          dynamicCommodities.add((crop, icon, crop));
                        }
                      } else {
                        const baseline = [
                          ('Wheat', '🌾', 'Wheat'),
                          ('Paddy', '🌾', 'Paddy'),
                          ('Sponge Gourd', '🥒', 'Sponge Gourd'),
                          ('Garlic', '🧄', 'Garlic'),
                          ('Chilli', '🌶️', 'Chilli'),
                          ('Onion', '🧅', 'Onion'),
                          ('Tomato', '🍅', 'Tomato'),
                          ('Potato', '🥔', 'Potato'),
                          ('Soybean', '🌱', 'Soybean'),
                          ('Banana', '🍌', 'Banana'),
                          ('Guava', '🍈', 'Guava'),
                          ('Cotton', '☁️', 'Cotton'),
                          ('Maize', '🌽', 'Maize'),
                          ('Pomegranate', '🍎', 'Pomegranate'),
                        ];
                        dynamicCommodities.addAll(baseline);
                      }

                      if (_selectedCommodity != 'all' &&
                          !dynamicCommodities.any((c) => c.$1.toLowerCase() == _selectedCommodity.toLowerCase())) {
                        dynamicCommodities.add((
                          _selectedCommodity,
                          CommodityIcon.getEmoji(_selectedCommodity),
                          _selectedCommodity,
                        ));
                      }

                      return _CommodityRibbon(
                        commodities: dynamicCommodities,
                        selected: _selectedCommodity,
                        onChanged: (c) => setState(() {
                          _selectedCommodity = c;
                          _selectedVariety = null;
                          _searchFilter = '';
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Hierarchical Location & Variety Filters Row (State -> District -> Market -> Commodity -> Variety)
                  _LocationFilterRow(
                    selectedState: _selectedState,
                    selectedDistrict: _selectedDistrict,
                    selectedMarket: _selectedMarket,
                    selectedVariety: _selectedVariety,
                    isAllIndia: _isAllIndia,
                    availableVarietiesCount: availableVarieties.length,
                    onTapState: () => _showFilterSheet(
                      title: 'Select State (AGMARKNET)',
                      options: availableStates,
                      selectedValue: _selectedState,
                      onSelected: (val) => setState(() {
                        _selectedState = val;
                        _isAllIndia = (val == null || val.toLowerCase() != 'maharashtra');
                        _selectedDistrict = null;
                        _selectedMarket = null;
                        _selectedVariety = null;
                      }),
                    ),
                    onTapDistrict: () => _showFilterSheet(
                      title: 'Select District (${_selectedState ?? "All India"})',
                      options: availableDistricts,
                      selectedValue: _selectedDistrict,
                      onSelected: (val) => setState(() {
                        _selectedDistrict = val;
                        _selectedMarket = null;
                        _selectedVariety = null;
                      }),
                    ),
                    onTapMarket: () => _showFilterSheet(
                      title: 'Select APMC Market (${_selectedDistrict ?? "All Districts"})',
                      options: availableMarkets,
                      selectedValue: _selectedMarket,
                      onSelected: (val) => setState(() {
                        _selectedMarket = val;
                        _selectedVariety = null;
                      }),
                    ),
                    onTapVariety: () => _showFilterSheet(
                      title: 'Select Variety (${commodityToQuery ?? "Crop"})',
                      options: availableVarieties,
                      selectedValue: _selectedVariety,
                      onSelected: (val) => setState(() => _selectedVariety = val),
                    ),
                    onClearAll: () => setState(() {
                      _selectedState = 'Maharashtra';
                      _isAllIndia = false;
                      _selectedDistrict = null;
                      _selectedMarket = null;
                      _selectedVariety = null;
                      _selectedCommodity = 'Onion';
                      _searchFilter = '';
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Radius filter
                  _RadiusFilter(
                    labels: _isAllIndia
                        ? [l10n.within50km, l10n.within150km, l10n.allIndiaLabel]
                        : _radiusLabels(l10n),
                    selectedIdx: _radiusIdx,
                    onChanged: (i) => setState(() => _radiusIdx = i),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Map area with real market pins
                  _MandiMapArea(
                    prices: pricesAsync.asData?.value ?? [],
                    isLive: isLive,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Audio rate summary bar
                  _AudioSummaryBar(
                    prices: pricesAsync.asData?.value ?? [],
                    selectedCommodity: _selectedCommodity,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mandi cards list with loading, error, and empty states
                  pricesAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: KcLoadingIndicator(
                          message: l10n.loadingGovData,
                        ),
                      ),
                    ),
                    error: (err, _) {
                      if (err is ApiException && err.isBackendUnavailable) {
                        return KcBackendUnavailableState(onRetry: _refreshAll);
                      }
                      return KcErrorState(
                        message: l10n.govSourceUnavailable,
                        onRetry: _refreshAll,
                      );
                    },
                    data: (prices) {
                      if (prices.isEmpty) {
                        if (!hasEverSynced) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            margin: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.cloud_off_outlined,
                                  size: 44,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.noGovDataAvailable,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.noGovDataSubtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.sync, size: 16),
                                  label: Text(l10n.synchronizeWithAgmarknet),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                  ),
                                  onPressed: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.triggeringGovSync),
                                      ),
                                    );
                                    try {
                                      await ref
                                          .read(mandiRepositoryProvider)
                                          .triggerSync();
                                    } catch (_) {}
                                    _refreshAll();
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          margin: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 44,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.noMarketDataForCommodity,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isFailed || isStale
                                      ? '${l10n.showingLastAvailableData}: No matching arrivals found for this filter.'
                                    : 'No dummy prices are shown. Official Agmarknet synchronization can be initiated below.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ElevatedButton.icon(
                                icon: Icon(Icons.sync, size: 16),
                                label: Text(l10n.synchronizeWithAgmarknet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                ),
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.triggeringGovSync),
                                    ),
                                  );
                                  try {
                                    await ref
                                        .read(mandiRepositoryProvider)
                                        .triggerSync();
                                  } catch (_) {}
                                  _refreshAll();
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFailed || isStale) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.tertiary.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.history_toggle_off,
                                      color: AppColors.tertiary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          Text(
                                            '${l10n.showingLastAvailableData}' + (latestDataDate != null ? ' from $latestDataDate' : ''),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.tertiary,
                                          ),
                                        ),
                                        if (lastSuccessfulSync != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Last successful sync: $lastSuccessfulSync • Official source offline',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ...prices.map((m) {
                            final isTop = prices.first.id == m.id;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _MandiCard(
                                price: m,
                                isHighlighted: isTop,
                                tag: isTop ? l10n.topModalRate : null,
                                isLive: isLive,
                                isLastAvailable: isFailed || isStale,
                                lastUpdated: m.sourceUpdatedAt ??
                                    m.ingestedAt ??
                                    lastSuccessfulSync ??
                                    lastUpdated,
                                onTap: () => context.push(
                                  '${AppRoutes.markets}/detail?market=${Uri.encodeComponent(m.market)}&commodity=${Uri.encodeComponent(m.displayName)}',
                                ),
                                onCalculate: () => context.push(
                                  '${AppRoutes.netRealization}?market=${Uri.encodeComponent(m.market)}&commodity=${Uri.encodeComponent(m.displayName)}&qty=20',
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Live trade feed
                  _LiveTradeFeed(
                    isLive: isLive,
                    prices: pricesAsync.asData?.value ?? [],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Sub-widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CommodityRibbon extends StatelessWidget {
  const _CommodityRibbon({
    required this.commodities,
    required this.selected,
    required this.onChanged,
  });

  final List<(String, String, String)> commodities;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: commodities.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final c = commodities[i];
          final isSelected = c.$1.toLowerCase() == selected.toLowerCase() ||
              (selected.toLowerCase() == 'all' && c.$1.toLowerCase() == 'all');
          return GestureDetector(
            onTap: () => onChanged(c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Text(c.$2, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    c.$3,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StateScopeToggle extends StatelessWidget {
  const _StateScopeToggle({
    required this.isAllIndia,
    required this.selectedState,
    required this.totalRecords,
    required this.onSelectMaharashtra,
    required this.onSelectAllIndia,
  });

  final bool isAllIndia;
  final String? selectedState;
  final int totalRecords;
  final VoidCallback onSelectMaharashtra;
  final VoidCallback onSelectAllIndia;

  @override
  Widget build(BuildContext context) {
    final isMhActive = !isAllIndia && (selectedState == 'Maharashtra' || selectedState == null);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSelectMaharashtra,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: isMhActive
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isMhActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      size: 16,
                      color: isMhActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Maharashtra (Focus)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMhActive ? AppColors.onPrimary : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: onSelectAllIndia,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: !isMhActive
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isMhActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 16,
                      color: !isMhActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'All India (All Mandis)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: !isMhActive ? AppColors.onPrimary : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationFilterRow extends StatelessWidget {
  const _LocationFilterRow({
    required this.selectedState,
    required this.selectedDistrict,
    required this.selectedMarket,
    this.selectedVariety,
    this.isAllIndia = false,
    this.availableVarietiesCount = 0,
    required this.onTapState,
    required this.onTapDistrict,
    required this.onTapMarket,
    required this.onTapVariety,
    required this.onClearAll,
  });

  final String? selectedState;
  final String? selectedDistrict;
  final String? selectedMarket;
  final String? selectedVariety;
  final bool isAllIndia;
  final int availableVarietiesCount;
  final VoidCallback onTapState;
  final VoidCallback onTapDistrict;
  final VoidCallback onTapMarket;
  final VoidCallback onTapVariety;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = (isAllIndia
            ? selectedState != null
            : (selectedState != 'Maharashtra' && selectedState != null)) ||
        selectedDistrict != null ||
        selectedMarket != null ||
        selectedVariety != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            icon: Icons.map_outlined,
            label: selectedState != null
                ? 'State: $selectedState'
                : (isAllIndia ? 'State: All India' : 'State: Maharashtra'),
            isActive: selectedState != null,
            onTap: onTapState,
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChipButton(
            icon: Icons.location_city_outlined,
            label: selectedDistrict != null
                ? 'District: $selectedDistrict'
                : 'District: All',
            isActive: selectedDistrict != null,
            onTap: onTapDistrict,
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChipButton(
            icon: Icons.storefront_outlined,
            label: selectedMarket != null
                ? 'Market: $selectedMarket'
                : 'Market: All',
            isActive: selectedMarket != null,
            onTap: onTapMarket,
          ),
          if (availableVarietiesCount > 0 || selectedVariety != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _FilterChipButton(
              icon: Icons.grain_outlined,
              label: selectedVariety != null
                  ? 'Variety: $selectedVariety'
                  : 'Variety: All',
              isActive: selectedVariety != null,
              onTap: onTapVariety,
            ),
          ],
          if (hasActiveFilter) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onClearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 13, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOptionSheet extends StatefulWidget {
  const _FilterOptionSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  @override
  State<_FilterOptionSheet> createState() => _FilterOptionSheetState();
}

class _FilterOptionSheetState extends State<_FilterOptionSheet> {
  late TextEditingController _searchCtrl;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => widget.onSelected(null),
                    child: const Text('Clear Filter'),
                  ),
                ],
              ),
            ),
            if (widget.options.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: filtered.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    final isAll = widget.selectedValue == null;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isAll
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isAll
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                      title: Text(
                        'All (${widget.title})',
                        style: TextStyle(
                          fontWeight: isAll ? FontWeight.w700 : FontWeight.w400,
                          color: isAll ? AppColors.primary : AppColors.onSurface,
                        ),
                      ),
                      onTap: () => widget.onSelected(null),
                    );
                  }
                  final option = filtered[i - 1];
                  final isSelected = widget.selectedValue == option;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 18,
                    ),
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                    onTap: () => widget.onSelected(option),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RadiusFilter extends StatelessWidget {
  const _RadiusFilter({
    required this.labels,
    required this.selectedIdx,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIdx;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == selectedIdx;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4)
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MandiMapArea extends StatelessWidget {
  const _MandiMapArea({required this.prices, required this.isLive});

  final List<MandiPrice> prices;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final pin1 = prices.isNotEmpty ? prices[0] : null;
    final pin2 = prices.length > 1 ? prices[1] : null;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceContainerLow,
                    AppColors.surfaceContainer,
                  ],
                ),
              ),
            ),
            // Transit corridors
            CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _TransitCorridorPainter(),
            ),
            // Map pins
            if (pin1 != null)
              Positioned(
                top: 25,
                right: 35,
                child: _MapPin(
                  label: pin1.market,
                  price: '₹${pin1.modalPrice.toInt()}/Q',
                  color: AppColors.primaryContainer,
                  textColor: AppColors.onPrimary,
                  isTop: true,
                ),
              ),
            if (pin2 != null)
              Positioned(
                top: 75,
                left: 75,
                child: _MapPin(
                  label: pin2.market,
                  price: '₹${pin2.modalPrice.toInt()}/Q',
                  color: AppColors.surfaceContainerHigh,
                  textColor: AppColors.onSurface,
                  isTop: false,
                ),
              ),
            Positioned(
              bottom: 40,
              left: 30,
              child: _YouAreHerePin(),
            ),
            // Footer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                color: AppColors.inverseSurface.withOpacity(0.7),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: AppColors.inverseOnSurface),
                    const SizedBox(width: 4),
                    Text(
                      'Tap pin or card for market history & net realization',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.inverseOnSurface,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        LivePulsingDot(
                          color: isLive ? AppColors.secondary : AppColors.outline,
                          size: 6,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isLive ? 'Live e-NAM' : 'Agmarknet Gov Data',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.inverseOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransitCorridorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashed = Paint()
      ..color = AppColors.secondary.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // NH60 corridor
    final path1 = Path()
      ..moveTo(size.width * 0.18, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.4,
          size.width * 0.88, size.height * 0.2);
    canvas.drawPath(path1, dashed);

    // Local route
    final path2 = Path()
      ..moveTo(size.width * 0.18, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.55,
          size.width * 0.45, size.height * 0.45);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.label,
    required this.price,
    required this.color,
    required this.textColor,
    required this.isTop,
  });

  final String label;
  final String price;
  final Color color;
  final Color textColor;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15), blurRadius: 4),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              if (isTop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up,
                        size: 10, color: AppColors.secondaryFixed),
                    Text(
                      ' Top Rate',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.secondaryFixed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Container(
          width: 2,
          height: 8,
          color: color,
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _YouAreHerePin extends StatefulWidget {
  @override
  State<_YouAreHerePin> createState() => _YouAreHerePinState();
}

class _YouAreHerePinState extends State<_YouAreHerePin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.secondary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Opacity(
                  opacity: 0.3 + 0.7 * _ctrl.value,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Junnar Cluster',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        Text(
          'You are here',
          style: TextStyle(
            fontSize: 8,
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AudioSummaryBar extends StatelessWidget {
  const _AudioSummaryBar({
    required this.prices,
    required this.selectedCommodity,
  });

  final List<MandiPrice> prices;
  final String selectedCommodity;

  @override
  Widget build(BuildContext context) {
    final summaryText = prices.isNotEmpty
        ? '${prices.first.market} reported modal rate at ₹${prices.first.modalPrice.toInt()}/Q for ${prices.first.commodity}'
        : 'Awaiting Agmarknet arrivals for ${selectedCommodity.toUpperCase()}';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.volume_up,
                size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              summaryText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.play_circle,
              color: AppColors.secondary, size: 22),
        ],
      ),
    );
  }
}

class _MandiCard extends StatelessWidget {
  const _MandiCard({
    required this.price,
    required this.isHighlighted,
    this.tag,
    required this.isLive,
    required this.isLastAvailable,
    this.lastUpdated,
    required this.onTap,
    required this.onCalculate,
  });

  final MandiPrice price;
  final bool isHighlighted;
  final String? tag;
  final bool isLive;
  final bool isLastAvailable;
  final String? lastUpdated;
  final VoidCallback onTap;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    final varietyText = price.variety.isNotEmpty && price.variety != 'Other'
        ? ' • ${price.variety}'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price.market,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isHighlighted
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${price.commodity}$varietyText',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHighlighted
                                ? AppColors.onPrimary.withOpacity(0.8)
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.secondaryContainer
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isHighlighted
                              ? AppColors.onSecondaryContainer
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Market Location, Arrivals & Date
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${price.district}, ${price.state}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (price.arrivalQuantity != null && price.arrivalQuantity! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  size: 11, color: AppColors.secondary),
                              const SizedBox(width: 3),
                              Text(
                                '${price.arrivalQuantity!.toInt()} Qtl',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Date: ${price.arrivalDate}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Price grid: Min, Modal, Max
                  Row(
                    children: [
                      _PriceStat(label: 'Min Price', value: price.minPrice),
                      _PriceDivider(),
                      _PriceStat(
                        label: 'Modal Price',
                        value: price.modalPrice,
                        isModal: true,
                      ),
                      _PriceDivider(),
                      _PriceStat(label: 'Max Price', value: price.maxPrice),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Source & Last updated row + CTA
                  Row(
                    children: [
                      Expanded(
                        child: DataSourceTag(
                          source: price.source,
                          arrivalDate: price.arrivalDate,
                          lastUpdated: lastUpdated,
                          isLive: isLive,
                          isLastAvailable: isLastAvailable,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: onCalculate,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calculate,
                                  size: 15, color: AppColors.onPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Calculate Net Payout',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
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
    );
  }
}

class _PriceStat extends StatelessWidget {
  const _PriceStat(
      {required this.label, required this.value, this.isModal = false});
  final String label;
  final double value;
  final bool isModal;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatInr(value),
            style: TextStyle(
              fontSize: isModal ? 18 : 14,
              fontWeight: FontWeight.w800,
              color: isModal ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          Text(
            '/Quintal',
            style: TextStyle(
                fontSize: 9, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PriceDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.outlineVariant,
    );
  }
}

class _LiveTradeFeed extends StatelessWidget {
  const _LiveTradeFeed({required this.isLive, required this.prices});

  final bool isLive;
  final List<MandiPrice> prices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LivePulsingDot(
                color: isLive ? AppColors.secondary : AppColors.outline,
                size: 8,
              ),
              const SizedBox(width: 6),
              Text(
                isLive
                    ? 'Verified Arhtiya Trade Feed'
                    : 'Government Market Data Arrivals',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (prices.isNotEmpty) ...[
            ...prices.take(3).map(
                  (p) => _TradeEntry(
                    text:
                        '${p.market}: ${p.commodity} arrived — Modal ₹${p.modalPrice.toInt()}/Q (Min ₹${p.minPrice.toInt()} - Max ₹${p.maxPrice.toInt()})',
                    time: p.arrivalDate,
                  ),
                ),
          ] else ...[
            _TradeEntry(
              text: isLive
                  ? 'Awaiting live trade transactions from APMC'
                  : 'Awaiting Agmarknet synchronized records',
              time: 'Recent',
            ),
          ],
        ],
      ),
    );
  }
}

class _TradeEntry extends StatelessWidget {
  const _TradeEntry({required this.text, required this.time});
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
                color: AppColors.secondary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: AppColors.onSurface),
            ),
          ),
          Text(
            time,
            style: TextStyle(
                fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

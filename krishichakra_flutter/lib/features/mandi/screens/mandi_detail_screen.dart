import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/mandi_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/kc_widgets.dart';

enum MandiPeriod {
  sevenDays('7 Days', 7),
  thirtyDays('30 Days', 30),
  oneYear('1 Year', 365);

  const MandiPeriod(this.label, this.days);
  final String label;
  final int days;
}

DateTime? _parseDate(String dateStr) {
  try {
    if (dateStr.contains('-')) {
      return DateTime.parse(dateStr);
    }
    if (dateStr.contains('/')) {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }
  } catch (_) {}
  return null;
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  if (month >= 1 && month <= 12) return months[month - 1];
  return '';
}

String _formatFullDate(DateTime dt) {
  return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
}

String _formatShortDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$d/$m';
}

String _formatDateString(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class MandiDetailScreen extends ConsumerStatefulWidget {
  const MandiDetailScreen({
    super.key,
    required this.market,
    required this.commodity,
  });

  final String market;
  final String commodity;

  @override
  ConsumerState<MandiDetailScreen> createState() => _MandiDetailScreenState();
}

class _MandiDetailScreenState extends ConsumerState<MandiDetailScreen> {
  MandiPeriod _selectedPeriod = MandiPeriod.sevenDays;
  bool _showModal = true;
  bool _showMin = false;
  bool _showMax = false;

  String get _periodParam {
    switch (_selectedPeriod) {
      case MandiPeriod.sevenDays:
        return '7d';
      case MandiPeriod.thirtyDays:
        return '30d';
      case MandiPeriod.oneYear:
        return '1y';
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(
      mandiDailyHistoryProvider((
        commodity: widget.commodity,
        market: widget.market,
        period: _periodParam,
      )),
    );
    ref.invalidate(mandiStatusProvider);
  }

  Widget _buildFallbackBanner(MandiDailyHistory historyData) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing nearby government market data (${historyData.fallbackMarket}) for price reference.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(mandiStatusProvider);
    final historyAsync = ref.watch(
      mandiDailyHistoryProvider((
        commodity: widget.commodity,
        market: widget.market,
        period: _periodParam,
      )),
    );

    final status = statusAsync.asData?.value;
    final isLive = status?.isLive ?? false;
    final isFailed = status?.hasFailedSync ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: true,
              snap: true,
              expandedHeight: 80,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: widget.market.isEmpty ? 'Mandi Detail' : widget.market,
                subtitle: widget.commodity.isEmpty
                    ? 'Government Price History'
                    : '${widget.commodity} Price History',
                showBack: true,
                showLiveIndicator: isLive,
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
                    tooltip: 'Refresh Gov History',
                    onPressed: _refresh,
                  ),
                ],
              ),
              toolbarHeight: 80,
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // â”€â”€ Source & Status Provenance Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  historyAsync.maybeWhen(
                    data: (h) => DataSourceTag(
                      source: h.source.isNotEmpty
                          ? h.source
                          : (status?.source ??
                              'Government Market Data (AGMARKNET / data.gov.in)'),
                      lastUpdated: h.lastUpdated ??
                          status?.lastSuccessfulSync ??
                          status?.lastSync,
                      isLive: isLive,
                      isLastAvailable: isFailed,
                      compact: false,
                    ),
                    orElse: () => DataSourceTag(
                      source: status?.source ??
                          'Government Market Data (AGMARKNET / data.gov.in)',
                      lastUpdated: status?.lastSuccessfulSync ?? status?.lastSync,
                      isLive: isLive,
                      isLastAvailable: isFailed,
                      compact: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // â”€â”€ Period Selector: [ 7 Days ] [ 30 Days ] [ 1 Year ] â”€â”€â”€â”€â”€
                  _PeriodSelector(
                    selected: _selectedPeriod,
                    onChanged: (p) => setState(() => _selectedPeriod = p),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // â”€â”€ History Records & Chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  historyAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: KcLoadingIndicator(
                          message: 'Loading government market data...',
                        ),
                      ),
                    ),
                    error: (err, _) => KcErrorState(
                      message: 'Government source temporarily unavailable.',
                      onRetry: _refresh,
                    ),
                    data: (historyData) {
                      int counter = 1;
                      final reportedRecords = historyData.records
                          .where((r) => r.hasData)
                          .map((r) => MandiPrice(
                                id: counter++,
                                commodity: r.commodity,
                                market: r.market,
                                state: r.state ?? '',
                                district: r.district ?? '',
                                variety: r.variety ?? '',
                                minPrice: r.minPrice ?? 0.0,
                                modalPrice: r.modalPrice ?? 0.0,
                                maxPrice: r.maxPrice ?? 0.0,
                                arrivalDate: r.date,
                                arrivalQuantity: r.arrivalQuantity,
                                unit: r.unit,
                                source: r.source.isNotEmpty
                                    ? r.source
                                    : 'Government Market Data',
                              ))
                          .toList();

                      final hasFallback = historyData.isFallback &&
                          historyData.fallbackMarket != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasFallback) ...[
                            _buildFallbackBanner(historyData),
                          ],

                          // â”€â”€ Summary Metrics for Selected Period â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          _MandiPriceSummaryStats(
                            summary: historyData.summary,
                            datesWithData: historyData.datesWithData,
                            datesChecked: historyData.datesChecked,
                          ),

                          // â”€â”€ Historical Chart with Real Gov Data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          _MandiPriceHistoryChart(
                            history: historyData,
                            period: _selectedPeriod,
                            showModal: _showModal,
                            showMin: _showMin,
                            showMax: _showMax,
                            onToggleModal: () =>
                                setState(() => _showModal = !_showModal),
                            onToggleMin: () =>
                                setState(() => _showMin = !_showMin),
                            onToggleMax: () =>
                                setState(() => _showMax = !_showMax),
                          ),

                          // â”€â”€ Timeline List Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                          Row(
                            children: [
                              Icon(Icons.timeline_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Arrival Price Timeline (${reportedRecords.length} record${reportedRecords.length > 1 ? "s" : ""})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // â”€â”€ Timeline Cards (Actual Reported Records Only) â”€
                          ...reportedRecords.map(
                            (rec) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _HistoryCard(
                                price: rec,
                                isLive: isLive,
                                isLastAvailable: isFailed,
                                lastUpdated: historyData.lastUpdated ??
                                    status?.lastSuccessfulSync ??
                                    status?.lastSync,
                                onCalculate: () => context.push(
                                  '${AppRoutes.netRealization}?market=${Uri.encodeComponent(rec.market)}&commodity=${Uri.encodeComponent(rec.commodity)}&qty=20',
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

// â”€â”€â”€ Period Selector Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final MandiPeriod selected;
  final ValueChanged<MandiPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: MandiPeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// â”€â”€â”€ Summary Statistics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MandiPriceSummaryStats extends StatelessWidget {
  const _MandiPriceSummaryStats({
    required this.summary,
    required this.datesWithData,
    required this.datesChecked,
  });

  final MandiHistorySummary summary;
  final int datesWithData;
  final int datesChecked;

  @override
  Widget build(BuildContext context) {
    final trendPercent = summary.trendPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Government Market Price Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (trendPercent != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendPercent >= 0
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendPercent >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: trendPercent >= 0
                            ? AppColors.primary
                            : Colors.red[700],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${trendPercent >= 0 ? "+" : ""}${trendPercent.toStringAsFixed(1)}% trend',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: trendPercent >= 0
                              ? AppColors.primary
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatItem(
                label: 'Latest Modal',
                value: formatInr(summary.latestModal),
                color: AppColors.primary,
              ),
              _StatDivider(),
              _StatItem(
                label: 'Period Min',
                value: formatInr(summary.periodMin),
                color: AppColors.onSurface,
              ),
              _StatDivider(),
              _StatItem(
                label: 'Period Max',
                value: formatInr(summary.periodMax),
                color: AppColors.onSurface,
              ),
              _StatDivider(),
              _StatItem(
                label: 'Avg Modal',
                value: formatInr(summary.avgModal),
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.outlineVariant,
    );
  }
}

// â”€â”€â”€ Monthly Aggregated Point for 1-Year View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MonthlyAggregatedPoint {
  const _MonthlyAggregatedPoint({
    required this.monthDate,
    required this.label,
    required this.fullLabel,
    required this.avgModal,
    required this.minPrice,
    required this.maxPrice,
    required this.recordCount,
    required this.representativeRecord,
    this.hasGovData = false,
  });

  final DateTime monthDate;
  final String label;
  final String fullLabel;
  final double avgModal;
  final double minPrice;
  final double maxPrice;
  final int recordCount;
  final MandiHistoryPoint representativeRecord;
  final bool hasGovData;
}

// â”€â”€â”€ Historical Price Chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MandiPriceHistoryChart extends StatelessWidget {
  const _MandiPriceHistoryChart({
    required this.history,
    required this.period,
    required this.showModal,
    required this.showMin,
    required this.showMax,
    required this.onToggleModal,
    required this.onToggleMin,
    required this.onToggleMax,
  });

  final MandiDailyHistory history;
  final MandiPeriod period;
  final bool showModal;
  final bool showMin;
  final bool showMax;
  final VoidCallback onToggleModal;
  final VoidCallback onToggleMin;
  final VoidCallback onToggleMax;

  @override
  Widget build(BuildContext context) {
    if (history.records.isEmpty) return const SizedBox.shrink();

    final modalColor = AppColors.primary;
    const minColor = Color(0xFF0288D1);
    const maxColor = Color(0xFFE65100);

    if (period == MandiPeriod.sevenDays) {
      return _build7DayChart(context, modalColor, minColor, maxColor);
    } else if (period == MandiPeriod.oneYear) {
      return _build1YearChart(context, modalColor, minColor, maxColor);
    } else {
      return _build30DayChart(context, modalColor, minColor, maxColor);
    }
  }

  // â”€â”€â”€ 7-Day View: Exact Daily Calendar with Explicit Gaps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _build7DayChart(
    BuildContext context,
    Color modalColor,
    Color minColor,
    Color maxColor,
  ) {
    final records = history.allCalendarDays.isNotEmpty ? history.allCalendarDays : history.records;
    if (records.isEmpty) return const SizedBox.shrink();

    // Map fallback records by date
    final fallbackMap = <String, MandiHistoryPoint>{};
    for (final fb in history.fallbackRecords) {
      if (fb.date.isNotEmpty) {
        fallbackMap[fb.date] = fb;
      }
    }

    // Compute min and max values only from actual data points (including fallback)
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    for (final r in records) {
      if (!r.hasData) continue;
      if (showModal && r.modalPrice != null) {
        if (r.modalPrice! < minVal) minVal = r.modalPrice!;
        if (r.modalPrice! > maxVal) maxVal = r.modalPrice!;
      }
      if (showMin && r.minPrice != null) {
        if (r.minPrice! < minVal) minVal = r.minPrice!;
        if (r.minPrice! > maxVal) maxVal = r.minPrice!;
      }
      if (showMax && r.maxPrice != null) {
        if (r.maxPrice! < minVal) minVal = r.maxPrice!;
        if (r.maxPrice! > maxVal) maxVal = r.maxPrice!;
      }
    }

    // Also include fallback prices in Y bounds so dashed line is not clipped
    for (final fb in history.fallbackRecords) {
      if (fb.modalPrice != null) {
        if (fb.modalPrice! < minVal) minVal = fb.modalPrice!;
        if (fb.modalPrice! > maxVal) maxVal = fb.modalPrice!;
      }
    }

    if (minVal == double.infinity) {
      minVal = 0;
      maxVal = 100;
    }
    final range = maxVal - minVal;
    final yMargin = range > 0 ? range * 0.2 : (minVal > 0 ? minVal * 0.15 : 10.0);
    final minY = (minVal - yMargin).clamp(0.0, double.infinity);
    final maxY = maxVal + yMargin;
    final medianY = (minY + maxY) / 2;

    final lineBars = <LineChartBarData>[];

    if (showModal) {
      final spots = <FlSpot>[];
      for (int i = 0; i < records.length; i++) {
        if (records[i].modalPrice != null) {
          spots.add(FlSpot(i.toDouble(), records[i].modalPrice!));
        }
      }
      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            curveSmoothness: 0.2,
            color: modalColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final idx = spot.x.toInt();
                final isGov = idx >= 0 &&
                    idx < records.length &&
                    (records[idx].source.contains('Government') ||
                        records[idx].dataQuality == 'government_exact_market');
                if (isGov) {
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: modalColor,
                    strokeWidth: 2,
                    strokeColor: AppColors.surfaceContainerLowest,
                  );
                } else {
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: AppColors.surfaceContainerLowest,
                    strokeWidth: 2.5,
                    strokeColor: modalColor,
                  );
                }
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  modalColor.withValues(alpha: 0.15),
                  modalColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      }
    }

    if (showMin) {
      final spots = <FlSpot>[];
      for (int i = 0; i < records.length; i++) {
        if (records[i].minPrice != null) {
          spots.add(FlSpot(i.toDouble(), records[i].minPrice!));
        }
      }
      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            curveSmoothness: 0.2,
            color: minColor,
            barWidth: 2,
            dashArray: [5, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final idx = spot.x.toInt();
                final isGov = idx >= 0 &&
                    idx < records.length &&
                    (records[idx].source.contains('Government') ||
                        records[idx].dataQuality == 'government_exact_market');
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: isGov ? minColor : AppColors.surfaceContainerLowest,
                  strokeWidth: 1.5,
                  strokeColor: minColor,
                );
              },
            ),
          ),
        );
      }
    }

    if (showMax) {
      final spots = <FlSpot>[];
      for (int i = 0; i < records.length; i++) {
        if (records[i].maxPrice != null) {
          spots.add(FlSpot(i.toDouble(), records[i].maxPrice!));
        }
      }
      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            curveSmoothness: 0.2,
            color: maxColor,
            barWidth: 2,
            dashArray: [5, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final idx = spot.x.toInt();
                final isGov = idx >= 0 &&
                    idx < records.length &&
                    (records[idx].source.contains('Government') ||
                        records[idx].dataQuality == 'government_exact_market');
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: isGov ? maxColor : AppColors.surfaceContainerLowest,
                  strokeWidth: 1.5,
                  strokeColor: maxColor,
                );
              },
            ),
          ),
        );
      }
    }

    final maxX = (records.length - 1).toDouble().clamp(0.0, double.infinity);

    return _buildChartCard(
      title: 'Modal Price Movement (₹/Q)',
      badgeText: '${history.datesWithData}/${history.datesChecked} Days Recorded',
      badgeColor: modalColor,
      modalColor: modalColor,
      minColor: minColor,
      maxColor: maxColor,
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            verticalInterval: 1,
            getDrawingVerticalLine: (val) {
              final idx = val.toInt();
              final isGap = idx >= 0 &&
                  idx < records.length &&
                  !records[idx].hasData;
              return FlLine(
                color: isGap
                    ? Colors.amber.withValues(alpha: 0.25)
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
                strokeWidth: isGap ? 1.5 : 0.8,
                dashArray: isGap ? [3, 3] : null,
              );
            },
            horizontalInterval: range > 0 ? range / 3 : 100,
            getDrawingHorizontalLine: (val) => FlLine(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= records.length) {
                    return const SizedBox.shrink();
                  }
                  final r = records[idx];
                  final dt = _parseDate(r.date) ??
                      DateTime.now().subtract(Duration(days: records.length - 1 - idx));
                  final label = _formatShortDate(dt);
                  final isReported = r.hasData;

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isReported ? FontWeight.w700 : FontWeight.w500,
                        color: isReported
                            ? AppColors.onSurface
                            : Colors.amber.shade800,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${value.toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBars,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= records.length) return null;
                  final r = records[idx];
                  final isGovPoint = r.source.contains('Government') ||
                      r.dataQuality == 'government_exact_market';
                  final sourceLabel = isGovPoint
                      ? 'Government Market Data'
                      : 'Prototype Estimate';
                  final dt = _parseDate(r.date) ??
                      DateTime.now().subtract(Duration(days: records.length - 1 - idx));
                  final dateFormatted = _formatFullDate(dt);

                  final minFormatted = r.minPrice != null
                      ? '₹${r.minPrice!.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d\d)+\d$)"), (m) => "${m[1]},")}/Q'
                      : 'N/A';
                  final modalFormatted = r.modalPrice != null
                      ? '₹${r.modalPrice!.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d\d)+\d$)"), (m) => "${m[1]},")}/Q'
                      : 'N/A';
                  final maxFormatted = r.maxPrice != null
                      ? '₹${r.maxPrice!.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d\d)+\d$)"), (m) => "${m[1]},")}/Q'
                      : 'N/A';

                  return LineTooltipItem(
                    '$dateFormatted\n'
                    '${r.commodity.isNotEmpty ? r.commodity : history.commodity}\n'
                    '${r.market.isNotEmpty ? r.market : history.market}\n\n'
                    'Min: $minFormatted\n'
                    'Modal: $modalFormatted\n'
                    'Max: $maxFormatted\n\n'
                    'Source:\n$sourceLabel',
                    const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 6),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: modalColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '● Government data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: modalColor, width: 2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '○ Prototype estimate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  records.any((r) => r.source.contains('Government') || r.dataQuality == 'government_exact_market') &&
                          records.any((r) => r.source.contains('Prototype') || r.dataQuality == 'prototype_estimate')
                      ? 'Government data available for some dates; missing dates show prototype estimates.'
                      : (records.any((r) => r.source.contains('Government') || r.dataQuality == 'government_exact_market')
                          ? 'Government Market Data (data.gov.in / AGMARKNET).'
                          : 'Prototype estimated trend — not government data.'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ 30-Day View: Full Month Actual Daily Trend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _build30DayChart(
    BuildContext context,
    Color modalColor,
    Color minColor,
    Color maxColor,
  ) {
    final records = history.records.isNotEmpty ? history.records : history.allCalendarDays;
    if (records.isEmpty) return const SizedBox.shrink();

    final spotsModal = <FlSpot>[];
    final spotsMin = <FlSpot>[];
    final spotsMax = <FlSpot>[];

    double minVal = double.infinity;
    double maxVal = -double.infinity;

    for (int i = 0; i < records.length; i++) {
      final p = records[i].modalPrice ?? 0.0;
      spotsModal.add(FlSpot(i.toDouble(), p));
      if (records[i].minPrice != null) {
        spotsMin.add(FlSpot(i.toDouble(), records[i].minPrice!));
      }
      if (records[i].maxPrice != null) {
        spotsMax.add(FlSpot(i.toDouble(), records[i].maxPrice!));
      }

      if (showModal && p > 0) {
        if (p < minVal) minVal = p;
        if (p > maxVal) maxVal = p;
      }
      if (showMin && records[i].minPrice != null) {
        if (records[i].minPrice! < minVal) minVal = records[i].minPrice!;
        if (records[i].minPrice! > maxVal) maxVal = records[i].minPrice!;
      }
      if (showMax && records[i].maxPrice != null) {
        if (records[i].maxPrice! < minVal) minVal = records[i].maxPrice!;
        if (records[i].maxPrice! > maxVal) maxVal = records[i].maxPrice!;
      }
    }

    if (minVal == double.infinity) {
      minVal = 0;
      maxVal = 100;
    }
    final range = maxVal - minVal;
    final yMargin = range > 0 ? range * 0.2 : (minVal > 0 ? minVal * 0.15 : 10.0);
    final minY = (minVal - yMargin).clamp(0.0, double.infinity);
    final maxY = maxVal + yMargin;

    final lineBars = <LineChartBarData>[];

    if (showModal && spotsModal.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: spotsModal,
          isCurved: records.length > 2,
          curveSmoothness: 0.2,
          color: modalColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final idx = spot.x.toInt();
              final isGov = idx >= 0 &&
                  idx < records.length &&
                  (records[idx].source.contains('Government') ||
                      records[idx].dataQuality == 'government_exact_market');
              if (isGov) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: modalColor,
                  strokeWidth: 1.5,
                  strokeColor: AppColors.surfaceContainerLowest,
                );
              } else {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.surfaceContainerLowest,
                  strokeWidth: 2,
                  strokeColor: modalColor,
                );
              }
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                modalColor.withValues(alpha: 0.15),
                modalColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    if (showMin && spotsMin.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: spotsMin,
          isCurved: records.length > 2,
          curveSmoothness: 0.2,
          color: minColor,
          barWidth: 2,
          dashArray: [5, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final idx = spot.x.toInt();
              final isGov = idx >= 0 &&
                  idx < records.length &&
                  (records[idx].source.contains('Government') ||
                      records[idx].dataQuality == 'government_exact_market');
              return FlDotCirclePainter(
                radius: 3,
                color: isGov ? minColor : AppColors.surfaceContainerLowest,
                strokeWidth: 1.5,
                strokeColor: minColor,
              );
            },
          ),
        ),
      );
    }

    if (showMax && spotsMax.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: spotsMax,
          isCurved: records.length > 2,
          curveSmoothness: 0.2,
          color: maxColor,
          barWidth: 2,
          dashArray: [5, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final idx = spot.x.toInt();
              final isGov = idx >= 0 &&
                  idx < records.length &&
                  (records[idx].source.contains('Government') ||
                      records[idx].dataQuality == 'government_exact_market');
              return FlDotCirclePainter(
                radius: 3,
                color: isGov ? maxColor : AppColors.surfaceContainerLowest,
                strokeWidth: 1.5,
                strokeColor: maxColor,
              );
            },
          ),
        ),
      );
    }

    final bool hasGov = records.any((r) =>
        r.source.contains('Government') ||
        r.dataQuality == 'government_exact_market');
    final bool hasEst = records.any((r) =>
        r.source.contains('Prototype') ||
        r.dataQuality == 'prototype_estimate');

    return _buildChartCard(
      title: 'Modal Price Movement (₹/Q)',
      badgeText: hasGov ? (hasEst ? 'Gov & Prototype Data' : 'Government Data') : 'Prototype Trend',
      badgeColor: modalColor,
      modalColor: modalColor,
      minColor: minColor,
      maxColor: maxColor,
      chart: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 3 : 100,
            getDrawingHorizontalLine: (val) => FlLine(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= records.length) {
                    return const SizedBox.shrink();
                  }
                  if (records.length > 7 &&
                      idx % (records.length ~/ 5) != 0 &&
                      idx != records.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final dt = _parseDate(records[idx].date);
                  final label =
                      dt != null ? _formatShortDate(dt) : records[idx].date;

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${value.toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBars,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= records.length) return null;
                  final rec = records[idx];
                  final isGovPoint = rec.source.contains('Government') ||
                      rec.dataQuality == 'government_exact_market';
                  final sourceLabel = isGovPoint
                      ? 'Government Market Data'
                      : 'Prototype Estimate';
                  final dt = _parseDate(rec.date);
                  final dateFormatted =
                      dt != null ? _formatFullDate(dt) : rec.date;

                  final minFormatted = rec.minPrice != null
                      ? '₹${rec.minPrice!.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d\d)+\d$)"), (m) => "${m[1]},")}/Q'
                      : 'N/A';
                  final modalFormatted = rec.modalPrice != null
                      ? '₹${rec.modalPrice!.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d\d)+\d$)"), (m) => "${m[1]},")}/Q'
                      : 'N/A';
                  final maxFormatted = rec.maxPrice != null
                      ? '₹${rec.maxPrice!.toInt().toString().replaceAllMapped(RegExp(r"(\d)(?=(\d\d)+\d$)"), (m) => "${m[1]},")}/Q'
                      : 'N/A';

                  return LineTooltipItem(
                    '$dateFormatted\n'
                    '${rec.commodity.isNotEmpty ? rec.commodity : history.commodity}\n'
                    '${rec.market.isNotEmpty ? rec.market : history.market}\n\n'
                    'Min: $minFormatted\n'
                    'Modal: $modalFormatted\n'
                    'Max: $maxFormatted\n\n'
                    'Source:\n$sourceLabel',
                    const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 6),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: modalColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '● Government data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: modalColor, width: 2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '○ Prototype estimate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hasGov && hasEst
                      ? 'Government data available for some dates; others show prototype estimates.'
                      : (hasGov
                          ? 'Government Market Data (data.gov.in / AGMARKNET).'
                          : 'Prototype estimated trend — not government data.'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ 1-Year View: Monthly Aggregation from Real Database Records â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _build1YearChart(
    BuildContext context,
    Color modalColor,
    Color minColor,
    Color maxColor,
  ) {
    // Group actual reported records by Year-Month
    final monthlyGroups = <String, List<MandiHistoryPoint>>{};
    for (final r in history.records) {
      if (!r.hasData || r.modalPrice == null) continue;
      final dt = _parseDate(r.date);
      if (dt != null) {
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        monthlyGroups.putIfAbsent(key, () => []).add(r);
      }
    }

    // Baseline modal price for fallback months
    double baseModal = 2200.0;
    for (final r in history.records) {
      if (r.modalPrice != null && r.modalPrice! > 0) {
        baseModal = r.modalPrice!;
        break;
      }
    }
    if (history.summary.latestModal > 0) {
      baseModal = history.summary.latestModal;
    }

    // Build the 12 calendar month keys
    final now = DateTime.now();
    final all12MonthKeys = <String>[];
    for (int i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      all12MonthKeys.add(k);
    }

    final keysToUse = monthlyGroups.length >= 6
        ? (monthlyGroups.keys.toList()..sort())
        : all12MonthKeys;

    final aggregatedPoints = <_MonthlyAggregatedPoint>[];

    for (int mi = 0; mi < keysToUse.length; mi++) {
      final key = keysToUse[mi];
      final monthRecords = monthlyGroups[key];
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthDate = DateTime(year, month, 1);
      final label = '${_monthName(month)} ${year.toString().substring(2)}';
      final fullLabel = '${_monthName(month)} $year';

      if (monthRecords != null && monthRecords.isNotEmpty) {
        double sumModal = 0;
        double minP = double.infinity;
        double maxP = -double.infinity;
        bool hasGov = false;

        for (final r in monthRecords) {
          sumModal += r.modalPrice!;
          if (r.minPrice != null && r.minPrice! < minP) minP = r.minPrice!;
          if (r.maxPrice != null && r.maxPrice! > maxP) maxP = r.maxPrice!;
          if (r.source.contains('Government') || r.dataQuality == 'government_exact_market') {
            hasGov = true;
          }
        }

        aggregatedPoints.add(
          _MonthlyAggregatedPoint(
            monthDate: monthDate,
            label: label,
            fullLabel: fullLabel,
            avgModal: sumModal / monthRecords.length,
            minPrice:
                minP == double.infinity ? sumModal / monthRecords.length : minP,
            maxPrice:
                maxP == -double.infinity ? sumModal / monthRecords.length : maxP,
            recordCount: monthRecords.length,
            representativeRecord: monthRecords.first,
            hasGovData: hasGov,
          ),
        );
      } else {
        // Prototype seasonal estimate for missing months
        final offset = (mi - 6) * 15.0 + (mi % 3 == 0 ? 30.0 : -20.0);
        final estModal = (baseModal + offset).clamp(500.0, 15000.0);
        final dummyRecord = MandiHistoryPoint(
          date: '$year-${month.toString().padLeft(2, '0')}-01',
          displayDate: '${_monthName(month)} $year',
          commodity: history.commodity,
          market: history.market,
          minPrice: estModal * 0.9,
          modalPrice: estModal,
          maxPrice: estModal * 1.1,
          hasData: true,
          source: 'Prototype Estimate',
          dataQuality: 'prototype_estimate',
          status: 'estimated',
        );

        aggregatedPoints.add(
          _MonthlyAggregatedPoint(
            monthDate: monthDate,
            label: label,
            fullLabel: fullLabel,
            avgModal: estModal,
            minPrice: estModal * 0.9,
            maxPrice: estModal * 1.1,
            recordCount: 1,
            representativeRecord: dummyRecord,
            hasGovData: false,
          ),
        );
      }
    }

    double minVal = double.infinity;
    double maxVal = -double.infinity;
    final spotsModal = <FlSpot>[];
    final spotsMin = <FlSpot>[];
    final spotsMax = <FlSpot>[];

    for (int i = 0; i < aggregatedPoints.length; i++) {
      final p = aggregatedPoints[i].avgModal;
      spotsModal.add(FlSpot(i.toDouble(), p));
      spotsMin.add(FlSpot(i.toDouble(), aggregatedPoints[i].minPrice));
      spotsMax.add(FlSpot(i.toDouble(), aggregatedPoints[i].maxPrice));

      if (showModal) {
        if (p < minVal) minVal = p;
        if (p > maxVal) maxVal = p;
      }
      if (showMin) {
        if (aggregatedPoints[i].minPrice < minVal) {
          minVal = aggregatedPoints[i].minPrice;
        }
        if (aggregatedPoints[i].minPrice > maxVal) {
          maxVal = aggregatedPoints[i].minPrice;
        }
      }
      if (showMax) {
        if (aggregatedPoints[i].maxPrice < minVal) {
          minVal = aggregatedPoints[i].maxPrice;
        }
        if (aggregatedPoints[i].maxPrice > maxVal) {
          maxVal = aggregatedPoints[i].maxPrice;
        }
      }
    }

    if (minVal == double.infinity) {
      minVal = 0;
      maxVal = 100;
    }
    final range = maxVal - minVal;
    final yMargin = range > 0 ? range * 0.2 : (minVal > 0 ? minVal * 0.15 : 10.0);
    final minY = (minVal - yMargin).clamp(0.0, double.infinity);
    final maxY = maxVal + yMargin;

    final lineBars = <LineChartBarData>[];

    if (showModal) {
      lineBars.add(
        LineChartBarData(
          spots: spotsModal,
          isCurved: aggregatedPoints.length > 2,
          curveSmoothness: 0.2,
          color: modalColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final idx = spot.x.toInt();
              final isGov = idx >= 0 &&
                  idx < aggregatedPoints.length &&
                  aggregatedPoints[idx].hasGovData;
              return FlDotCirclePainter(
                radius: 4,
                color: isGov ? modalColor : AppColors.surfaceContainerLowest,
                strokeWidth: 2,
                strokeColor: modalColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                modalColor.withValues(alpha: 0.2),
                modalColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    if (showMin) {
      lineBars.add(
        LineChartBarData(
          spots: spotsMin,
          isCurved: aggregatedPoints.length > 2,
          curveSmoothness: 0.2,
          color: minColor,
          barWidth: 2,
          dashArray: [5, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final idx = spot.x.toInt();
              final isGov = idx >= 0 &&
                  idx < aggregatedPoints.length &&
                  aggregatedPoints[idx].hasGovData;
              return FlDotCirclePainter(
                radius: 3,
                color: isGov ? minColor : AppColors.surfaceContainerLowest,
                strokeWidth: 1.5,
                strokeColor: minColor,
              );
            },
          ),
        ),
      );
    }

    if (showMax) {
      lineBars.add(
        LineChartBarData(
          spots: spotsMax,
          isCurved: aggregatedPoints.length > 2,
          curveSmoothness: 0.2,
          color: maxColor,
          barWidth: 2,
          dashArray: [5, 4],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final idx = spot.x.toInt();
              final isGov = idx >= 0 &&
                  idx < aggregatedPoints.length &&
                  aggregatedPoints[idx].hasGovData;
              return FlDotCirclePainter(
                radius: 3,
                color: isGov ? maxColor : AppColors.surfaceContainerLowest,
                strokeWidth: 1.5,
                strokeColor: maxColor,
              );
            },
          ),
        ),
      );
    }

    return _buildChartCard(
      title: 'Modal Price Movement (₹/Q)',
      badgeText: '${aggregatedPoints.length} Recorded Months',
      badgeColor: modalColor,
      modalColor: modalColor,
      minColor: minColor,
      maxColor: maxColor,
      chart: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 3 : 100,
            getDrawingHorizontalLine: (val) => FlLine(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= aggregatedPoints.length) {
                    return const SizedBox.shrink();
                  }
                  if (aggregatedPoints.length > 6 &&
                      idx % (aggregatedPoints.length ~/ 4) != 0 &&
                      idx != aggregatedPoints.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      aggregatedPoints[idx].label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${value.toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBars,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= aggregatedPoints.length) return null;
                  final p = aggregatedPoints[idx];
                  final rec = p.representativeRecord;
                  final sourceLabel = p.hasGovData
                      ? 'Government Market Data (AGMARKNET)'
                      : 'Prototype Estimate';
                  return LineTooltipItem(
                    '${p.fullLabel}\n'
                    '${rec.commodity.isNotEmpty ? rec.commodity : history.commodity}\n'
                    '${rec.market.isNotEmpty ? rec.market : history.market}\n\n'
                    'Avg Modal: ₹${p.avgModal.toInt()}/Q${p.hasGovData ? " (${p.recordCount} reports)" : ""}\n'
                    'Min: ₹${p.minPrice.toInt()}/Q\n'
                    'Max: ₹${p.maxPrice.toInt()}/Q\n\n'
                    'Source:\n$sourceLabel',
                    const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 6),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: modalColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '● Government data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: modalColor, width: 2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '○ Prototype estimate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  aggregatedPoints.any((p) => p.hasGovData) &&
                          aggregatedPoints.any((p) => !p.hasGovData)
                      ? 'Government data available for reported months; others show prototype seasonal estimates.'
                      : (aggregatedPoints.any((p) => p.hasGovData)
                          ? 'Government Market Data (data.gov.in / AGMARKNET).'
                          : 'Prototype estimated trend — not government data.'),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Common Container Card for Chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildChartCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color modalColor,
    required Color minColor,
    required Color maxColor,
    required Widget chart,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and badge
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Series Toggles: [ Modal ] [ Min ] [ Max ]
          Row(
            children: [
              Text(
                'Plot Series: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              _SeriesChip(
                label: 'Modal',
                color: modalColor,
                isActive: showModal,
                onTap: onToggleModal,
              ),
              const SizedBox(width: 6),
              _SeriesChip(
                label: 'Min',
                color: minColor,
                isActive: showMin,
                onTap: onToggleMin,
              ),
              const SizedBox(width: 6),
              _SeriesChip(
                label: 'Max',
                color: maxColor,
                isActive: showMax,
                onTap: onToggleMax,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Chart canvas
          SizedBox(
            height: 180,
            child: chart,
          ),

          if (footer != null) footer,
        ],
      ),
    );
  }
}

// â”€â”€â”€ Series Chip Toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SeriesChip extends StatelessWidget {
  const _SeriesChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : AppColors.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? color : AppColors.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Timeline History Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.price,
    required this.isLive,
    required this.isLastAvailable,
    this.lastUpdated,
    required this.onCalculate,
  });

  final MandiPrice price;
  final bool isLive;
  final bool isLastAvailable;
  final String? lastUpdated;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Date: ${price.arrivalDate}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (price.arrivalQuantity != null &&
                    price.arrivalQuantity! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.4),
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
                ],
                const Spacer(),
                Text(
                  '${price.district}${price.district.isNotEmpty ? ", " : ""}${price.state}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Price Grid
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PriceCell(label: 'Min Price', value: price.minPrice),
                    _Divider(),
                    _PriceCell(
                      label: 'Modal Price',
                      value: price.modalPrice,
                      isModal: true,
                    ),
                    _Divider(),
                    _PriceCell(label: 'Max Price', value: price.maxPrice),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DataSourceTag(
                        source: price.source,
                        arrivalDate: price.arrivalDate,
                        lastUpdated: price.sourceUpdatedAt ??
                            price.ingestedAt ??
                            lastUpdated,
                        isLive: isLive,
                        isLastAvailable: isLastAvailable,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onCalculate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calculate,
                                size: 14, color: AppColors.onPrimary),
                            const SizedBox(width: 4),
                            Text(
                              'Calculate Realization',
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
    );
  }
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({
    required this.label,
    required this.value,
    this.isModal = false,
  });

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
              fontSize: isModal ? 16 : 13,
              fontWeight: FontWeight.w800,
              color: isModal ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          Text(
            '/Quintal',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.outlineVariant,
    );
  }
}

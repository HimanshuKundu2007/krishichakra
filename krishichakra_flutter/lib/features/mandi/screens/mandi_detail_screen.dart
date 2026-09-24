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

class MandiDetailScreen extends ConsumerWidget {
  const MandiDetailScreen({
    super.key,
    required this.market,
    required this.commodity,
  });

  final String market;
  final String commodity;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(
      mandiHistoryProvider((commodity: commodity, market: market)),
    );
    ref.invalidate(mandiStatusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(mandiStatusProvider);
    final historyAsync = ref.watch(
      mandiHistoryProvider((commodity: commodity, market: market)),
    );

    final status = statusAsync.asData?.value;
    final isLive = status?.isLive ?? false;
    final isFailed = status?.hasFailedSync ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: 80,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: market.isEmpty ? 'Mandi Detail' : market,
                subtitle: commodity.isEmpty
                    ? 'Government Price History'
                    : '$commodity Price History',
                showBack: true,
                showLiveIndicator: isLive,
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
                    tooltip: 'Refresh Gov History',
                    onPressed: () => _refresh(ref),
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
                  // ── Source & Status Provenance Banner ─────────────────────
                  DataSourceTag(
                    source: status?.source ??
                        'Government Market Data (AGMARKNET / data.gov.in)',
                    lastUpdated: status?.lastSuccessfulSync ?? status?.lastSync,
                    isLive: isLive,
                    isLastAvailable: isFailed,
                    compact: false,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── History Records & Chart ──────────────────────────────
                  historyAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => KcErrorState(
                      message: err.toString(),
                      onRetry: () => _refresh(ref),
                    ),
                    data: (records) {
                      if (records.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          margin:
                              const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 40,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No historical records found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isFailed
                                    ? 'Showing last available government data (0 historical entries for this market).'
                                    : 'No historical arrival data currently synchronized from Agmarknet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Summary Metrics ─────────────────────────────
                          _MandiPriceSummaryStats(records: records),

                          // ── Historical Line Chart ────────────────────────
                          _MandiPriceHistoryChart(records: records),

                          // ── Timeline List Header ─────────────────────────
                          Row(
                            children: [
                              Icon(Icons.timeline_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Arrival Price Timeline (${records.length} records)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // ── Timeline Cards ───────────────────────────────
                          ...records.map(
                            (rec) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _HistoryCard(
                                price: rec,
                                isLive: isLive,
                                isLastAvailable: isFailed,
                                lastUpdated: status?.lastSuccessfulSync ??
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

class _MandiPriceSummaryStats extends StatelessWidget {
  const _MandiPriceSummaryStats({required this.records});

  final List<MandiPrice> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    double minP = double.infinity;
    double maxP = -double.infinity;
    double sumP = 0;
    double totalArrivals = 0;
    bool hasArrivalQty = false;

    for (final r in records) {
      if (r.minPrice < minP) minP = r.minPrice;
      if (r.maxPrice > maxP) maxP = r.maxPrice;
      sumP += r.modalPrice;
      if (r.arrivalQuantity != null && r.arrivalQuantity! > 0) {
        totalArrivals += r.arrivalQuantity!;
        hasArrivalQty = true;
      }
    }

    final avgP = records.isNotEmpty ? sumP / records.length : 0.0;
    final latestP = records.first.modalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Government Market Price Summary',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatItem(
                label: 'Latest Modal',
                value: formatInr(latestP),
                color: AppColors.primary,
              ),
              _StatDivider(),
              _StatItem(
                label: 'Period Min',
                value: formatInr(minP),
                color: AppColors.onSurface,
              ),
              _StatDivider(),
              _StatItem(
                label: 'Period Max',
                value: formatInr(maxP),
                color: AppColors.onSurface,
              ),
              _StatDivider(),
              _StatItem(
                label: hasArrivalQty ? 'Total Arrivals' : 'Avg Modal',
                value: hasArrivalQty
                    ? '${totalArrivals.toInt()} Qtl'
                    : formatInr(avgP),
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

class _MandiPriceHistoryChart extends StatelessWidget {
  const _MandiPriceHistoryChart({required this.records});

  final List<MandiPrice> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    // Sort chronologically (oldest to newest)
    final sorted = List<MandiPrice>.from(records)
      ..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));

    final spots = <FlSpot>[];
    double minVal = double.infinity;
    double maxVal = -double.infinity;

    for (int i = 0; i < sorted.length; i++) {
      final p = sorted[i].modalPrice;
      spots.add(FlSpot(i.toDouble(), p));
      if (p < minVal) minVal = p;
      if (p > maxVal) maxVal = p;
    }

    if (minVal == double.infinity) {
      minVal = 0;
      maxVal = 100;
    }
    final range = maxVal - minVal;
    final yMargin =
        range > 0 ? range * 0.2 : (minVal > 0 ? minVal * 0.15 : 10.0);
    final minY = (minVal - yMargin).clamp(0.0, double.infinity);
    final maxY = maxVal + yMargin;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Modal Price Movement (₹/Q)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${sorted.length} Point${sorted.length > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: range > 0 ? range / 3 : 100,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: AppColors.outlineVariant.withOpacity(0.4),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        if (sorted.length > 6 &&
                            idx % (sorted.length ~/ 4) != 0 &&
                            idx != sorted.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final d = sorted[idx].arrivalDate;
                        final parts = d.split('-');
                        final label = parts.length >= 3
                            ? '${parts[2]}/${parts[1]}'
                            : d;
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
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: sorted.length > 2,
                    curveSmoothness: 0.2,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.surfaceContainerLowest,
                        strokeWidth: 2,
                        strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.25),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        if (idx < 0 || idx >= sorted.length) return null;
                        final rec = sorted[idx];
                        return LineTooltipItem(
                          '${rec.arrivalDate}\nModal: ₹${rec.modalPrice.toInt()}/Q\nMin: ₹${rec.minPrice.toInt()} • Max: ₹${rec.maxPrice.toInt()}',
                          const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            color: Colors.black.withOpacity(0.04),
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
                ],
                const Spacer(),
                Text(
                  '${price.district}, ${price.state}',
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
                    DataSourceTag(
                      source: price.source,
                      arrivalDate: price.arrivalDate,
                      lastUpdated: price.sourceUpdatedAt ??
                          price.ingestedAt ??
                          lastUpdated,
                      isLive: isLive,
                      isLastAvailable: isLastAvailable,
                      compact: true,
                    ),
                    const Spacer(),
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

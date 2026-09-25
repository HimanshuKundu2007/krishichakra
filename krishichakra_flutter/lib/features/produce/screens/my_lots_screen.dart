import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/repositories/farmer_repository.dart';
import '../../../core/repositories/produce_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';

class MyLotsScreen extends ConsumerWidget {
  const MyLotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmerId = ref.watch(currentFarmerIdProvider) ?? 1;
    final lotsAsync = ref.watch(farmerLotsProvider(farmerId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(farmerLotsProvider(farmerId));
          await ref.read(farmerLotsProvider(farmerId).future);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: true,
              snap: true,
              expandedHeight: AppSpacing.headerHeight,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: 'My Harvest Lots',
                subtitle: lotsAsync.when(
                  data: (lots) => '${lots.length} Lots Registered',
                  loading: () => 'Loading lots...',
                  error: (_, __) => 'Connection error',
                ),
                showLiveIndicator: true,
              ),
              toolbarHeight: AppSpacing.headerHeight,
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: lotsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text(
                            'Fetching harvest lots from server...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 40,
                          color: AppColors.onErrorContainer,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to Load Lots',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(farmerLotsProvider(farmerId));
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onErrorContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (lots) {
                  if (lots.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Harvest Lots Listed Yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Register your harvest produce to get instant AI grading, mandi price intelligence, and matching buyers.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.push(AppRoutes.produceListing),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('List First Lot'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lot = lots[index];
                        final emoji = _getCommodityEmoji(lot.commodity);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => context.push(
                              '${AppRoutes.buyerMatches}?lot_id=${lot.id}',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: _LotCard(
                              lotId: '${lot.id}',
                              commodity: '$emoji ${lot.commodity}',
                              qty:
                                  '${lot.quantityQuintal.toStringAsFixed(1)} Quintals • Grade ${lot.grade ?? "A"}',
                              status: lot.status,
                              offers: 'View Buyers →',
                              statusColor: _getStatusColor(lot.status),
                            ),
                          ),
                        );
                      },
                      childCount: lots.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.produceListing),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add New Lot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static String _getCommodityEmoji(String commodity) {
    final lower = commodity.toLowerCase();
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('soybean') || lower.contains('soya')) return '🌱';
    if (lower.contains('wheat')) return '🌾';
    if (lower.contains('cotton')) return '☁️';
    if (lower.contains('potato')) return '🥔';
    if (lower.contains('rice') || lower.contains('paddy')) return '🍚';
    return '📦';
  }

  static Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('bid') || lower.contains('available') || lower.contains('listed')) {
      return AppColors.secondary;
    }
    if (lower.contains('transit')) {
      return AppColors.tertiary;
    }
    return AppColors.primary;
  }
}

class _LotCard extends StatelessWidget {
  const _LotCard({
    required this.lotId,
    required this.commodity,
    required this.qty,
    required this.status,
    required this.offers,
    required this.statusColor,
  });

  final String lotId;
  final String commodity;
  final String qty;
  final String status;
  final String offers;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                commodity.substring(0, 2),
                style: const TextStyle(fontSize: 24),
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
                      'Lot #$lotId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  qty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      offers,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
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

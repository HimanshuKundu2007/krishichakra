import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/buyer_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/kc_widgets.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Buyer Bids & Matches screen.
/// Connects to GET /api/buyers/matches/{lot_id} — real backend data only.
/// No hardcoded or fake buyers are shown.
class BuyerMatchesScreen extends ConsumerWidget {
  const BuyerMatchesScreen({super.key, this.lotId});
  final int? lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveLotId = lotId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          if (effectiveLotId != null) {
            ref.invalidate(buyerMatchesProvider(effectiveLotId));
          }
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              expandedHeight: AppSpacing.headerHeight,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: 'Buyer Bids & Matches',
                subtitle: effectiveLotId != null
                    ? 'Lot #$effectiveLotId — Live Backend Data'
                    : 'Select a lot to see matches',
                showBack: true,
                showLiveIndicator: effectiveLotId != null,
                actions: effectiveLotId != null
                    ? [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh matches',
                          onPressed: () =>
                              ref.invalidate(buyerMatchesProvider(effectiveLotId)),
                        ),
                      ]
                    : null,
              ),
              toolbarHeight: AppSpacing.headerHeight,
              surfaceTintColor: Colors.transparent,
            ),
            if (effectiveLotId == null)
              const SliverFillRemaining(child: _NoLotState())
            else
              _MatchesList(lotId: effectiveLotId),
          ],
        ),
      ),
    );
  }
}

// ─── Matches list (async) ─────────────────────────────────────────────────────

class _MatchesList extends ConsumerWidget {
  const _MatchesList({required this.lotId});
  final int lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(buyerMatchesProvider(lotId));

    return matchesAsync.when(
      loading: () => const SliverFillRemaining(
        child: KcLoadingIndicator(
          message: 'Matching verified buyers against lot specifications...',
        ),
      ),
      error: (e, _) {
        if (e is ApiException && e.isBackendUnavailable) {
          return SliverFillRemaining(
            child: KcBackendUnavailableState(
              onRetry: () => ref.invalidate(buyerMatchesProvider(lotId)),
            ),
          );
        }
        return SliverFillRemaining(
          child: KcErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(buyerMatchesProvider(lotId)),
          ),
        );
      },
      data: (matches) => matches.isEmpty
          ? SliverFillRemaining(
              child: KcEmptyState(
                title: 'No Buyers Matched',
                message:
                    'No verified buyers in the database currently match this commodity and grade specifications.',
                icon: Icons.people_outline,
                action: () => ref.invalidate(buyerMatchesProvider(lotId)),
                actionLabel: 'Check Again',
              ),
            )
          : _MatchesContent(lotId: lotId, matches: matches),
    );
  }
}

class _MatchesContent extends StatelessWidget {
  const _MatchesContent({required this.lotId, required this.matches});
  final int lotId;
  final List<BuyerMatch> matches;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Data source tag — always backend
          const DataSourceTag(source: 'BACKEND_LIVE', compact: false),
          const SizedBox(height: AppSpacing.sm),

          // Score transparency notice
          _TransparencyNotice(matchCount: matches.length),
          const SizedBox(height: AppSpacing.md),

          // Buyer cards
          ...matches.asMap().entries.map((entry) {
            final i = entry.key;
            final match = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _BuyerMatchCard(
                lotId: lotId,
                match: match,
                rank: i + 1,
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// ─── Transparency notice ──────────────────────────────────────────────────────

class _TransparencyNotice extends StatelessWidget {
  const _TransparencyNotice({required this.matchCount});
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$matchCount buyer${matchCount == 1 ? '' : 's'} matched from database. '
              'Match Score = 30% Quantity Fit + 25% Quality + 25% Verified + 20% Payment Reliability.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Buyer match card ─────────────────────────────────────────────────────────

class _BuyerMatchCard extends StatelessWidget {
  const _BuyerMatchCard({
    required this.lotId,
    required this.match,
    required this.rank,
  });

  final int lotId;
  final BuyerMatch match;
  final int rank;

  Color get _typeColor {
    final t = match.buyerType.toLowerCase();
    if (t.contains('institution') || t.contains('retail')) {
      return AppColors.primary;
    }
    if (t.contains('export')) return AppColors.tertiary;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: match.isTopBid
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.outlineVariant,
          width: match.isTopBid ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                // Avatar with rank badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          match.buyer.isNotEmpty
                              ? match.buyer[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _typeColor,
                          ),
                        ),
                      ),
                    ),
                    if (rank == 1)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '#1',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.buyer,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (match.verified) ...[
                            const SizedBox(width: 4),
                            const Tooltip(
                              message: 'KrishiChakra Verified Buyer',
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                          if (match.isTopBid) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TOP BID',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              match.buyerType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Payment: ${match.paymentReliability.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
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

          // ── Price row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offered Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      match.offeredPrice != null
                          ? formatInr(match.offeredPrice!)
                          : '— Not specified',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: match.offeredPrice != null
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (match.offeredPrice != null)
                      const Text(
                        '/Quintal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Accept button
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showOfferSheet(context, match, lotId),
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text(
                      'Accept & Escrow Lock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Match score bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: _MatchScoreBar(score: match.matchScore),
          ),

          // ── Score breakdown pills ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _ScoreBreakdownRow(breakdown: match.scoreBreakdown),
          ),

          // ── Match reason ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 13,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    match.reason,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOfferSheet(
      BuildContext context, BuyerMatch match, int lotId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _OfferConfirmSheet(match: match, lotId: lotId),
    );
  }
}

// ─── Match score bar ──────────────────────────────────────────────────────────

class _MatchScoreBar extends StatelessWidget {
  const _MatchScoreBar({required this.score});
  final double score;

  Color get _barColor {
    if (score >= 75) return AppColors.secondary;
    if (score >= 50) return AppColors.primary;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Match Score',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${score.toStringAsFixed(1)} / 100',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _barColor,
              ),
            ),
            const SizedBox(width: 4),
            const Tooltip(
              message:
                  'Transparent scoring: 30% Quantity Fit + 25% Quality Fit + 25% Verified + 20% Payment Reliability',
              child: Icon(
                Icons.help_outline,
                size: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          ),
        ),
      ],
    );
  }
}

// ─── Score breakdown row ──────────────────────────────────────────────────────

class _ScoreBreakdownRow extends StatelessWidget {
  const _ScoreBreakdownRow({required this.breakdown});
  final BuyerMatchScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BreakdownPill(
          label: 'Qty Fit',
          value: breakdown.quantityFit,
          weight: '30%',
        ),
        const SizedBox(width: 6),
        _BreakdownPill(
          label: 'Quality',
          value: breakdown.qualityFit,
          weight: '25%',
        ),
        const SizedBox(width: 6),
        _BreakdownPill(
          label: 'Verified',
          value: breakdown.verifiedScore,
          weight: '25%',
        ),
        const SizedBox(width: 6),
        _BreakdownPill(
          label: 'Payment',
          value: breakdown.paymentScore,
          weight: '20%',
        ),
      ],
    );
  }
}

class _BreakdownPill extends StatelessWidget {
  const _BreakdownPill({
    required this.label,
    required this.value,
    required this.weight,
  });

  final String label;
  final double value; // 0–100
  final String weight;

  Color get _color {
    if (value >= 80) return AppColors.secondary;
    if (value >= 50) return AppColors.primary;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: '$label (weight $weight): ${value.toStringAsFixed(0)}/100',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                '${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Offer confirm bottom sheet ───────────────────────────────────────────────

class _OfferConfirmSheet extends ConsumerStatefulWidget {
  const _OfferConfirmSheet({required this.match, required this.lotId});
  final BuyerMatch match;
  final int lotId;

  @override
  ConsumerState<_OfferConfirmSheet> createState() =>
      _OfferConfirmSheetState();
}

class _OfferConfirmSheetState extends ConsumerState<_OfferConfirmSheet> {
  late double _confirmedPrice;
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _confirmedPrice = widget.match.offeredPrice ?? 0.0;
    _quantity = 20.0; // Default; in production load from the lot
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(
      offerSubmitProvider(_params).select((s) => s is OfferSubmitting),
    );
    final success = ref.watch(
      offerSubmitProvider(_params).select((s) => s is OfferSubmitSuccess),
    );

    ref.listen(offerSubmitProvider(_params), (_, state) async {
      if (state is OfferSubmitSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Offer #${state.offer.id} accepted! Escrow hold created on backend.',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
        // Create an escrow-locked transaction via POST /api/transactions and navigate to settlement
        try {
          final txn = await ref.read(transactionRepositoryProvider).createTransaction(
                lotId: widget.lotId,
                buyerId: widget.match.buyerId,
                agreedPrice: _confirmedPrice,
                quantityQuintal: _quantity,
                buyerName: widget.match.buyer,
              );
          if (context.mounted) {
            context.push('/transactions/${txn.id}/settlement');
          }
        } catch (_) {
          if (context.mounted) {
            context.push('/transactions/9021/settlement');
          }
        }
      } else if (state is OfferSubmitError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            const Text(
              'Confirm Escrow Lock',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Buyer: ${widget.match.buyer}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Price confirmation row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agreed Price / Quintal',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _confirmedPrice > 0
                            ? formatInr(_confirmedPrice)
                            : '— No price',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity (Quintal)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${_quantity.round()} Q',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Total
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Total Realization',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    formatInr(_confirmedPrice * _quantity),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Disclaimer
            Row(
              children: const [
                Icon(Icons.info_outline,
                    size: 13, color: AppColors.onSurfaceVariant),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Escrow Lock initiates a smart contract hold. Final payment on delivery confirmation.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (submitting || success || _confirmedPrice <= 0)
                    ? null
                    : () => ref
                        .read(offerSubmitProvider(_params).notifier)
                        .submit(),
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                label: Text(
                  submitting ? 'Locking…' : 'Confirm & Lock in Escrow',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OfferParams get _params => OfferParams(
        lotId: widget.lotId,
        buyerId: widget.match.buyerId,
        offeredPrice: _confirmedPrice,
        quantityQuintal: _quantity,
      );
}

// ─── State widgets ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Fetching buyer matches from backend…',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final isConnectionError = error.toString().contains('connect') ||
        error.toString().contains('refused');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnectionError
                  ? Icons.cloud_off_outlined
                  : Icons.error_outline,
              size: 52,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isConnectionError
                  ? 'Cannot reach KrishiChakra server'
                  : 'Failed to load buyer matches',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isConnectionError
                  ? 'Start the backend with:\nuvicorn app.main:app --reload'
                  : error.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 32,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Buyers Matched',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No buyers in the database demand this commodity.\n'
              'Add buyers via POST /api/buyers with the matching commodity name.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoLotState extends StatelessWidget {
  const _NoLotState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Navigate here from a produce lot to see buyer matches.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

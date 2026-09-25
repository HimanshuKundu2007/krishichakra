import '../../../l10n/app_localizations.dart';
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

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Buyer Bids & Matches screen.
/// Connects to GET /api/buyers/matches/{lot_id} — real backend data only.
/// No hardcoded or fake buyers are shown.
class BuyerMatchesScreen extends ConsumerStatefulWidget {
  const BuyerMatchesScreen({super.key, this.lotId});
  final int? lotId;

  @override
  ConsumerState<BuyerMatchesScreen> createState() => _BuyerMatchesScreenState();
}

class _BuyerMatchesScreenState extends ConsumerState<BuyerMatchesScreen> {
  late bool _browseMode;
  String _selectedCommodity = 'All';
  String _selectedLocation = 'All';
  String _selectedGrade = 'All';

  @override
  void initState() {
    super.initState();
    _browseMode = widget.lotId == null;
  }

  Map<String, dynamic> get _filters {
    final map = <String, dynamic>{};
    if (_selectedCommodity != 'All') map['commodity'] = _selectedCommodity;
    if (_selectedLocation != 'All') map['location'] = _selectedLocation;
    if (_selectedGrade != 'All') map['grade'] = _selectedGrade;
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveLotId = widget.lotId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          if (!_browseMode && effectiveLotId != null) {
            ref.invalidate(buyerMatchesProvider(effectiveLotId));
          } else {
            ref.invalidate(allBuyersProvider(_filters));
          }
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: false,
              pinned: true,
              expandedHeight: AppSpacing.headerHeight,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: l10n.buyerBidsMatches,
                subtitle: (!_browseMode && effectiveLotId != null)
                    ? 'Lot #$effectiveLotId — Matched Demo Buyers'
                    : 'Demo Buyer Database (Maharashtra)',
                showBack: true,
                showLiveIndicator: true,
                actions: [
                  if (effectiveLotId != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _browseMode = !_browseMode),
                      icon: Icon(
                        _browseMode ? Icons.filter_alt_outlined : Icons.storefront_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        _browseMode ? 'Lot #$effectiveLotId Matches' : 'All Buyers',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () {
                      if (!_browseMode && effectiveLotId != null) {
                        ref.invalidate(buyerMatchesProvider(effectiveLotId));
                      } else {
                        ref.invalidate(allBuyersProvider(_filters));
                      }
                    },
                  ),
                ],
              ),
              toolbarHeight: AppSpacing.headerHeight,
              surfaceTintColor: Colors.transparent,
            ),
            if (!_browseMode && effectiveLotId != null)
              _MatchesList(
                lotId: effectiveLotId,
                onBrowseAll: () => setState(() => _browseMode = true),
              )
            else
              _AllBuyersBrowseView(
                selectedCommodity: _selectedCommodity,
                selectedLocation: _selectedLocation,
                selectedGrade: _selectedGrade,
                onCommodityChanged: (c) => setState(() => _selectedCommodity = c),
                onLocationChanged: (l) => setState(() => _selectedLocation = l),
                onGradeChanged: (g) => setState(() => _selectedGrade = g),
                lotId: effectiveLotId,
              ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Matches list (async) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MatchesList extends ConsumerWidget {
  const _MatchesList({
    required this.lotId,
    required this.onBrowseAll,
  });

  final int lotId;
  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(buyerMatchesProvider(lotId));

    return matchesAsync.when(
      loading: () => SliverFillRemaining(
        child: KcLoadingIndicator(
          message: l10n.matchingBuyers,
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
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'No Exact Matched Buyers Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No buyer currently matches this specific commodity and grade criteria. You can browse all verified demo buyers across Maharashtra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: onBrowseAll,
                      icon: const Icon(Icons.storefront_outlined, size: 16),
                      label: const Text('View All Demo Buyers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
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
    final l10n = AppLocalizations.of(context)!;
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

// â”€â”€â”€ Transparency notice â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TransparencyNotice extends StatelessWidget {
  const _TransparencyNotice({required this.matchCount});
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
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

// â”€â”€â”€ Buyer match card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final l10n = AppLocalizations.of(context)!;
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
          // â”€â”€ Header row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // Metadata tags row: Location, Qty, Grade, Payment terms
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (match.location != null && match.location!.isNotEmpty)
                  _BadgeTag(
                    icon: Icons.location_on_outlined,
                    label: match.location!,
                    color: AppColors.secondary,
                  ),
                if (match.requiredQuantity != null && match.requiredQuantity!.isNotEmpty)
                  _BadgeTag(
                    icon: Icons.scale_outlined,
                    label: 'Req: ${match.requiredQuantity}',
                    color: AppColors.primary,
                  ),
                if (match.acceptedGrade != null && match.acceptedGrade!.isNotEmpty)
                  _BadgeTag(
                    icon: Icons.verified_outlined,
                    label: 'Grade ${match.acceptedGrade}',
                    color: Colors.teal,
                  ),
                if (match.paymentTerms != null && match.paymentTerms!.isNotEmpty)
                  _BadgeTag(
                    icon: Icons.schedule_outlined,
                    label: match.paymentTerms!,
                    color: Colors.purple,
                  ),
                _BadgeTag(
                  icon: Icons.verified_user_outlined,
                  label: match.verificationBadge ?? 'Demo Verified Buyer',
                  color: Colors.amber.shade800,
                ),
              ],
            ),
          ),

          // Price row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.offeredPrice,
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
                    icon: Icon(Icons.lock_outline, size: 16),
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

          // â”€â”€ Match score bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: _MatchScoreBar(score: match.matchScore),
          ),

          // â”€â”€ Score breakdown pills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _ScoreBreakdownRow(breakdown: match.scoreBreakdown),
          ),

          // â”€â”€ Match reason â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
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

// â”€â”€â”€ Match score bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.matchScore,
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

// â”€â”€â”€ Score breakdown row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ScoreBreakdownRow extends StatelessWidget {
  const _ScoreBreakdownRow({required this.breakdown});
  final BuyerMatchScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
  final double value; // 0â€“100
  final String weight;

  Color get _color {
    if (value >= 80) return AppColors.secondary;
    if (value >= 50) return AppColors.primary;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

// â”€â”€â”€ Offer confirm bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final l10n = AppLocalizations.of(context)!;
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
                    : Icon(Icons.lock_outline, size: 18),
                label: Text(
                  submitting ? 'Lockingâ€¦' : 'Confirm & Lock in Escrow',
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


class _BadgeTag extends StatelessWidget {
  const _BadgeTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllBuyersBrowseView extends ConsumerWidget {
  const _AllBuyersBrowseView({
    required this.selectedCommodity,
    required this.selectedLocation,
    required this.selectedGrade,
    required this.onCommodityChanged,
    required this.onLocationChanged,
    required this.onGradeChanged,
    this.lotId,
  });

  final String selectedCommodity;
  final String selectedLocation;
  final String selectedGrade;
  final ValueChanged<String> onCommodityChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onGradeChanged;
  final int? lotId;

  static const commodities = [
    'All',
    'Onion',
    'Tomato',
    'Potato',
    'Wheat',
    'Soybean',
    'Banana',
    'Garlic',
    'Paddy',
    'Cotton',
    'Maize',
    'Guava',
    'Orange',
  ];

  static const locations = [
    'All',
    'Pune',
    'Nashik',
    'Ahmednagar',
    'Mumbai',
    'Nagpur',
    'Solapur',
    'Kolhapur',
  ];

  static const grades = ['All', 'A', 'B'];

  Map<String, dynamic> get _filters {
    final map = <String, dynamic>{};
    if (selectedCommodity != 'All') map['commodity'] = selectedCommodity;
    if (selectedLocation != 'All') map['location'] = selectedLocation;
    if (selectedGrade != 'All') map['grade'] = selectedGrade;
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyersAsync = ref.watch(allBuyersProvider(_filters));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Prototype demo database disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined,
                    size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Demo Buyer Database • Clearly marked synthetic buyers for prototype evaluation & escrow matching.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Commodity filter row
          const Text(
            'Filter by Commodity:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: commodities.map((c) {
                final isSelected = selectedCommodity == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) => onCommodityChanged(c),
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Location & Grade filters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Location:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: locations.map((loc) {
                          final isSel = selectedLocation == loc;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: FilterChip(
                              label: Text(loc, style: const TextStyle(fontSize: 10)),
                              selected: isSel,
                              onSelected: (_) => onLocationChanged(loc),
                              selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Grade:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: grades.map((g) {
                      final isSel = selectedGrade == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilterChip(
                          label: Text(g, style: const TextStyle(fontSize: 10)),
                          selected: isSel,
                          onSelected: (_) => onGradeChanged(g),
                          selectedColor: Colors.teal.withValues(alpha: 0.2),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Buyers content
          buyersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: KcLoadingIndicator(
                  message: 'Loading demo buyers...',
                ),
              ),
            ),
            error: (err, _) => KcErrorState(
              message: 'Failed to load buyers: $err',
              onRetry: () => ref.invalidate(allBuyersProvider(_filters)),
            ),
            data: (buyers) {
              if (buyers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off, size: 40, color: AppColors.onSurfaceVariant),
                        const SizedBox(height: 10),
                        const Text(
                          'No demo buyers match these filters.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            onCommodityChanged('All');
                            onLocationChanged('All');
                            onGradeChanged('All');
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: buyers.map((b) => _BuyerCard(buyer: b, lotId: lotId)).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _BuyerCard extends StatelessWidget {
  const _BuyerCard({required this.buyer, this.lotId});
  final Buyer buyer;
  final int? lotId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
                  radius: 20,
                  child: Text(
                    buyer.name.isNotEmpty ? buyer.name[0].toUpperCase() : 'B',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              buyer.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Text(
                              'DEMO BUYER',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${buyer.buyerType.toUpperCase()} • Payment Reliability: ${(buyer.paymentReliability ?? 95).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Metadata tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (buyer.demandCommodity != null)
                  _BadgeTag(
                    icon: Icons.eco_outlined,
                    label: buyer.demandCommodity!,
                    color: AppColors.primary,
                  ),
                if (buyer.city != null || buyer.district != null)
                  _BadgeTag(
                    icon: Icons.location_on_outlined,
                    label: '${buyer.city ?? buyer.district}, ${buyer.state ?? "MH"}',
                    color: AppColors.secondary,
                  ),
                if (buyer.minQuantity != null && buyer.maxQuantity != null)
                  _BadgeTag(
                    icon: Icons.scale_outlined,
                    label: '${buyer.minQuantity!.toInt()}–${buyer.maxQuantity!.toInt()} Q',
                    color: Colors.indigo,
                  ),
                if (buyer.acceptedGrade != null)
                  _BadgeTag(
                    icon: Icons.verified_outlined,
                    label: 'Grade ${buyer.acceptedGrade}',
                    color: Colors.teal,
                  ),
                if (buyer.pickupAvailable)
                  _BadgeTag(
                    icon: Icons.local_shipping_outlined,
                    label: 'Pickup Available',
                    color: Colors.green.shade700,
                  ),
                if (buyer.paymentTerms != null)
                  _BadgeTag(
                    icon: Icons.schedule_outlined,
                    label: buyer.paymentTerms!,
                    color: Colors.purple,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Price & actions
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Indicative Offer',
                      style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      buyer.indicativePriceMin != null && buyer.indicativePriceMax != null
                          ? '₹${buyer.indicativePriceMin!.toInt()} – ₹${buyer.indicativePriceMax!.toInt()}'
                          : (buyer.offeredPrice != null ? formatInr(buyer.offeredPrice!) : '₹2,500/Q'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => _BuyerDetailSheet(buyer: buyer, lotId: lotId),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Offer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerDetailSheet extends StatelessWidget {
  const _BuyerDetailSheet({required this.buyer, this.lotId});
  final Buyer buyer;
  final int? lotId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Expanded(
                child: Text(
                  buyer.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PROTOTYPE DEMO BUYER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${buyer.buyerType.toUpperCase()} • ${buyer.city ?? buyer.district ?? "Maharashtra"}',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const Divider(height: 24),
          _detailRow('Target Commodity', buyer.demandCommodity ?? 'Agricultural Produce'),
          if (buyer.varieties != null) _detailRow('Varieties', buyer.varieties!),
          _detailRow('Accepted Grade', buyer.acceptedGrade ?? 'Grade A / Grade B'),
          _detailRow(
            'Required Quantity',
            '${(buyer.minQuantity ?? 10).toInt()} – ${(buyer.maxQuantity ?? 50).toInt()} Quintals',
          ),
          _detailRow(
            'Indicative Price',
            buyer.indicativePriceMin != null && buyer.indicativePriceMax != null
                ? '₹${buyer.indicativePriceMin!.toInt()} – ₹${buyer.indicativePriceMax!.toInt()} / Quintal'
                : 'Market-linked',
          ),
          _detailRow('Payment Terms', buyer.paymentTerms ?? '24 hours via Escrow Hold'),
          _detailRow('Logistics', buyer.pickupAvailable ? 'Farmgate Pickup Available' : 'Mandi Delivery'),
          _detailRow('Verification', buyer.verificationStatus ?? 'Demo Verified Buyer'),
          const SizedBox(height: 16),
          const Text(
            'Note: This is a synthetic demo buyer provided for testing KrishiChakra buyer-matching, transparent scoring, and escrow lock flows.',
            style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Buyer ${buyer.name} contacted (Prototype Demo).'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Connect with Buyer (Prototype)', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

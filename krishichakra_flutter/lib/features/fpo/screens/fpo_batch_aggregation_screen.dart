import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/fpo_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';

class FpoBatchAggregationScreen extends ConsumerStatefulWidget {
  const FpoBatchAggregationScreen({super.key, this.batchId = 1});

  final int batchId;

  @override
  ConsumerState<FpoBatchAggregationScreen> createState() =>
      _FpoBatchAggregationScreenState();
}

class _FpoBatchAggregationScreenState
    extends ConsumerState<FpoBatchAggregationScreen> {
  bool _isDispatching = false;
  String? _dispatchedEwayBill;

  Future<void> _handleDispatch(FpoBatchAggregation aggregation) async {
    if (aggregation.status == 'dispatched') return;
    setState(() => _isDispatching = true);
    try {
      final updated = await ref
          .read(fpoRepositoryProvider)
          .dispatchBatch(aggregation.id);
      setState(() {
        _isDispatching = false;
        _dispatchedEwayBill = updated.ewayBillNumber;
      });
      ref.invalidate(fpoBatchAggregationProvider(widget.batchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(
              'Batch ${aggregation.batchCode} Sealed & Dispatched! e-Way Bill generated.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDispatching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Dispatch failed: $e'),
          ),
        );
      }
    }
  }

  void _showAddLotSheet(BuildContext context, int batchId) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '15');
    String selectedGrade = 'Grade A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Contribute Lot to Batch',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Backend Gatekeeper will evaluate grade against batch specs (Grade A staged, lower grades diverted to APMC).',
                style: TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Farmer Name',
                  hintText: 'e.g. Anand Rao',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.quantityInQuintals,
                  hintText: 'e.g. 15',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Observed Quality Grade',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Grade A', child: Text('Grade A (50mm+ Bulb)')),
                  DropdownMenuItem(
                      value: 'Grade B',
                      child: Text('Grade B (<45mm Bulb - Diverted)')),
                  DropdownMenuItem(
                      value: 'Grade C',
                      child: Text('Grade C (Sub-standard - Diverted)')),
                ],
                onChanged: (v) {
                  if (v != null) setModalState(() => selectedGrade = v);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.add_task),
                  label: const Text(
                    'Submit to Gatekeeper Audit',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final qty = double.tryParse(qtyCtrl.text) ?? 10.0;
                    Navigator.pop(ctx);
                    try {
                      await ref.read(fpoRepositoryProvider).addLotToBatch(
                            batchId,
                            farmerName: nameCtrl.text.trim(),
                            quantityQuintal: qty,
                            grade: selectedGrade,
                            bulbSpec: selectedGrade == 'Grade A'
                                ? '52–58mm bulb'
                                : '<45mm Uniformity',
                            moisturePct: 12.0,
                          );
                      ref.invalidate(
                          fpoBatchAggregationProvider(widget.batchId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text(
                                'Lot processed through backend Gatekeeper quality check!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text('Error adding lot: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFpoDirectorySheet(BuildContext context, int fpoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final membersAsync = ref.watch(fpoMembersProvider(fpoId));
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            builder: (ctx, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FPO Members Directory',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Registered smallholder farmers eligible for bulk pool bonus',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: membersAsync.when(
                      data: (members) {
                        if (members.isEmpty) {
                          return const Center(
                            child: Text(
                              'No registered members found in this FPO.',
                              style: TextStyle(
                                  color: AppColors.onSurfaceVariant),
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollCtrl,
                          itemCount: members.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final m = members[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryContainer
                                    .withOpacity(0.15),
                                child: Text(
                                  m.farmerName?.isNotEmpty == true
                                      ? m.farmerName![0]
                                      : 'F',
                                  style: const TextStyle(
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                m.farmerName ?? 'Farmer Member',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${m.memberCode ?? "ID #FPO-${m.farmerId}"} • ${m.farmerVillage ?? "Hub Zone"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Active Member',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
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

  @override
  Widget build(BuildContext context) {
    final asyncAggregation =
        ref.watch(fpoBatchAggregationProvider(widget.batchId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: asyncAggregation.when(
        data: (agg) => _buildContent(context, agg),
        loading: () => const Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading FPO Batch Aggregation...',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(title: const Text('FPO Aggregation')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load batch: $err',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                        fpoBatchAggregationProvider(widget.batchId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FpoBatchAggregation agg) {
    final l10n = AppLocalizations.of(context)!;
    final isDispatched =
        agg.status == 'dispatched' || _dispatchedEwayBill != null;
    final remainingTonnes =
        ((agg.targetQuantityQuintal - agg.stagedQuantityQuintal) / 10)
            .clamp(0.0, 999.0);
    final targetTonnes = agg.targetQuantityQuintal / 10;
    final stagedTonnes = agg.stagedQuantityQuintal / 10;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          floating: false,
          pinned: true,
          expandedHeight: AppSpacing.headerHeight,
          backgroundColor: Colors.transparent,
          flexibleSpace: KcAppBar(
            title: l10n.fpoBatchAggregation,
            subtitle: agg.fpoName,
            showBack: true,
            actions: [
              IconButton(
                icon: Icon(Icons.group, size: 22),
                tooltip: 'FPO Members',
                onPressed: () => _showFpoDirectorySheet(context, agg.fpoId),
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined, size: 22),
                tooltip: 'Notifications',
                onPressed: () {},
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
              const SizedBox(height: 8),

              // â”€â”€ 1. FPO Brand & Credential Strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildFpoBrandStrip(context, agg),
              const SizedBox(height: 12),

              // â”€â”€ 2. Active Consignment Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildActiveConsignmentCard(agg),
              const SizedBox(height: 14),

              // â”€â”€ 3. Batch Consolidation Progress Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildProgressCard(agg, stagedTonnes, targetTonnes, remainingTonnes),
              const SizedBox(height: 14),

              // â”€â”€ 4. Photo Snapshot of Staging Bay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildStagingBaySnapshot(agg),
              const SizedBox(height: 16),

              // â”€â”€ 5. Member Contributed Lots (Gatekeeper Quality) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildMemberLotsSection(context, agg),
              const SizedBox(height: 16),

              // â”€â”€ 6. Assigned Logistics & Transport â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildLogisticsCard(agg),
              const SizedBox(height: 16),

              // â”€â”€ 7. Financial Ledger Realization (Escrow Protected) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildFinancialLedgerCard(agg),
              const SizedBox(height: 20),

              // â”€â”€ 8. Sticky Bottom Seal & Dispatch Action â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildDispatchSection(agg, isDispatched),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFpoBrandStrip(BuildContext context, FpoBatchAggregation agg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.corporate_fare,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            agg.fpoHubName ?? 'Junnar FPC Hub',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (agg.fpoVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 13,
                                    color: AppColors.onSecondaryContainer),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${agg.totalRegisteredFarmers > 0 ? agg.totalRegisteredFarmers : 412} Smallholders Registered',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (agg.fpoRegistrationNumber != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              agg.fpoRegistrationNumber!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveConsignmentCard(FpoBatchAggregation agg) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    agg.batchCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          agg.status == 'dispatched'
                              ? 'Batch Dispatched'
                              : 'Pooling Active • ${agg.fillPercentage.toStringAsFixed(0)}% Filled',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.volume_up,
                    color: AppColors.primaryContainer),
                tooltip: 'Audio summary',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Consignment ${agg.batchCode}: ${agg.commodity}, ${(agg.stagedQuantityQuintal / 10).toStringAsFixed(1)} Tonnes staged at hub.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco,
                        size: 15, color: AppColors.onTertiaryFixed),
                    const SizedBox(width: 4),
                    Text(
                      agg.commodity,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onTertiaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${agg.targetGrade} Export Spec',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    FpoBatchAggregation agg,
    double stagedTonnes,
    double targetTonnes,
    double remainingTonnes,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consolidation Target',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '${stagedTonnes.toStringAsFixed(1)} / ${targetTonnes.toStringAsFixed(1)} T',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
              children: [
                const TextSpan(text: 'Remaining: '),
                TextSpan(
                  text:
                      '${remainingTonnes.toStringAsFixed(1)} Tonnes (${agg.remainingCrates} Crates)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const TextSpan(text: ' to trigger batch seal'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (agg.fillPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0 Tonnes',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
              Text(
                '${agg.fillPercentage.toStringAsFixed(1)}% Complete',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryContainer,
                ),
              ),
              Text('${targetTonnes.toStringAsFixed(1)} Tonnes Max',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),

          // Bulk Institutional Bonus Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up,
                      size: 20, color: AppColors.onSecondaryContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Institutional Bonus Unlocked: +₹${agg.institutionalBonusPerQ?.toInt() ?? 180}/Q',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        agg.bonusExplanation ??
                            'Consolidated volume unlocks direct contract with Sahyadri Processing at ₹2,650/Q flat vs ₹2,470/Q spot market average.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagingBaySnapshot(FpoBatchAggregation agg) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withOpacity(0.85),
            AppColors.primary.withOpacity(0.95),
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Live Camera Gate 2',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.videocam, color: Colors.white70, size: 18),
            ],
          ),
          Row(
            children: [
              Icon(Icons.inventory_2,
                  color: AppColors.secondaryFixed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  agg.stagingBayInfo ??
                      'Junnar Staging Bay: ${agg.totalCratesChecked} Crates Checked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberLotsSection(
      BuildContext context, FpoBatchAggregation agg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Member Contributed Lots',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${agg.lots.length} Farmers',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gavel,
                          size: 13, color: AppColors.onSecondaryContainer),
                      SizedBox(width: 4),
                      Text(
                        'Gatekeeper Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: AppColors.primaryContainer),
                  tooltip: 'Contribute lot',
                  onPressed: () => _showAddLotSheet(context, agg.id),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...agg.lots.map((lot) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildLotCard(lot),
            )),
      ],
    );
  }

  Widget _buildLotCard(FpoBatchLot lot) {
    final initials = lot.farmerName
        .split(' ')
        .map((s) => s.isNotEmpty ? s[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: lot.isStaged
                        ? AppColors.surfaceContainer
                        : AppColors.tertiaryFixed,
                    child: Text(
                      initials.isNotEmpty ? initials : 'FM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: lot.isStaged
                            ? AppColors.primaryContainer
                            : AppColors.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.farmerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        lot.memberCode ?? 'Member ID',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lot.isStaged
                      ? AppColors.secondaryContainer
                      : AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      lot.isStaged ? Icons.check_circle : Icons.alt_route,
                      size: 13,
                      color: lot.isStaged
                          ? AppColors.onSecondaryContainer
                          : AppColors.onTertiaryFixed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lot.isStaged ? 'Staged at Hub' : 'Diverted to APMC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: lot.isStaged
                            ? AppColors.onSecondaryContainer
                            : AppColors.onTertiaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Volume & Spec',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant)),
                      Text(
                        '${lot.quantityQuintal.toInt()} Q • ${lot.grade}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (lot.bulbSpec != null)
                        Text(lot.bulbSpec!,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.isStaged
                            ? 'Quality Sensor Check'
                            : 'Diversion Route',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant),
                      ),
                      if (lot.isStaged) ...[
                        Text(
                          '${lot.moisturePct ?? 12.0}% Moisture',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        Text(
                          '${lot.foreignRotPct?.toInt() ?? 0}% Foreign Rot',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          lot.diversionRoute ?? 'Local APMC Yard',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (lot.isStaged && lot.cratesCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.qr_code_2,
                        size: 16, color: AppColors.primaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      '${lot.cratesCount} Crates Tagged (${lot.qrTagRange ?? ""})',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'QR manifests verified for ${lot.farmerName}: crates staged in Bay #2.'),
                      ),
                    );
                  },
                  child: const Text('Trace Crates',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
          if (lot.isDiverted && lot.gatekeeperNote != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                  children: [
                    const TextSpan(
                      text: 'Gatekeeper Note: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface),
                    ),
                    TextSpan(text: lot.gatekeeperNote!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsCard(FpoBatchAggregation agg) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned Logistics & Transport',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  agg.dockBay ?? 'Dock Bay #2',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            agg.transporterVehicle ?? '10-Tonne Eicher Pro',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            agg.transporterNumber ?? 'MH-14-AZ-8821',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Driver: ${agg.transporterDriver ?? "Verified Driver"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.pin_drop,
                              size: 13, color: AppColors.primaryContainer),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              agg.destination ??
                                  'Sahyadri Agro Processing Plant, Dindori',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildFinancialLedgerCard(FpoBatchAggregation agg) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Ledger Realization',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.shield, size: 14, color: AppColors.secondary),
                  SizedBox(width: 3),
                  Text(
                    'Escrow Protected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _ledgerRow('Total Master Batch Commercial Value',
                    '₹${agg.ledger.commercialValue.toInt()}'),
                const SizedBox(height: 6),
                _ledgerRow(
                  'Direct Farmer Payout Realization',
                  '₹${agg.ledger.farmerPayout.toInt()}',
                  isHighlight: true,
                ),
                const SizedBox(height: 6),
                _ledgerRow('FPO Operational Handling Margin (2%)',
                    '₹${agg.ledger.fpoMargin.toInt()}'),
                const SizedBox(height: 6),
                _ledgerRow('Freight & Toll Surcharge',
                    '₹${agg.ledger.freightSurcharge.toInt()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow(String title, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isHighlight
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 14 : 12,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
            color:
                isHighlight ? AppColors.primaryContainer : AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchSection(
      FpoBatchAggregation agg, bool isDispatched) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDispatched
                  ? AppColors.secondary
                  : AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isDispatched || _isDispatching
                ? null
                : () => _handleDispatch(agg),
            child: _isDispatching
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Generating e-Way Manifest...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDispatched ? Icons.check_circle : Icons.verified,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDispatched
                            ? 'Batch ${agg.batchCode} Sealed & Dispatched'
                            : 'Seal Master Batch & Dispatch Order',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isDispatched) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isDispatched
              ? 'e-Way Bill: ${agg.ewayBillNumber ?? _dispatchedEwayBill ?? "EWB-MH-VERIFIED"} • Escrow Payout Triggered'
              : 'Automated e-Way Bill, Tax Invoice & Master QR Manifest generated on dispatch.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

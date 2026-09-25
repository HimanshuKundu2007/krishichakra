import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_widgets.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});
  final int transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _isUpdatingPayment = false;

  Future<void> _changePaymentStatus(String targetStatus) async {
    setState(() => _isUpdatingPayment = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.updatePaymentStatus(widget.transactionId, targetStatus);
      ref.invalidate(transactionDetailProvider(widget.transactionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment status updated to ${targetStatus.toUpperCase()} on backend.',
            ),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txnAsync = ref.watch(transactionDetailProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionDetailProvider(widget.transactionId));
          await ref.read(transactionDetailProvider(widget.transactionId).future);
        },
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
                title: 'Transaction #LOT-${widget.transactionId}',
                subtitle: 'Escrow Status • Consignment Audit',
                showBack: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh Transaction',
                    onPressed: () => ref.invalidate(
                      transactionDetailProvider(widget.transactionId),
                    ),
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
                  txnAsync.when(
                    data: (txn) => _buildBody(context, txn),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: KcLoadingIndicator(
                        message: 'Verifying escrow & settlement audit...',
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: KcBackendUnavailableState(
                        message: 'Failed to load transaction audit: $err',
                        onRetry: () => ref.invalidate(
                          transactionDetailProvider(widget.transactionId),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionRecord txn) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment Status Control Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Backend Payment Status Controller',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isUpdatingPayment)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildStatusChip('pending', txn.isPending, Colors.amber.shade800),
                  _buildStatusChip('paid', txn.isPaid, AppColors.secondary),
                  _buildStatusChip('failed', txn.isFailed, AppColors.error),
                  _buildStatusChip('disputed', txn.isDisputed, Colors.deepOrange),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Escrow status card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: txn.isPaid
                ? AppColors.primaryContainer
                : (txn.isFailed
                    ? AppColors.errorContainer
                    : (txn.isDisputed
                        ? Colors.orange.shade100
                        : AppColors.primaryContainer)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    txn.isPaid
                        ? Icons.verified_user
                        : (txn.isFailed
                            ? Icons.cancel
                            : (txn.isDisputed
                                ? Icons.gavel
                                : Icons.lock_clock)),
                    color: txn.isPaid
                        ? AppColors.secondaryFixed
                        : (txn.isFailed
                            ? AppColors.error
                            : (txn.isDisputed
                                ? Colors.orange.shade900
                                : AppColors.secondaryFixed)),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.paymentStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: txn.isFailed
                                ? AppColors.onErrorContainer
                                : AppColors.primaryFixedDim,
                          ),
                        ),
                        Text(
                          txn.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: txn.isFailed
                                ? AppColors.error
                                : (txn.isDisputed
                                    ? Colors.orange.shade900
                                    : AppColors.onPrimary),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatInr(txn.totalAmount),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: txn.isFailed
                          ? AppColors.onErrorContainer
                          : AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Milestones progression
              if (txn.milestones.isNotEmpty) ...[
                for (final m in txn.milestones)
                  _MilestoneRow(
                    label: m.title,
                    done: m.isCompleted,
                    isCurrent: m.isCurrent,
                    amount: m.amount,
                  ),
              ] else ...[
                _MilestoneRow(
                    label: 'Weighment & Gate Dispatch', done: true),
                _MilestoneRow(
                    label: 'Weighbridge Verified',
                    done: txn.isPaid || txn.isDisputed),
                _MilestoneRow(
                    label: 'Digital Assay & Release', done: txn.isPaid),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Transaction details
        _DetailRow('Batch Reference', txn.batchCode ?? 'LOT-${txn.id}'),
        _DetailRow('Commodity',
            '${txn.commodity ?? "Tomato"} • ${txn.quantityQuintal.round()} Q'),
        _DetailRow('Buyer',
            '${txn.buyerName ?? "Institutional Buyer"} • Verified'),
        _DetailRow('Agreed Rate', '${formatInr(txn.agreedPrice)}/Q'),
        _DetailRow('Gross Value', formatInr(txn.totalAmount)),
        _DetailRow('Payment State', txn.paymentStatus.toUpperCase()),
        _DetailRow('Invoice', txn.invoiceNumber ?? 'KC-INV-2026-${txn.id}'),
        _DetailRow('UTR Reference', txn.utrNumber ?? 'Pending Settlement'),
        const SizedBox(height: AppSpacing.md),

        // Action 1: View Consignment Settlement & Audit (Stitch screen)
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () =>
                context.push('/transactions/${widget.transactionId}/settlement'),
            icon: Icon(Icons.receipt_long, size: 20),
            label: const Text(
              'View Consignment Settlement & Audit',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Action 2: Raise Dispute
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push('/transactions/${widget.transactionId}/dispute'),
            icon: Icon(Icons.report_problem, size: 20),
            label: const Text(
              'Raise Dispute / Grievance',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildStatusChip(String status, bool isSelected, Color color) {
    return InkWell(
      onTap: _isUpdatingPayment || isSelected
          ? null
          : () => _changePaymentStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.label,
    required this.done,
    this.isCurrent = false,
    this.amount,
  });

  final String label;
  final bool done;
  final bool isCurrent;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : (isCurrent ? Icons.pending : Icons.radio_button_unchecked),
            size: 18,
            color: done ? AppColors.secondaryFixed : AppColors.primaryFixedDim,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                color: done ? AppColors.onPrimary : AppColors.primaryFixedDim,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: 8),
            Text(
              formatInr(amount!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: done ? AppColors.secondaryFixed : AppColors.primaryFixedDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

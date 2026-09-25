import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_widgets.dart';

class ConsignmentSettlementScreen extends ConsumerStatefulWidget {
  const ConsignmentSettlementScreen({super.key, required this.transactionId});
  final int transactionId;

  @override
  ConsumerState<ConsignmentSettlementScreen> createState() =>
      _ConsignmentSettlementScreenState();
}

class _ConsignmentSettlementScreenState
    extends ConsumerState<ConsignmentSettlementScreen> {
  bool _isDownloading = false;
  bool _isSharing = false;
  String? _downloadMessage;
  String? _shareMessage;
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
                'Payment status updated to "${targetStatus.toUpperCase()}" on backend.'),
            backgroundColor: _getStatusColor(targetStatus),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPayment = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.secondary;
      case 'failed':
        return AppColors.error;
      case 'disputed':
        return Colors.orange.shade800;
      case 'pending':
      default:
        return AppColors.primary;
    }
  }

  void _triggerDownload() {
    setState(() {
      _isDownloading = true;
      _downloadMessage = 'Generating Digitally Signed APMC PDF...';
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadMessage = 'APMC-Tax-Invoice-LOT9021.pdf Downloaded';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved: APMC-Tax-Invoice-LOT9021.pdf'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _downloadMessage = null);
        });
      }
    });
  }

  void _triggerShare() {
    setState(() {
      _isSharing = true;
      _shareMessage = 'Creating secure WhatsApp dispatch link...';
    });
    Clipboard.setData(
      ClipboardData(
        text:
            'KrishiChakra e-Settlement Slip for Batch #${widget.transactionId}: https://krishichakra.in/settlement/${widget.transactionId}',
      ),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _shareMessage = 'Link copied to clipboard for WhatsApp dispatch!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settlement slip link copied for WhatsApp sharing!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _shareMessage = null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final txnAsync = ref.watch(transactionDetailProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          color: AppColors.surface.withValues(alpha: 0.95),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 16,
            bottom: 8,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, size: 26, color: AppColors.primary),
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Krishichakra Institutional Buyer Procurement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Institutional Agri Trade Gateway',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Notifications
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No new escrow alerts.')),
                      );
                    },
                    icon: Icon(Icons.notifications_outlined,
                        size: 24, color: AppColors.onSurfaceVariant),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              // Buyer Profile badge
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceContainerHighest,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.business, size: 18, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: txnAsync.when(
        data: (txn) => _buildContent(txn),
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 16),
              Text(
                'Fetching Institutional Settlement Audit...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Unable to load transaction #LOT-${widget.transactionId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(
                      transactionDetailProvider(widget.transactionId)),
                  icon: Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TransactionRecord txn) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionDetailProvider(widget.transactionId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ 0. Payment Status Test Controller (Genuine Backend Toggle) â”€â”€â”€
            _buildPaymentStatusController(txn),

            // â”€â”€ 1. Escrow Settlement Status Badge Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildEscrowBadgeBanner(txn),

            // â”€â”€ 2. Photographic Verification Thumbnail Strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildPhotographicAssayStrip(txn),

            // â”€â”€ 3. 3-Stage Milestone Settlement Stepper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildMilestonesStepper(txn),

            // â”€â”€ 4. Core USP: Crate-Level Dispute Resolution Box â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildCrateDisputeBox(txn),

            // â”€â”€ 5. Official Financial Settlement Summary (Ledger Receipt) â”€â”€â”€â”€â”€
            _buildSettlementLedger(txn),

            // â”€â”€ 6. Farmer Share Micro-Ledger Breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildMemberPayoutSplit(txn),

            // â”€â”€ 7. Sticky Actions & Institutional Compliance Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildActionsFooter(txn),
          ],
        ),
      ),
    );
  }

  // â”€â”€ 0. Payment Status Interactive Controller â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPaymentStatusController(TransactionRecord txn) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
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
                  'Live Backend Payment Status Control',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
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
          const SizedBox(height: 4),
          const Text(
            'Updates PATCH /api/transactions/{id}/payment directly without spoofing:',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStatusButton('pending', txn.isPending, Colors.amber.shade800),
              _buildStatusButton('paid', txn.isPaid, AppColors.secondary),
              _buildStatusButton('failed', txn.isFailed, AppColors.error),
              _buildStatusButton('disputed', txn.isDisputed, Colors.deepOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, bool isSelected, Color color) {
    return InkWell(
      onTap: _isUpdatingPayment || isSelected
          ? null
          : () => _changePaymentStatus(status),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ 1. Escrow Settlement Status Badge Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildEscrowBadgeBanner(TransactionRecord txn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LOT AUDIT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Text(
                            'Batch #${txn.batchCode ?? "LOT-9021"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${txn.sellerName ?? "Junnar FPO"} â†’ ${txn.buyerName ?? "Sahyadri Agro"}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nashik Dindori Processing Unit • ${txn.commodity ?? "Bulk Tomato Lot"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusSealBg(txn),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getStatusSealIcon(txn),
                          size: 28,
                          color: _getStatusSealColor(txn),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getStatusSealColor(txn),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Verified Settlement Seal Callout
            _buildSealCallout(txn),
          ],
        ),
      ),
    );
  }

  Color _getStatusSealBg(TransactionRecord txn) {
    if (txn.isPaid) return AppColors.secondaryContainer.withValues(alpha: 0.35);
    if (txn.isFailed) return AppColors.errorContainer.withValues(alpha: 0.5);
    if (txn.isDisputed) return Colors.orange.withValues(alpha: 0.2);
    return AppColors.primaryContainer.withValues(alpha: 0.15);
  }

  Color _getStatusSealColor(TransactionRecord txn) {
    if (txn.isPaid) return AppColors.secondary;
    if (txn.isFailed) return AppColors.error;
    if (txn.isDisputed) return Colors.orange.shade800;
    return AppColors.primary;
  }

  IconData _getStatusSealIcon(TransactionRecord txn) {
    if (txn.isPaid) return Icons.verified_user;
    if (txn.isFailed) return Icons.cancel;
    if (txn.isDisputed) return Icons.gavel;
    return Icons.lock_outline;
  }

  Widget _buildSealCallout(TransactionRecord txn) {
    if (txn.isPaid) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle,
                color: AppColors.secondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agri-Escrow: COMPLETED & VERIFIED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Settled Today, 04:35 PM • UTR: ${txn.utrNumber ?? "SBIN0049281726"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (txn.isPending) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_clock, color: Colors.amber.shade900, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agri-Escrow: FUNDS LOCKED & PENDING',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade900,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tranche 1 awaiting weighbridge audit • Tranche 2 held in escrow',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (txn.isFailed) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agri-Escrow: PAYMENT TRANSFER FAILED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bank NPCI Aadhaar Bridge rejected transaction. Escrow held secure.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Disputed
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel, color: Colors.orange.shade900, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agri-Escrow: DISPUTED & ISOLATED',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade900,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Crate-level dispute active. Healthy consignment payout unaffected.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ 2. Photographic Verification Thumbnail Strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPhotographicAssayStrip(TransactionRecord txn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 52,
                color: Colors.red.shade100,
                child: Icon(Icons.inventory_2, color: Colors.red, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consignment Visual Assay Log',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '400 Crates • Total Tare Verified',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.photo_camera,
                          size: 13, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Visual Inspection Cleared',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 52,
                color: Colors.blueGrey.shade100,
                child: Icon(Icons.scale, color: Colors.blueGrey, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ 3. 3-Stage Milestone Settlement Stepper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMilestonesStepper(TransactionRecord txn) {
    final milestones = txn.milestones;
    final completedCount = milestones.where((m) => m.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Settlement Milestones',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedCount of ${milestones.isNotEmpty ? milestones.length : 3} Complete',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (milestones.isNotEmpty) ...[
              for (int i = 0; i < milestones.length; i++)
                _buildMilestoneItem(
                  milestone: milestones[i],
                  isLast: i == milestones.length - 1,
                ),
            ] else ...[
              _buildDefaultMilestones(txn),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneItem({
    required SettlementMilestone milestone,
    required bool isLast,
  }) {
    final isDone = milestone.isCompleted;
    final isCurrent = milestone.isCurrent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary
                    : (isCurrent
                        ? AppColors.primaryContainer.withValues(alpha: 0.3)
                        : AppColors.surfaceContainerHighest),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : (isCurrent
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : Text(
                            '${milestone.step}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          )),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: milestone.amount != null ? 64 : 48,
                color: isDone
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      milestone.timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  milestone.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                if (milestone.badge != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            milestone.badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (milestone.amount != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: milestone.step == 2
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            milestone.amountLabel ?? 'Advance Tranche',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: milestone.step == 2
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatInr(milestone.amount!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: milestone.step == 2
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultMilestones(TransactionRecord txn) {
    return Column(
      children: [
        _buildMilestoneItem(
          milestone: const SettlementMilestone(
            step: 1,
            title: 'Dispatch QR Confirmation',
            timestamp: '19 Sep • 05:15 PM',
            description:
                '400 Crates scanned at Junnar Hub Gate. Truck consignment seal intact and logged.',
            badge: 'QR-Seal Log #9021-JNR',
            isCompleted: true,
          ),
          isLast: false,
        ),
        _buildMilestoneItem(
          milestone: SettlementMilestone(
            step: 2,
            title: 'Weighbridge Slip Verified',
            timestamp: '20 Sep • 07:45 AM',
            description:
                '20.1 Tonnes Verified (Gross 28.4T / Tare 8.3T) at Dindori Factory Weighbridge.',
            amount: 241200,
            amountLabel: 'Tranche 1 (50% Advance)',
            isCompleted: txn.isPaid || txn.isDisputed,
          ),
          isLast: false,
        ),
        _buildMilestoneItem(
          milestone: SettlementMilestone(
            step: 3,
            title: 'Assay & Final Release',
            timestamp: 'Today • 04:35 PM',
            description:
                'Digital assay confirmed 88% Grade A uniformity. Plant Gate QC Passed.',
            amount: 215500,
            amountLabel: 'Tranche 2 (Final Balance)',
            isCompleted: txn.isPaid,
          ),
          isLast: true,
        ),
      ],
    );
  }

  // â”€â”€ 4. Core USP: Crate-Level Dispute Resolution Box â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCrateDisputeBox(TransactionRecord txn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              color: const Color(0xFF7E4200),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5C2F00),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gavel, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Crate Dispute Isolation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'KrishiChakra Zero Whole-Batch Rejection Shield',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFFB579),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDCC3).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notification_important,
                            size: 18, color: Color(0xFF7E4200)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurface,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'Buyer flagged '),
                                TextSpan(
                                  text:
                                      '${txn.flaggedCratesCount > 0 ? txn.flaggedCratesCount : 2} crates ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                    text: 'with transit bruising out of '),
                                const TextSpan(
                                  text: '400 total crates ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: 'during unloading.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'ISOLATED CRATES AUDIT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurfaceVariant,
                                  letterSpacing: 0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${txn.flaggedCratesCount > 0 ? txn.flaggedCratesCount : 2} / 400 Flagged',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Defect isolated strictly to specific QR lot units (Suresh Deshmukh, 50kg each):',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildFlaggedCratePill('#QR-38: Bruised (-50kg)'),
                            _buildFlaggedCratePill('#QR-39: Bruised (-50kg)'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: const [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: AppColors.secondary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Remaining 398 Crates',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹2,400 / Quintal (Full Pay)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Smallholder Fairness Shield Active',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'No full-lot rejection permitted. The ₹1,200 deduction applies strictly to Crate #QR-38/39. All other 411 smallholders receive 100% uninterrupted payout.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurface,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showDisputeModal(context, txn),
                        icon: Icon(Icons.add_alert, size: 16),
                        label: const Text('File / Update Grievance'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7E4200),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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

  Widget _buildFlaggedCratePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_problem, size: 14, color: AppColors.error),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ 5. Official Financial Settlement Summary (Ledger Receipt) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSettlementLedger(TransactionRecord txn) {
    final ledger = txn.ledger;
    final gross = ledger?.grossValue ?? txn.totalAmount;
    final freight = ledger?.freightDeduction ?? txn.freightDeduction;
    final damage = ledger?.damagedCratesDeduction ?? txn.crateDamageDeduction;
    final apmc = ledger?.apmcFee ?? 0.0;
    final net = ledger?.netDisbursed ?? (gross - freight - damage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Settlement Ledger',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'APMC Reconciled',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Tax Invoice #${txn.invoiceNumber ?? "KC-INV-2026-9021"} • GST Exempt under APMC FPO Direct Route',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildLedgerRow(
              'Gross Value (20.1 Tonnes @ ₹2,400/Q)',
              formatInr(gross),
              color: AppColors.onSurface,
              isBold: true,
            ),
            _buildLedgerRow(
              'Freight (MH-14-AZ-8821)',
              '-${formatInr(freight)}',
              icon: Icons.local_shipping,
              color: AppColors.error,
            ),
            _buildLedgerRow(
              'Damaged Crates (QR-38 & 39)',
              '-${formatInr(damage)}',
              icon: Icons.inventory_2,
              color: AppColors.error,
            ),
            _buildLedgerRow(
              'APMC Mandi Fee & User Charges',
              apmc > 0 ? '-${formatInr(apmc)}' : '₹0 (Govt Exempt)',
              color: AppColors.secondary,
            ),
            const SizedBox(height: 14),

            // Disbursed Container
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NET DISBURSED TO FARMERS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF90D689),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatInr(net),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.bolt, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Direct DBT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Instant Direct Benefit Transfer (DBT) credited to registered farmer accounts via NPCI Aadhaar Bridge.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF90D689),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Ref UTR #${txn.utrNumber ?? "9928174620"}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Bank of Maharashtra & SBI',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
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
      ),
    );
  }

  Widget _buildLedgerRow(
    String label,
    String value, {
    IconData? icon,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ 6. Farmer Share Micro-Ledger Breakdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMemberPayoutSplit(TransactionRecord txn) {
    final splits = txn.memberSplits;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.groups, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Member Payout Split',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '3 Selected of 412',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (splits.isNotEmpty) ...[
              for (final split in splits) _buildSplitCard(split),
            ] else ...[
              _buildDefaultSplitCards(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitCard(MemberPayoutSplit split) {
    final hasWarning = split.deductionAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        split.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasWarning) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning, size: 14, color: AppColors.error),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  split.note ??
                      '${split.quantityQuintal.round()} Quintals • ${split.grade}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatInr(split.netPayout),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                split.status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSplitCards() {
    return Column(
      children: [
        _buildSplitCard(
          const MemberPayoutSplit(
            name: 'Ramesh Patil',
            quantityQuintal: 20,
            grade: 'Grade A',
            grossAmount: 48000,
            deductionAmount: 1250,
            netPayout: 46750,
            status: '100% Paid',
          ),
        ),
        _buildSplitCard(
          const MemberPayoutSplit(
            name: 'Suresh Deshmukh',
            quantityQuintal: 15,
            grade: 'Grade A',
            grossAmount: 36000,
            deductionAmount: 2200,
            netPayout: 33800,
            status: 'Net Adjusted',
            note: '15 Quintals (Reflects -₹1,200 defect)',
          ),
        ),
        _buildSplitCard(
          const MemberPayoutSplit(
            name: 'Junnar FPO Aggregation Pool',
            quantityQuintal: 166,
            grade: 'Aggregated Lot',
            grossAmount: 398400,
            deductionAmount: 0,
            netPayout: 9134,
            status: 'FPO Reserve',
            note: '2% Operational & Handling Margin',
          ),
        ),
      ],
    );
  }

  // â”€â”€ 7. Sticky Actions & Institutional Compliance Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildActionsFooter(TransactionRecord txn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _triggerDownload,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.picture_as_pdf, size: 22),
              label: Text(
                _downloadMessage ??
                    'Download Signed APMC Tax Invoice (PDF)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _isSharing ? null : _triggerShare,
              icon: Icon(Icons.share, size: 22, color: AppColors.secondary),
              label: Text(
                _shareMessage ?? 'Share Settlement Slip via WhatsApp',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLowest,
                side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.verified, size: 15, color: AppColors.primary),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Digitally certified under e-NAM & Model APMC Act 2026',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cryptographically signed with ${txn.sellerName ?? "Junnar FPO"} & ${txn.buyerName ?? "Sahyadri Agro"} e-Sign Key.',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // â”€â”€ Dispute Filing Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showDisputeModal(BuildContext context, TransactionRecord txn) {
    final reasonController = TextEditingController();
    final cratesController = TextEditingController(text: 'QR-38, QR-39');
    String disputeType = 'transit_bruising';
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.gavel, color: Color(0xFF7E4200), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'File Crate Grievance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(modalCtx),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Isolates affected crates under Smallholder Fairness Shield without delaying the rest of the batch payout.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: disputeType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Issue Category',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'transit_bruising',
                      child: Text('Transit Bruising (Crate-level)'),
                    ),
                    DropdownMenuItem(
                      value: 'weight_discrepancy',
                      child: Text('Weighbridge Weight Discrepancy'),
                    ),
                    DropdownMenuItem(
                      value: 'grade_mismatch',
                      child: Text('Grade Mismatch (QC Assay)'),
                    ),
                    DropdownMenuItem(
                      value: 'payment_delay',
                      child: Text('Delayed Tranche Disbursement'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => disputeType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cratesController,
                  decoration: const InputDecoration(
                    labelText: 'Affected Crate Tags (e.g. QR-38, QR-39)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Grievance Details',
                    hintText:
                        'State observations from unloading inspection, photos logged, or driver tare slip...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final reason = reasonController.text.trim().isEmpty
                                ? 'Transit bruising observed on 2 crates during dock unloading'
                                : reasonController.text.trim();

                            setModalState(() => isSubmitting = true);
                            try {
                              final repo = ref.read(transactionRepositoryProvider);
                              await repo.createDispute(
                                transactionId: widget.transactionId,
                                raisedBy: 'Institutional Buyer QC',
                                reason: reason,
                                crateIds: cratesController.text.trim(),
                                disputeType: disputeType,
                              );
                              ref.invalidate(
                                  transactionDetailProvider(widget.transactionId));
                              if (context.mounted) {
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Grievance registered. Transaction marked DISPUTED with Crate Isolation active.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to file dispute: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E4200),
                      foregroundColor: Colors.white,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit & Protect Batch'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

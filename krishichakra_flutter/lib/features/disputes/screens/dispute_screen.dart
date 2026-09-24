import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';

class DisputeScreen extends ConsumerStatefulWidget {
  const DisputeScreen({super.key, required this.transactionId});
  final int transactionId;

  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen> {
  final _reasonController = TextEditingController();
  final _cratesController = TextEditingController(text: 'QR-38, QR-39');
  String _disputeType = 'transit_bruising';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _cratesController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description for your grievance.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.createDispute(
        transactionId: widget.transactionId,
        raisedBy: 'Farmer / Producer FPO',
        reason: reason,
        crateIds: _cratesController.text.trim(),
        disputeType: _disputeType,
      );

      ref.invalidate(transactionDetailProvider(widget.transactionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Grievance registered. Zero-Whole-Batch Rejection Shield active.',
            ),
            backgroundColor: AppColors.secondary,
            duration: Duration(seconds: 3),
          ),
        );
        context.pushReplacement(
            '/transactions/${widget.transactionId}/settlement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit dispute: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            expandedHeight: AppSpacing.headerHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: KcAppBar(
              title: 'Dispute & Grievance Portal',
              subtitle: 'Transaction #LOT-${widget.transactionId}',
              showBack: true,
            ),
            toolbarHeight: AppSpacing.headerHeight,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Ombudsman Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E4200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Smallholder Fairness Shield Protected',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'KrishiChakra guarantees zero full-batch rejection. Disputed crates are isolated while healthy lots are paid uninterrupted.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFFB579),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Issue Category Dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _disputeType,
                  decoration: const InputDecoration(
                    labelText: 'Grievance Type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'transit_bruising',
                      child: Text('Transit Bruising (Crate-level deduction)'),
                    ),
                    DropdownMenuItem(
                      value: 'weight_discrepancy',
                      child: Text('Weighbridge Tare / Weight Discrepancy'),
                    ),
                    DropdownMenuItem(
                      value: 'grade_mismatch',
                      child: Text('Digital Assay Quality Downgrade'),
                    ),
                    DropdownMenuItem(
                      value: 'payment_delay',
                      child: Text('DBT Settlement Delay (>24h window)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _disputeType = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Affected Crate QR IDs
                TextField(
                  controller: _cratesController,
                  decoration: const InputDecoration(
                    labelText: 'Isolated Crate QR IDs',
                    hintText: 'e.g. QR-38, QR-39',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Description
                TextField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Grievance Description & Evidence Notes',
                    hintText:
                        'State specific issues observed (bruising percentage, weighing slips, or buyer inspector comments)...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Submit Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitDispute,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.gavel, size: 20),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting Grievance...'
                          : 'Submit & Isolate Dispute',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E4200),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Support Helpdesk box
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.support_agent,
                          color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Need emergency ombudsman intervention? Call KrishiChakra Kisan Support: 1800-180-1551 (Toll-Free, 24/7).',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

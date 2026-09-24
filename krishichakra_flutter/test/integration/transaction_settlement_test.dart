import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/transaction_repository.dart';
import 'package:krishichakra/features/transactions/screens/consignment_settlement_screen.dart';
import 'package:krishichakra/features/transactions/screens/transaction_detail_screen.dart';
import 'package:krishichakra/features/disputes/screens/dispute_screen.dart';

void main() {
  final testLedger = SettlementLedger(
    grossValue: 482400.0,
    freightDeduction: 24500.0,
    damagedCratesDeduction: 1200.0,
    apmcFee: 0.0,
    netDisbursed: 456700.0,
    currency: 'INR',
    utrReference: 'SBIN0049281726',
    bankInfo: 'Bank of Maharashtra & SBI (Direct DBT)',
  );

  final testMilestones = [
    const SettlementMilestone(
      step: 1,
      title: 'Dispatch QR Confirmation',
      timestamp: '19 Sep • 05:15 PM',
      description: '400 Crates scanned at Junnar Hub Gate.',
      badge: 'QR-Seal Log #9021-JNR',
      isCompleted: true,
    ),
    const SettlementMilestone(
      step: 2,
      title: 'Weighbridge Slip Verified',
      timestamp: '20 Sep • 07:45 AM',
      description: '20.1 Tonnes Verified at Dindori Factory Weighbridge.',
      amount: 241200.0,
      amountLabel: 'Tranche 1 (50% Advance)',
      isCompleted: true,
    ),
    const SettlementMilestone(
      step: 3,
      title: 'Assay & Final Release',
      timestamp: 'Today • 04:35 PM',
      description: 'Digital assay confirmed 88% Grade A uniformity.',
      amount: 215500.0,
      amountLabel: 'Tranche 2 (Final Balance)',
      isCompleted: true,
    ),
  ];

  final testIsolatedCrates = [
    const IsolatedCrate(
      crateId: '#QR-38',
      issue: 'Bruised (-50kg)',
      weightKg: 50.0,
      deductionAmount: 600.0,
    ),
    const IsolatedCrate(
      crateId: '#QR-39',
      issue: 'Bruised (-50kg)',
      weightKg: 50.0,
      deductionAmount: 600.0,
    ),
  ];

  final testSplits = [
    const MemberPayoutSplit(
      name: 'Ramesh Patil',
      quantityQuintal: 20.0,
      grade: 'Grade A',
      grossAmount: 48000.0,
      deductionAmount: 1250.0,
      netPayout: 46750.0,
      status: '100% Paid',
    ),
    const MemberPayoutSplit(
      name: 'Suresh Deshmukh',
      quantityQuintal: 15.0,
      grade: 'Grade A',
      grossAmount: 36000.0,
      deductionAmount: 2200.0,
      netPayout: 33800.0,
      status: 'Net Adjusted',
      note: '15 Quintals (Reflects -₹1,200 defect)',
    ),
    const MemberPayoutSplit(
      name: 'Junnar FPO Aggregation Pool',
      quantityQuintal: 166.0,
      grade: 'Aggregated Lot',
      grossAmount: 398400.0,
      deductionAmount: 0.0,
      netPayout: 9134.0,
      status: 'FPO Reserve',
      note: '2% Operational & Handling Margin',
    ),
  ];

  final testTxnPaid = TransactionRecord(
    id: 9021,
    lotId: 101,
    buyerId: 5,
    agreedPrice: 2400.0,
    quantityQuintal: 201.0,
    totalAmount: 482400.0,
    status: 'settled',
    paymentStatus: 'paid',
    utrNumber: 'SBIN0049281726',
    weighbridgeQuantity: 20.1,
    freightDeduction: 24500.0,
    crateDamageDeduction: 1200.0,
    flaggedCratesCount: 2,
    invoiceNumber: 'KC-INV-2026-9021',
    batchCode: 'LOT-9021',
    sellerName: 'Junnar FPO',
    buyerName: 'Sahyadri Agro',
    commodity: 'Bulk Tomato Lot',
    milestones: testMilestones,
    isolatedCrates: testIsolatedCrates,
    ledger: testLedger,
    memberSplits: testSplits,
  );

  group('Transaction & Settlement Model Tests', () {
    test('TransactionRecord parses JSON correctly', () {
      final json = {
        'id': 9021,
        'lot_id': 101,
        'buyer_id': 5,
        'agreed_price': 2400.0,
        'quantity_quintal': 201.0,
        'total_amount': 482400.0,
        'status': 'settled',
        'payment_status': 'paid',
        'utr_number': 'SBIN0049281726',
        'flagged_crates_count': 2,
        'batch_code': 'LOT-9021',
        'seller_name': 'Junnar FPO',
        'buyer_name': 'Sahyadri Agro',
        'milestones': [
          {
            'step': 1,
            'title': 'Dispatch QR Confirmation',
            'timestamp': '19 Sep',
            'description': 'Scanned at gate',
            'is_completed': true,
          }
        ],
        'ledger': {
          'gross_value': 482400.0,
          'freight_deduction': 24500.0,
          'damaged_crates_deduction': 1200.0,
          'apmc_fee': 0.0,
          'net_disbursed': 456700.0,
          'utr_reference': 'SBIN0049281726',
        },
      };

      final txn = TransactionRecord.fromJson(json);
      expect(txn.id, 9021);
      expect(txn.isPaid, true);
      expect(txn.isPending, false);
      expect(txn.isFailed, false);
      expect(txn.isDisputed, false);
      expect(txn.totalAmount, 482400.0);
      expect(txn.ledger?.netDisbursed, 456700.0);
      expect(txn.milestones.length, 1);
    });

    test('DisputeRecord parses JSON correctly', () {
      final json = {
        'id': 1,
        'transaction_id': 9021,
        'raised_by': 'Buyer QC',
        'reason': 'Crate damage in transit',
        'status': 'open',
        'crate_ids': 'QR-38, QR-39',
        'dispute_type': 'transit_bruising',
      };
      final disp = DisputeRecord.fromJson(json);
      expect(disp.id, 1);
      expect(disp.transactionId, 9021);
      expect(disp.crateIds, 'QR-38, QR-39');
      expect(disp.status, 'open');
    });
  });

  group('ConsignmentSettlementScreen Widget Tests (Stitch UI)', () {
    testWidgets(
        'renders all Stitch settlement sections faithfully for paid status',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 2500));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('paid_scope'),
          overrides: [
            transactionDetailProvider(9021).overrideWith((ref) => testTxnPaid),
          ],
          child: const MaterialApp(
            home: ConsignmentSettlementScreen(transactionId: 9021),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(
          find.text('Krishichakra Institutional Buyer Procurement'), findsOneWidget);
      expect(find.text('Institutional Agri Trade Gateway'), findsOneWidget);

      // Badge Banner
      expect(find.text('LOT AUDIT'), findsOneWidget);
      expect(find.text('Batch #LOT-9021'), findsOneWidget);
      expect(find.text('Junnar FPO → Sahyadri Agro'), findsOneWidget);
      expect(find.text('Agri-Escrow: COMPLETED & VERIFIED'), findsOneWidget);
      expect(find.textContaining('SBIN0049281726'), findsWidgets);

      // Photographic Assay strip
      expect(find.text('Consignment Visual Assay Log'), findsOneWidget);
      expect(find.text('400 Crates • Total Tare Verified'), findsOneWidget);
      expect(find.text('Visual Inspection Cleared'), findsOneWidget);

      // 3-Stage Milestone Stepper
      expect(find.text('Settlement Milestones'), findsOneWidget);
      expect(find.text('Dispatch QR Confirmation'), findsOneWidget);
      expect(find.text('Weighbridge Slip Verified'), findsOneWidget);
      expect(find.text('Assay & Final Release'), findsOneWidget);

      // Core USP: Crate Dispute Isolation Box
      expect(find.text('Crate Dispute Isolation'), findsOneWidget);
      expect(find.text('KrishiChakra Zero Whole-Batch Rejection Shield'),
          findsOneWidget);
      expect(find.text('#QR-38: Bruised (-50kg)'), findsOneWidget);
      expect(find.text('#QR-39: Bruised (-50kg)'), findsOneWidget);
      expect(find.text('Remaining 398 Crates'), findsOneWidget);
      expect(find.text('Smallholder Fairness Shield Active'), findsOneWidget);

      // Settlement Ledger Receipt
      expect(find.text('Settlement Ledger'), findsOneWidget);
      expect(find.text('APMC Reconciled'), findsOneWidget);
      expect(find.text('NET DISBURSED TO FARMERS'), findsOneWidget);
      expect(find.text('Direct DBT'), findsOneWidget);

      // Member Payout Split
      expect(find.text('Member Payout Split'), findsOneWidget);
      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.text('Suresh Deshmukh'), findsOneWidget);

      // Actions Footer
      expect(find.text('Download Signed APMC Tax Invoice (PDF)'), findsOneWidget);
      expect(find.text('Share Settlement Slip via WhatsApp'), findsOneWidget);
    });

    testWidgets('renders distinct UI for pending, failed, and disputed payment status',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Pending Status
      final pendingTxn = testTxnPaid.toJson();
      pendingTxn['payment_status'] = 'pending';
      pendingTxn['status'] = 'escrow_locked';

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('pending_scope'),
          overrides: [
            transactionDetailProvider(9021).overrideWith(
                (ref) => TransactionRecord.fromJson(pendingTxn)),
          ],
          child: const MaterialApp(
            home: ConsignmentSettlementScreen(transactionId: 9021),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agri-Escrow: FUNDS LOCKED & PENDING'), findsOneWidget);

      // 2. Failed Status
      final failedTxn = testTxnPaid.toJson();
      failedTxn['payment_status'] = 'failed';
      failedTxn['status'] = 'payment_failed';

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('failed_scope'),
          overrides: [
            transactionDetailProvider(9021).overrideWith(
                (ref) => TransactionRecord.fromJson(failedTxn)),
          ],
          child: const MaterialApp(
            home: ConsignmentSettlementScreen(transactionId: 9021),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agri-Escrow: PAYMENT TRANSFER FAILED'), findsOneWidget);

      // 3. Disputed Status
      final disputedTxn = testTxnPaid.toJson();
      disputedTxn['payment_status'] = 'disputed';
      disputedTxn['status'] = 'disputed';

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('disputed_scope'),
          overrides: [
            transactionDetailProvider(9021).overrideWith(
                (ref) => TransactionRecord.fromJson(disputedTxn)),
          ],
          child: const MaterialApp(
            home: ConsignmentSettlementScreen(transactionId: 9021),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agri-Escrow: DISPUTED & ISOLATED'), findsOneWidget);
    });
  });

  group('TransactionDetailScreen Widget Tests', () {
    testWidgets('renders transaction record with milestones and navigation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionDetailProvider(9021).overrideWith((ref) => testTxnPaid),
          ],
          child: const MaterialApp(
            home: TransactionDetailScreen(transactionId: 9021),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transaction #LOT-9021'), findsOneWidget);
      expect(find.text('View Consignment Settlement & Audit'), findsOneWidget);
      expect(find.text('Raise Dispute / Grievance'), findsOneWidget);
    });
  });

  group('DisputeScreen Widget Tests', () {
    testWidgets('renders dispute screen with ombudsman guarantee and submission form',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DisputeScreen(transactionId: 9021),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dispute & Grievance Portal'), findsOneWidget);
      expect(find.text('Smallholder Fairness Shield Protected'), findsOneWidget);
      expect(find.text('Submit & Isolate Dispute'), findsOneWidget);
      expect(find.textContaining('1800-180-1551'), findsOneWidget);
    });
  });
}

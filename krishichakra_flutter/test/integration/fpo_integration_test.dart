import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/fpo_repository.dart';
import 'package:krishichakra/features/fpo/screens/fpo_batch_aggregation_screen.dart';

void main() {
  group('FPO Models & Aggregation JSON Tests', () {
    test('Fpo.fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'name': 'Junnar Farmer Producer Co. Ltd.',
        'district': 'Pune',
        'state': 'Maharashtra',
        'registration_number': 'Reg #MH-JNR-092',
        'hub_name': 'Junnar FPC Hub',
        'total_members_count': 412,
        'verified': true,
      };

      final fpo = Fpo.fromJson(json);
      expect(fpo.id, 1);
      expect(fpo.name, 'Junnar Farmer Producer Co. Ltd.');
      expect(fpo.district, 'Pune');
      expect(fpo.state, 'Maharashtra');
      expect(fpo.registrationNumber, 'Reg #MH-JNR-092');
      expect(fpo.hubName, 'Junnar FPC Hub');
      expect(fpo.memberCount, 412);
      expect(fpo.verified, isTrue);
    });

    test('FpoMember.fromJson parses directory fields', () {
      final json = {
        'id': 10,
        'fpo_id': 1,
        'farmer_id': 84,
        'farmer_name': 'Ramesh Patil',
        'farmer_phone': '9876543210',
        'farmer_village': 'Junnar',
        'farmer_district': 'Pune',
        'member_code': 'Member ID #FPO-084',
        'role': 'lead_grower',
      };

      final member = FpoMember.fromJson(json);
      expect(member.id, 10);
      expect(member.fpoId, 1);
      expect(member.farmerName, 'Ramesh Patil');
      expect(member.memberCode, 'Member ID #FPO-084');
      expect(member.role, 'lead_grower');
    });

    test('FpoBatchLot.fromJson handles staged vs diverted lots', () {
      final stagedJson = {
        'id': 1,
        'batch_id': 1,
        'farmer_name': 'Ramesh Patil',
        'member_code': 'Member ID #FPO-084',
        'quantity_quintal': 20.0,
        'grade': 'Grade A',
        'bulb_spec': '52–58mm bulb',
        'moisture_pct': 11.8,
        'foreign_rot_pct': 0.0,
        'crates_count': 40,
        'qr_tag_range': '#QR-01 to #QR-40',
        'status': 'staged',
      };

      final staged = FpoBatchLot.fromJson(stagedJson);
      expect(staged.isStaged, isTrue);
      expect(staged.isDiverted, isFalse);
      expect(staged.quantityQuintal, 20.0);
      expect(staged.cratesCount, 40);

      final divertedJson = {
        'id': 3,
        'batch_id': 1,
        'farmer_name': 'Vilas Shinde',
        'member_code': 'Member ID #FPO-203',
        'quantity_quintal': 8.0,
        'grade': 'Grade B',
        'status': 'diverted',
        'diversion_route': 'Junnar APMC Yard • Spot Auction Slip #92',
        'gatekeeper_note':
            'Not eligible for Grade A bulk processing contract. Auto-rerouted to local mandi spot auction to safeguard FPO grade purity bonus.',
      };

      final diverted = FpoBatchLot.fromJson(divertedJson);
      expect(diverted.isStaged, isFalse);
      expect(diverted.isDiverted, isTrue);
      expect(diverted.diversionRoute, contains('APMC'));
      expect(diverted.gatekeeperNote, contains('safeguard FPO grade purity'));
    });

    test('FpoFinancialLedger.fromJson parses ledger values', () {
      final json = {
        'commercial_value': 490000.0,
        'farmer_payout': 462500.0,
        'fpo_margin': 9800.0,
        'freight_surcharge': 17700.0,
        'currency': 'INR',
      };

      final ledger = FpoFinancialLedger.fromJson(json);
      expect(ledger.commercialValue, 490000.0);
      expect(ledger.farmerPayout, 462500.0);
      expect(ledger.fpoMargin, 9800.0);
      expect(ledger.freightSurcharge, 17700.0);
    });

    test('FpoBatchAggregation.fromJson parses full batch aggregation', () {
      final json = {
        'id': 1,
        'batch_code': '#ON-BATCH-402',
        'fpo_id': 1,
        'fpo_name': 'Junnar Farmer Producer Co. Ltd.',
        'fpo_verified': true,
        'fpo_registration_number': 'Reg #MH-JNR-092',
        'fpo_hub_name': 'Junnar FPC Hub',
        'total_registered_farmers': 412,
        'commodity': 'Nashik Red Onion',
        'target_grade': 'Grade A',
        'target_quantity_quintal': 200.0,
        'staged_quantity_quintal': 185.0,
        'diverted_quantity_quintal': 8.0,
        'remaining_quantity_quintal': 15.0,
        'remaining_crates': 30,
        'fill_percentage': 92.5,
        'status': 'pooling',
        'buyer_name': 'Sahyadri Processing',
        'buyer_contract_price': 2650.0,
        'benchmark_mandi_price': 2470.0,
        'institutional_premium_per_q': 180.0,
        'bonus_explanation':
            'Consolidated volume unlocks direct contract with Sahyadri Processing at ₹2,650/Q flat vs ₹2,470/Q spot market average.',
        'staging_bay_info':
            'Junnar Staging Bay: 70 Crates Checked • Live Camera Gate 2',
        'total_crates_checked': 70,
        'dock_bay': 'Dock Bay #2',
        'transporter_vehicle': '10-Tonne Eicher Pro',
        'transporter_number': 'MH-14-AZ-8821',
        'transporter_driver': 'Kailash Jadhav • Verified Ventilated Reefer',
        'destination': 'Sahyadri Agro Processing Plant, Dindori',
        'lots': [
          {
            'id': 1,
            'batch_id': 1,
            'farmer_name': 'Ramesh Patil',
            'quantity_quintal': 20.0,
            'grade': 'Grade A',
            'crates_count': 40,
            'status': 'staged',
          },
          {
            'id': 3,
            'batch_id': 1,
            'farmer_name': 'Vilas Shinde',
            'quantity_quintal': 8.0,
            'grade': 'Grade B',
            'crates_count': 0,
            'status': 'diverted',
            'diversion_route': 'Junnar APMC Yard',
            'gatekeeper_note': 'Rerouted to spot auction.',
          }
        ],
        'ledger': {
          'commercial_value': 490000.0,
          'farmer_payout': 462500.0,
          'fpo_margin': 9800.0,
          'freight_surcharge': 17700.0,
        },
      };

      final agg = FpoBatchAggregation.fromJson(json);
      expect(agg.batchCode, '#ON-BATCH-402');
      expect(agg.fpoHubName, 'Junnar FPC Hub');
      expect(agg.fpoVerified, isTrue);
      expect(agg.stagedQuantityQuintal, 185.0);
      expect(agg.fillPercentage, 92.5);
      expect(agg.remainingCrates, 30);
      expect(agg.institutionalBonusPerQ, 180.0);
      expect(agg.lots.length, 2);
      expect(agg.ledger.commercialValue, 490000.0);
    });
  });

  group('FpoBatchAggregationScreen UI Tests', () {
    final sampleAggregation = FpoBatchAggregation(
      id: 1,
      batchCode: '#ON-BATCH-402',
      fpoId: 1,
      fpoName: 'Junnar Farmer Producer Co. Ltd.',
      fpoVerified: true,
      fpoRegistrationNumber: 'Reg #MH-JNR-092',
      fpoHubName: 'Junnar FPC Hub',
      totalRegisteredFarmers: 412,
      commodity: 'Nashik Red Onion',
      targetGrade: 'Grade A',
      targetQuantityQuintal: 200.0,
      stagedQuantityQuintal: 185.0,
      divertedQuantityQuintal: 8.0,
      remainingQuantityQuintal: 15.0,
      remainingCrates: 30,
      fillPercentage: 92.5,
      status: 'pooling',
      buyerName: 'Sahyadri Processing',
      buyerContractPrice: 2650.0,
      benchmarkMandiPrice: 2470.0,
      institutionalBonusPerQ: 180.0,
      bonusExplanation:
          'Consolidated volume unlocks direct contract with Sahyadri Processing at ₹2,650/Q flat vs ₹2,470/Q spot market average.',
      stagingBayInfo:
          'Junnar Staging Bay: 70 Crates Checked • Live Camera Gate 2',
      totalCratesChecked: 70,
      dockBay: 'Dock Bay #2',
      transporterVehicle: '10-Tonne Eicher Pro',
      transporterNumber: 'MH-14-AZ-8821',
      transporterDriver: 'Kailash Jadhav • Verified Ventilated Reefer',
      destination: 'Sahyadri Agro Processing Plant, Dindori',
      lots: const [
        FpoBatchLot(
          id: 1,
          batchId: 1,
          farmerName: 'Ramesh Patil',
          memberCode: 'Member ID #FPO-084',
          quantityQuintal: 20.0,
          grade: 'Grade A',
          bulbSpec: '52–58mm bulb',
          moisturePct: 11.8,
          foreignRotPct: 0.0,
          cratesCount: 40,
          qrTagRange: '#QR-01 to #QR-40',
          status: 'staged',
        ),
        FpoBatchLot(
          id: 2,
          batchId: 1,
          farmerName: 'Suresh Deshmukh',
          memberCode: 'Member ID #FPO-119',
          quantityQuintal: 15.0,
          grade: 'Grade A',
          bulbSpec: '50–56mm bulb',
          moisturePct: 12.1,
          foreignRotPct: 0.0,
          cratesCount: 30,
          qrTagRange: '#QR-41 to #QR-70',
          status: 'staged',
        ),
        FpoBatchLot(
          id: 3,
          batchId: 1,
          farmerName: 'Vilas Shinde',
          memberCode: 'Member ID #FPO-203',
          quantityQuintal: 8.0,
          grade: 'Grade B',
          bulbSpec: '<45mm Uniformity',
          moisturePct: 14.0,
          foreignRotPct: 2.0,
          cratesCount: 0,
          status: 'diverted',
          diversionRoute: 'Junnar APMC Yard • Spot Auction Slip #92',
          gatekeeperNote:
              'Not eligible for Grade A bulk processing contract. Auto-rerouted to local mandi spot auction to safeguard FPO grade purity bonus.',
        ),
      ],
      ledger: const FpoFinancialLedger(
        commercialValue: 490000.0,
        farmerPayout: 462500.0,
        fpoMargin: 9800.0,
        freightSurcharge: 17700.0,
      ),
    );

    testWidgets('Renders Stitch FPO batch aggregation screen with live data',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fpoBatchAggregationProvider(1).overrideWith(
              (ref) => Future.value(sampleAggregation),
            ),
          ],
          child: const MaterialApp(
            home: FpoBatchAggregationScreen(batchId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header & FPO brand strip
      expect(find.text('Fpo Batch Aggregation'), findsOneWidget);
      expect(find.text('Junnar FPC Hub'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Reg #MH-JNR-092'), findsOneWidget);
      expect(find.text('412 Smallholders Registered'), findsOneWidget);

      // Active Consignment Card
      expect(find.text('#ON-BATCH-402'), findsOneWidget);
      expect(find.text('Pooling Active • 93% Filled'), findsOneWidget);
      expect(find.text('Nashik Red Onion'), findsOneWidget);
      expect(find.text('Grade A Export Spec'), findsOneWidget);

      // Consolidation Target & Bonus
      expect(find.text('Consolidation Target'), findsOneWidget);
      expect(find.text('18.5 / 20.0 T'), findsOneWidget);
      expect(find.text('92.5% Complete'), findsOneWidget);
      expect(
          find.text('Bulk Institutional Bonus Unlocked: +₹180/Q'), findsOneWidget);

      // Member Lots & Gatekeeper
      expect(find.text('Member Contributed Lots'), findsOneWidget);
      expect(find.text('Gatekeeper Active'), findsOneWidget);
      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.text('Suresh Deshmukh'), findsOneWidget);
      expect(find.text('Vilas Shinde'), findsOneWidget);
      expect(find.text('Staged at Hub'), findsNWidgets(2));
      expect(find.text('Diverted to APMC'), findsOneWidget);

      // Logistics
      expect(find.text('Assigned Logistics & Transport'), findsOneWidget);
      expect(find.text('10-Tonne Eicher Pro'), findsOneWidget);
      expect(find.text('MH-14-AZ-8821'), findsOneWidget);

      // Financial Ledger
      expect(find.text('Financial Ledger Realization'), findsOneWidget);
      expect(find.text('Escrow Protected'), findsOneWidget);
      expect(find.text('₹490000'), findsOneWidget);
      expect(find.text('₹462500'), findsOneWidget);

      // Dispatch button
      expect(find.text('Seal Master Batch & Dispatch Order'), findsOneWidget);
    });
  });
}

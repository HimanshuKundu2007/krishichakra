import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/mandi_repository.dart';
import 'package:krishichakra/features/mandi/screens/mandi_detail_screen.dart';

void main() {
  testWidgets('MandiDetailScreen renders price summary, chart, and timeline cards',
      (tester) async {
    const testRecords = [
      MandiPrice(
        id: 1,
        commodity: 'Tomato',
        variety: 'Deshi',
        state: 'Maharashtra',
        district: 'Pune',
        market: 'Junnar',
        arrivalDate: '2026-09-19',
        minPrice: 2200,
        maxPrice: 2800,
        modalPrice: 2500,
        unit: 'Quintal',
        arrivalQuantity: 150,
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
      ),
      MandiPrice(
        id: 2,
        commodity: 'Tomato',
        variety: 'Deshi',
        state: 'Maharashtra',
        district: 'Pune',
        market: 'Junnar',
        arrivalDate: '2026-09-20',
        minPrice: 2400,
        maxPrice: 3000,
        modalPrice: 2700,
        unit: 'Quintal',
        arrivalQuantity: 180,
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
      ),
    ];

    const testStatus = MandiStatus(
      source: 'Government Market Data (AGMARKNET / data.gov.in)',
      lastSync: '2026-09-20T10:00:00',
      lastSyncStatus: 'success',
      lastSuccessfulSync: '2026-09-20T10:00:00',
      records: 200,
      govRecords: 200,
      latestDataDate: '2026-09-20',
      isLive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mandiStatusProvider.overrideWith((ref) => testStatus),
          mandiHistoryProvider((commodity: 'Tomato', market: 'Junnar'))
              .overrideWith((ref) => testRecords),
        ],
        child: const MaterialApp(
          home: MandiDetailScreen(
            market: 'Junnar',
            commodity: 'Tomato',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Junnar'), findsOneWidget);
    expect(find.text('Tomato Price History'), findsOneWidget);

    // Verify Summary stats
    expect(find.text('Government Market Price Summary'), findsOneWidget);
    expect(find.text('Latest Modal'), findsOneWidget);
    expect(find.text('Period Min'), findsOneWidget);
    expect(find.text('Period Max'), findsOneWidget);
    expect(find.text('Total Arrivals'), findsOneWidget);

    // Verify Chart title
    expect(find.text('Modal Price Movement (₹/Q)'), findsOneWidget);

    // Verify Timeline records
    expect(find.text('Arrival Price Timeline (2 records)'), findsOneWidget);
    expect(find.text('150 Qtl'), findsOneWidget);
    expect(find.text('180 Qtl'), findsOneWidget);
  });
}

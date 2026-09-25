import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/mandi_repository.dart';
import 'package:krishichakra/features/mandi/screens/mandi_detail_screen.dart';
import 'package:krishichakra/l10n/app_localizations.dart';

void main() {
  testWidgets('MandiDetailScreen renders price summary, chart, and timeline cards',
      (tester) async {

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

    final testHistory = MandiDailyHistory(
      commodity: 'Tomato',
      market: 'Junnar',
      source: 'Government Market Data (AGMARKNET / data.gov.in)',
      requestedStartDate: '2026-09-14',
      requestedEndDate: '2026-09-20',
      datesChecked: 7,
      datesWithData: 2,
      missingDates: 5,
      period: '7d',
      summary: const MandiHistorySummary(
        latestModal: 2700,
        periodMin: 2200,
        periodMax: 3000,
        avgModal: 2600,
        recordsCount: 2,
        datesCheckedCount: 7,
        datesWithDataCount: 2,
        missingDatesCount: 5,
        trendPercent: 8.0,
      ),
      records: const [
        MandiHistoryPoint(
          date: '2026-09-19',
          displayDate: '19 Sep 2026',
          commodity: 'Tomato',
          market: 'Junnar',
          minPrice: 2200,
          modalPrice: 2500,
          maxPrice: 2800,
          arrivalQuantity: 150,
          unit: 'Quintal',
          source: 'Government Market Data (AGMARKNET / data.gov.in)',
          hasData: true,
          status: 'Reported',
          dataQuality: 'government_exact_market',
        ),
        MandiHistoryPoint(
          date: '2026-09-20',
          displayDate: '20 Sep 2026',
          commodity: 'Tomato',
          market: 'Junnar',
          minPrice: 2400,
          modalPrice: 2700,
          maxPrice: 3000,
          arrivalQuantity: 180,
          unit: 'Quintal',
          source: 'Government Market Data (AGMARKNET / data.gov.in)',
          hasData: true,
          status: 'Reported',
          dataQuality: 'government_exact_market',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mandiStatusProvider.overrideWith((ref) => testStatus),
          mandiDailyHistoryProvider((commodity: 'Tomato', market: 'Junnar', period: '7d'))
              .overrideWith((ref) => testHistory),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: MandiDetailScreen(
            market: 'Junnar',
            commodity: 'Tomato',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Subtitle
    expect(find.text('Junnar'), findsOneWidget);
    expect(find.text('Tomato Price History'), findsOneWidget);

    // Verify Summary stats
    expect(find.text('Government Market Price Summary'), findsOneWidget);
    expect(find.text('Latest Modal'), findsOneWidget);
    expect(find.text('Period Min'), findsOneWidget);
    expect(find.text('Period Max'), findsOneWidget);
    expect(find.text('Avg Modal'), findsOneWidget);

    // Verify Chart title
    expect(find.text('Modal Price Movement (₹/Q)'), findsOneWidget);

    // Verify Timeline records
    expect(find.text('Arrival Price Timeline (2 records)'), findsOneWidget);
    expect(find.text('150 Qtl'), findsOneWidget);
    expect(find.text('180 Qtl'), findsOneWidget);
  });
}

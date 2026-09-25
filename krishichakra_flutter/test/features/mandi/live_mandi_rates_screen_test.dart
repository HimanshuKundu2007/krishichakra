import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/mandi_repository.dart';
import 'package:krishichakra/features/mandi/screens/live_mandi_rates_screen.dart';
import 'package:krishichakra/l10n/app_localizations.dart';

void main() {
  testWidgets('LiveMandiRatesScreen renders search, location filters, price cards, and provenance tags',
      (tester) async {
    const testPrices = [
      MandiPrice(
        id: 1,
        commodity: 'Onion',
        variety: 'Red',
        state: 'Maharashtra',
        district: 'Nashik',
        market: 'Lasalgaon',
        arrivalDate: '2026-09-20',
        minPrice: 1800,
        maxPrice: 2600,
        modalPrice: 2200,
        unit: 'Quintal',
        arrivalQuantity: 450,
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

    final testFilters = (
      states: ['Maharashtra', 'Gujarat'],
      districts: ['Nashik', 'Pune'],
      markets: ['Lasalgaon', 'Junnar'],
      commodities: ['Onion', 'Tomato'],
      varieties: ['Red', 'Local', 'Hybrid'],
    );

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mandiStatusProvider.overrideWith((ref) => testStatus),
          filteredMandiPricesProvider((
            commodity: 'onion',
            state: 'Maharashtra',
            district: null,
            market: null,
            variety: null,
            limit: 100,
          )).overrideWith((ref) => testPrices),
          dynamicMandiFiltersProvider((
            state: 'Maharashtra',
            district: null,
            market: null,
            commodity: 'onion',
          )).overrideWith((ref) => const MandiFiltersData(
                states: ['Maharashtra', 'Gujarat'],
                districts: ['Nashik', 'Pune'],
                markets: ['Lasalgaon', 'Junnar'],
                commodities: ['Onion', 'Tomato'],
                varieties: ['Red', 'Local', 'Hybrid'],
                totalRecords: 2,
              )),
          availableMandiFiltersProvider.overrideWith((ref) => testFilters),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: LiveMandiRatesScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title & Subtitle
    expect(find.text('Live Mandi Rates'), findsOneWidget);
    expect(find.text('Official Agmarknet / data.gov.in rates'), findsOneWidget);

    // Verify Search hint
    expect(find.text('Search crop e.g. Onion, Tomato, Soybean'), findsOneWidget);

    // Verify Provenance
    expect(find.text('e-NAM Verified'), findsOneWidget);

    // Verify Scope toggle & Location filters are present
    expect(find.text('Maharashtra (Focus)'), findsOneWidget);
    expect(find.text('All India (All Mandis)'), findsOneWidget);
    expect(find.text('State: Maharashtra'), findsOneWidget);
    expect(find.text('District: All'), findsOneWidget);
    expect(find.text('Market: All'), findsOneWidget);

    // Verify Mandi card & map pin
    expect(find.text('Lasalgaon'), findsAtLeastNWidgets(1));
    expect(find.text('₹2,200'), findsAtLeastNWidgets(1));
    expect(find.text('450 Qtl'), findsOneWidget);
    expect(find.text('Calculate Net Payout'), findsOneWidget);
  });
}

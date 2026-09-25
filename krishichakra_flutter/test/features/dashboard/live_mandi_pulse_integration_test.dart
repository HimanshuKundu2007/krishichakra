import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:krishichakra/app/router.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/mandi_repository.dart';
import 'package:krishichakra/features/dashboard/screens/farmer_home_screen.dart';

void main() {
  group('Live Mandi Pulse Fully Backend-Driven Integration Tests', () {
    final mockPulseData = [
      const MandiPrice(
        id: 1,
        commodity: 'Wheat',
        normalizedName: 'Wheat',
        variety: 'Lokwan',
        state: 'Maharashtra',
        district: 'Jalgaon',
        market: 'APMC Pachora',
        arrivalDate: '2026-09-24',
        minPrice: 2200,
        maxPrice: 2600,
        modalPrice: 2451,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        priceChangePct: -20.4,
        previousModalPrice: 3080,
      ),
      const MandiPrice(
        id: 2,
        commodity: 'Paddy(Common)',
        normalizedName: 'Paddy',
        variety: 'Common',
        state: 'Maharashtra',
        district: 'Nandurbar',
        market: 'APMC Navapur',
        arrivalDate: '2026-09-24',
        minPrice: 2400,
        maxPrice: 2800,
        modalPrice: 2650,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / Maharashtra OGD)',
        priceChangePct: 0.0,
        previousModalPrice: 2650,
      ),
      const MandiPrice(
        id: 3,
        commodity: 'Sponge gourd',
        normalizedName: 'Sponge Gourd',
        variety: 'Other',
        state: 'Uttar Pradesh',
        district: 'Khekda',
        market: 'Khekda APMC',
        arrivalDate: '2026-09-24',
        minPrice: 1400,
        maxPrice: 1600,
        modalPrice: 1500,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        priceChangePct: null,
        previousModalPrice: null,
      ),
      const MandiPrice(
        id: 4,
        commodity: 'Garlic',
        normalizedName: 'Garlic',
        variety: 'Local',
        state: 'Maharashtra',
        district: 'Ahmednagar',
        market: 'APMC Shrirampur',
        arrivalDate: '2026-09-24',
        minPrice: 7000,
        maxPrice: 9500,
        modalPrice: 8500,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / Maharashtra OGD)',
        priceChangePct: null,
        previousModalPrice: null,
      ),
      const MandiPrice(
        id: 5,
        commodity: 'Green Chilli',
        normalizedName: 'Chilli',
        variety: 'G4',
        state: 'Maharashtra',
        district: 'Nandurbar',
        market: 'APMC Nandurbar',
        arrivalDate: '2026-09-24',
        minPrice: 2500,
        maxPrice: 3000,
        modalPrice: 2700,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / Maharashtra OGD)',
        priceChangePct: 0.0,
        previousModalPrice: 2700,
      ),
      const MandiPrice(
        id: 6,
        commodity: 'Onion',
        normalizedName: 'Onion',
        variety: 'Red',
        state: 'Maharashtra',
        district: 'Pune',
        market: 'Pune(Pimpri)',
        arrivalDate: '2026-09-24',
        minPrice: 3500,
        maxPrice: 4500,
        modalPrice: 4000,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        priceChangePct: -3.8,
        previousModalPrice: 4160,
      ),
      const MandiPrice(
        id: 7,
        commodity: 'Tomato',
        normalizedName: 'Tomato',
        variety: 'Hybrid',
        state: 'Maharashtra',
        district: 'Satara',
        market: 'APMC Vai',
        arrivalDate: '2026-09-24',
        minPrice: 800,
        maxPrice: 1300,
        modalPrice: 1050,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / Maharashtra OGD)',
        priceChangePct: -61.1,
        previousModalPrice: 2700,
      ),
      const MandiPrice(
        id: 8,
        commodity: 'Potato',
        normalizedName: 'Potato',
        variety: 'Jyoti',
        state: 'Maharashtra',
        district: 'Pune',
        market: 'APMC Pune',
        arrivalDate: '2026-09-24',
        minPrice: 900,
        maxPrice: 1300,
        modalPrice: 1100,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / Maharashtra OGD)',
        priceChangePct: -54.7,
        previousModalPrice: 2430,
      ),
      const MandiPrice(
        id: 9,
        commodity: 'Soyabean',
        normalizedName: 'Soybean',
        variety: 'Yellow',
        state: 'Maharashtra',
        district: 'Amravati',
        market: 'APMC Achalpur',
        arrivalDate: '2026-09-24',
        minPrice: 5200,
        maxPrice: 6000,
        modalPrice: 5725,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / Maharashtra OGD)',
        priceChangePct: 13.4,
        previousModalPrice: 5050,
      ),
    ];

    testWidgets('Live Mandi Pulse displays all 9 target commodities with correct prices and movements',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mandiPulseProvider('Maharashtra').overrideWith((ref) => mockPulseData),
            mandiStatusProvider.overrideWith((ref) => const MandiStatus(
                  source: 'Government Market Data (AGMARKNET / data.gov.in)',
                  isLive: true,
                  records: 50,
                  govRecords: 50,
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FarmerHomeScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify at least the 9 target crops are present
      expect(find.text('Wheat'), findsWidgets);
      expect(find.text('Paddy'), findsWidgets);
      expect(find.text('Sponge Gourd'), findsWidgets);
      expect(find.text('Garlic'), findsWidgets);
      expect(find.text('Chilli'), findsWidgets);
      expect(find.text('Onion'), findsWidgets);
      expect(find.text('Tomato'), findsWidgets);
      expect(find.text('Potato'), findsWidgets);
      expect(find.text('Soybean'), findsWidgets);

      // Verify Sponge Gourd shows "—" because previous data does not exist
      expect(find.text('—'), findsWidgets);

      // Verify Soybean shows actual price movement (+13.4%)
      expect(find.text('+13.4%'), findsOneWidget);

      // Verify Wheat shows actual negative price movement (-20.4%)
      expect(find.text('-20.4%'), findsOneWidget);

      // Verify exact market names from backend
      expect(find.text('APMC Pachora'), findsOneWidget);
      expect(find.text('Khekda APMC'), findsOneWidget);
      expect(find.text('APMC Achalpur'), findsOneWidget);
    });

    testWidgets('Tapping crop card navigates dynamically to corresponding crop markets', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (ctx, state) => const FarmerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.markets,
            builder: (ctx, state) {
              navigatedRoute = state.uri.toString();
              return Scaffold(
                body: Text('Markets: ${state.uri.queryParameters['commodity']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mandiPulseProvider('Maharashtra').overrideWith((ref) => mockPulseData),
            mandiStatusProvider.overrideWith((ref) => const MandiStatus(
                  source: 'Government Market Data (AGMARKNET / data.gov.in)',
                  isLive: true,
                  records: 50,
                  govRecords: 50,
                )),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on the Wheat card
      final wheatCardFinder = find.text('Wheat');
      expect(wheatCardFinder, findsWidgets);
      await tester.tap(wheatCardFinder.first);
      await tester.pumpAndSettle();

      // Verify navigation went to /markets?commodity=Wheat
      expect(navigatedRoute, contains('/markets'));
      expect(navigatedRoute, contains('commodity=Wheat'));
      expect(find.text('Markets: Wheat'), findsOneWidget);
    });
  });
}

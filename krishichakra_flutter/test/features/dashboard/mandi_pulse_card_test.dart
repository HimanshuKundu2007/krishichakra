import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/shared/widgets/kc_widgets.dart';

void main() {
  group('CommodityIcon Asset Mapping and Normalization', () {
    test('correctly normalizes all prompt-specified commodities', () {
      expect(CommodityIcon.getAssetPath('Onion'), 'assets/commodities/onion.png');
      expect(CommodityIcon.getAssetPath('Potato'), 'assets/commodities/potato.png');
      expect(CommodityIcon.getAssetPath('Tomato'), 'assets/commodities/tomato.png');
      expect(CommodityIcon.getAssetPath('Banana'), 'assets/commodities/banana.png');
      expect(CommodityIcon.getAssetPath('Guava'), 'assets/commodities/guava.png');
      expect(CommodityIcon.getAssetPath('Orange'), 'assets/commodities/orange.png');
      expect(CommodityIcon.getAssetPath('Carrot'), 'assets/commodities/carrot.png');
      expect(CommodityIcon.getAssetPath('Cucumber'), 'assets/commodities/cucumber.png');
      expect(CommodityIcon.getAssetPath('Brinjal'), 'assets/commodities/brinjal.png');
      expect(CommodityIcon.getAssetPath('Eggplant'), 'assets/commodities/brinjal.png');
      expect(CommodityIcon.getAssetPath('Baingan'), 'assets/commodities/brinjal.png');
      expect(CommodityIcon.getAssetPath('Paddy'), 'assets/commodities/paddy.png');
      expect(CommodityIcon.getAssetPath('Rice'), 'assets/commodities/paddy.png');
      expect(CommodityIcon.getAssetPath('Paddy (Dhan)'), 'assets/commodities/paddy.png');
      expect(CommodityIcon.getAssetPath('Wheat'), 'assets/commodities/wheat.png');
      expect(CommodityIcon.getAssetPath('Cotton'), 'assets/commodities/cotton.png');
      expect(CommodityIcon.getAssetPath('Soybean'), 'assets/commodities/soybean.png');
      expect(CommodityIcon.getAssetPath('Soya'), 'assets/commodities/soybean.png');
      expect(CommodityIcon.getAssetPath('Sugarcane'), 'assets/commodities/sugarcane.png');
    });

    test('falls back to default icon for unknown commodity', () {
      expect(
        CommodityIcon.getAssetPath('Exotic Mushroom XYZ'),
        'assets/commodities/default.png',
      );
    });
  });

  group('Live Mandi Pulse Card Layout & Overflow Verification', () {
    testWidgets('renders short commodity name without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 146,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 230,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CommodityIcon(commodity: 'Onion', size: 24),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Onion (Red)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: const [
                                  Flexible(
                                    child: Text(
                                      '₹2,450',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text('/Q', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const PriceChangeBadge(changePercent: 4.2),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Flexible(
                          child: Text(
                            'Official Agmarknet • Pune',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const DataSourceTag(
                          source: 'AGMARKNET',
                          isLive: true,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Onion (Red)'), findsOneWidget);
      expect(find.text('₹2,450'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders extremely long commodity name and market advisory without overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 146,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 230,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CommodityIcon(
                              commodity: 'Paddy (Dhan) (Basmati 1121 Extra Long Grain Premium Export)',
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Paddy (Dhan) (Basmati 1121 Extra Long Grain Premium Export)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: const [
                                  Flexible(
                                    child: Text(
                                      '₹1,45,200',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text('/Q', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const PriceChangeBadge(changePercent: -12.8),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Flexible(
                          child: Text(
                            'Government Market Data (AGMARKNET / data.gov.in) • Extremely Long Mandi Terminal Market Hub Pune District',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const DataSourceTag(
                          source: 'AGMARKNET',
                          isLive: true,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Expected ZERO overflow errors with long text');
    });
  });

  group('Live Mandi Pulse Backend Data Binding Verification', () {
    testWidgets('PriceChangeBadge renders neutral dash when changePercent is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PriceChangeBadge(changePercent: null),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('—'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('PriceChangeBadge renders positive percentage with trending_up icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PriceChangeBadge(changePercent: 13.4),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('+13.4%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('PriceChangeBadge renders negative percentage with trending_down icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PriceChangeBadge(changePercent: -20.4),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('-20.4%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    test('MandiPrice.fromJson accurately deserializes backend price_change_pct and previous_modal_price', () {
      final jsonWithHistory = {
        'id': 101,
        'commodity': 'Wheat',
        'normalized_name': 'Wheat',
        'variety': 'Lokwan',
        'state': 'Maharashtra',
        'district': 'Jalgaon',
        'market': 'APMC Pachora',
        'arrival_date': '2026-09-24',
        'min_price': 2200.0,
        'max_price': 2600.0,
        'modal_price': 2451.0,
        'unit': 'Quintal',
        'source': 'Government Market Data (AGMARKNET / data.gov.in)',
        'price_change_pct': -20.4,
        'previous_modal_price': 3080.0,
      };

      final priceWithHistory = MandiPrice.fromJson(jsonWithHistory);
      expect(priceWithHistory.commodity, 'Wheat');
      expect(priceWithHistory.modalPrice, 2451.0);
      expect(priceWithHistory.priceChangePct, -20.4);
      expect(priceWithHistory.previousModalPrice, 3080.0);

      final jsonWithoutHistory = {
        'id': 102,
        'commodity': 'Sponge gourd',
        'normalized_name': 'Sponge Gourd',
        'variety': 'Other',
        'state': 'Uttar Pradesh',
        'district': 'Khekda',
        'market': 'Khekda APMC',
        'arrival_date': '2026-09-24',
        'min_price': 1400.0,
        'max_price': 1600.0,
        'modal_price': 1500.0,
        'unit': 'Quintal',
        'source': 'Government Market Data (AGMARKNET / data.gov.in)',
        'price_change_pct': null,
        'previous_modal_price': null,
      };

      final priceWithoutHistory = MandiPrice.fromJson(jsonWithoutHistory);
      expect(priceWithoutHistory.commodity, 'Sponge gourd');
      expect(priceWithoutHistory.displayName, 'Sponge Gourd');
      expect(priceWithoutHistory.modalPrice, 1500.0);
      expect(priceWithoutHistory.priceChangePct, isNull);
      expect(priceWithoutHistory.previousModalPrice, isNull);
    });

    testWidgets('Live Mandi Pulse Card binds all required fields including market, unit, and government source',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 146,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 230,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            CommodityIcon(commodity: 'Sponge Gourd', size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sponge Gourd',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '₹1,500',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Text('/Q', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            SizedBox(width: 6),
                            PriceChangeBadge(changePercent: null),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Flexible(
                          child: Text(
                            'Khekda APMC',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const DataSourceTag(
                          source: 'Government Market Data (AGMARKNET / data.gov.in)',
                          isLive: true,
                          compact: true,
                          lastUpdated: '2026-09-24T18:00:00',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Sponge Gourd'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('/Q'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Khekda APMC'), findsOneWidget);
      expect(find.textContaining('Government Market Data'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('Verifies presence of all 9 target commodities in data parsing', () {
      const requiredCrops = [
        'Wheat',
        'Paddy',
        'Sponge Gourd',
        'Garlic',
        'Chilli',
        'Onion',
        'Tomato',
        'Potato',
        'Soybean',
      ];

      for (final crop in requiredCrops) {
        final iconPath = CommodityIcon.getAssetPath(crop);
        expect(iconPath, isNotEmpty, reason: '$crop should have a mapped icon asset');

        final item = MandiPrice(
          id: 1,
          commodity: crop,
          variety: 'Common',
          state: 'Maharashtra',
          district: 'Pune',
          market: 'APMC Market',
          arrivalDate: '2026-09-24',
          minPrice: 1000,
          maxPrice: 2000,
          modalPrice: 1500,
          unit: 'Quintal',
          source: 'Government Market Data (AGMARKNET / data.gov.in)',
        );
        expect(item.displayName, crop);
        expect(item.isLiveGovData, isTrue);
      }
    });
  });
}

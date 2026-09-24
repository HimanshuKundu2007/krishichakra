import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krishichakra/core/api/api_client.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/intelligence_repository.dart';

class InMemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName;
    if (memberName == #read) {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      return Future<String?>.value(_storage[key]);
    }
    if (memberName == #write) {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      final value = invocation.namedArguments[const Symbol('value')] as String?;
      if (value != null) {
        _storage[key] = value;
      } else {
        _storage.remove(key);
      }
      return Future<void>.value();
    }
    if (memberName == #delete) {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      _storage.remove(key);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late ApiClient apiClient;
  late IntelligenceRepository intelligenceRepo;

  setUp(() {
    final mockStorage = InMemorySecureStorage();
    apiClient = ApiClient(storage: mockStorage);
    intelligenceRepo = IntelligenceRepository(apiClient: apiClient);
  });

  group('KrishiChakra Market Intelligence / Net Realization Integration Tests', () {
    test('1. POST /api/intelligence/recommend-sale returns calculated recommendations with all required fields', () async {
      final response = await intelligenceRepo.getSaleRecommendation(
        commodity: 'Onion',
        quantityQuintal: 20.0,
        transportCostPerQuintal: 160.0,
        storageCostPerQuintal: 15.0,
        holdingDays: 2,
      );

      expect(response, isA<SaleRecommendationResponse>());
      expect(response.commodity, 'Onion');
      expect(response.quantity, 20.0);
      expect(response.options, isNotEmpty);

      // Verify disclaimer: do not present calculated values as guaranteed future prices
      expect(
        response.disclaimer.toLowerCase(),
        contains('not guaranteed future price'),
      );

      for (final opt in response.options) {
        // Required fields verification
        expect(opt.market, isNotEmpty);
        expect(opt.modalPrice, greaterThan(0));
        expect(opt.quantity, 20.0);
        expect(opt.grossRealization, greaterThan(0));
        expect(opt.transportCost, greaterThan(0));
        expect(opt.storageCost, greaterThanOrEqualTo(0));
        expect(opt.estimatedNetRealization, isNotNull);
        expect(opt.governmentDataDate, isNotEmpty);
        expect(opt.source, contains('Government Market Data'));

        // Formula verification:
        // Estimated Net Realization = Gross Realization − Transport Cost − Storage Cost
        final expectedGross = opt.modalPrice * opt.quantity;
        expect((opt.grossRealization - expectedGross).abs(), lessThan(0.01));

        final expectedNet = opt.grossRealization - opt.transportCost - opt.storageCost;
        expect((opt.estimatedNetRealization - expectedNet).abs(), lessThan(0.01));

        // Provenance & distinction check
        expect(opt.isLiveGovData, isTrue);
      }
    });

    test('2. NetRealizationResult correctly models Government-reported price and KrishiChakra calculated estimate', () {
      final result = NetRealizationResult.fromJson({
        'market': 'Vashi APMC',
        'modal_price': 2800.0,
        'quantity': 20.0,
        'gross_realization': 56000.0,
        'transport_cost': 3200.0,
        'storage_cost': 600.0,
        'estimated_net_realization': 52200.0,
        'government_data_date': '2026-09-20',
        'source': 'Government Market Data (AGMARKNET / data.gov.in)',
      });

      // Government-reported values
      expect(result.modalPrice, 2800.0);
      expect(result.governmentDataDate, '2026-09-20');
      expect(result.source, contains('Government Market Data'));

      // KrishiChakra calculated estimates
      expect(result.grossRealization, 56000.0);
      expect(result.transportCost, 3200.0);
      expect(result.storageCost, 600.0);
      expect(result.estimatedNetRealization, 52200.0);
      expect(
        result.estimatedNetRealization,
        result.grossRealization - result.transportCost - result.storageCost,
      );
    });

    test('3. POST /api/intelligence/recommend-sale supports other crops like Tomato', () async {
      final response = await intelligenceRepo.getSaleRecommendation(
        commodity: 'Tomato',
        quantityQuintal: 10.0,
        transportCostPerQuintal: 120.0,
      );

      expect(response.options, isNotEmpty);
      final top = response.options.first;
      expect(top.quantity, 10.0);
      expect(top.grossRealization, top.modalPrice * 10.0);
      expect(top.transportCost, 1200.0);
      expect(
        top.estimatedNetRealization,
        top.grossRealization - top.transportCost - top.storageCost,
      );
    });
  });
}

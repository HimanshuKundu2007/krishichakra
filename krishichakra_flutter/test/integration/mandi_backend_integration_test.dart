import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krishichakra/core/api/api_client.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/mandi_repository.dart';

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
  late MandiRepository mandiRepo;

  setUp(() {
    final mockStorage = InMemorySecureStorage();
    apiClient = ApiClient(storage: mockStorage);
    mandiRepo = MandiRepository(apiClient: apiClient);
  });

  group('KrishiChakra Real Government Mandi Integration Tests', () {
    test('1. GET /api/mandi/status returns government source metadata and sync status', () async {
      final status = await mandiRepo.getMandiStatus();
      expect(status, isA<MandiStatus>());
      expect(status.source, contains('Government Market Data'));
      expect(status.records, greaterThanOrEqualTo(0));
      expect(status.govRecords, greaterThanOrEqualTo(0));
      // Non-negotiable: isLive is only true if successful sync produced government records
      if (status.govRecords == 0 || status.lastSyncStatus != 'success') {
        expect(status.isLive, isFalse);
      }
    });

    test('2. GET /api/mandi/latest returns latest mandi prices', () async {
      final latest = await mandiRepo.getLatestPrices();
      expect(latest, isA<List<MandiPrice>>());
      for (final price in latest) {
        expect(price.commodity, isNotEmpty);
        expect(price.market, isNotEmpty);
        expect(price.arrivalDate, isNotEmpty);
        expect(price.modalPrice, greaterThan(0));
        expect(price.minPrice, greaterThan(0));
        expect(price.maxPrice, greaterThanOrEqualTo(price.minPrice));
        // Provenance verification: DEMO_SEED is never recognized as live gov data
        if (price.source == 'DEMO_SEED') {
          expect(price.isLiveGovData, isFalse);
        }
      }
    });

    test('3. GET /api/mandi/prices supports commodity and market filtering', () async {
      final prices = await mandiRepo.getPrices(commodity: 'Tomato', limit: 10);
      expect(prices, isA<List<MandiPrice>>());
      for (final price in prices) {
        expect(price.commodity.toLowerCase(), contains('tomato'));
      }
    });

    test('4. GET /api/mandi/history returns historical records for commodity', () async {
      final history = await mandiRepo.getPriceHistory('Tomato', days: 20);
      expect(history, isA<List<MandiPrice>>());
      for (final record in history) {
        expect(record.commodity.toLowerCase(), contains('tomato'));
      }
    });

    test('5. MandiPrice model correctly distinguishes DEMO_SEED from verified government data', () {
      const demoPrice = MandiPrice(
        id: 1,
        commodity: 'Tomato',
        variety: 'Hybrid',
        state: 'Maharashtra',
        district: 'Pune',
        market: 'Pune',
        arrivalDate: '2026-09-20',
        minPrice: 2200,
        maxPrice: 3100,
        modalPrice: 2850,
        unit: 'Quintal',
        source: 'DEMO_SEED',
      );

      const govPrice = MandiPrice(
        id: 2,
        commodity: 'Onion',
        variety: 'Red',
        state: 'Maharashtra',
        district: 'Nashik',
        market: 'Lasalgaon',
        arrivalDate: '2026-09-20',
        minPrice: 1800,
        maxPrice: 2500,
        modalPrice: 2200,
        unit: 'Quintal',
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
      );

      expect(demoPrice.isLiveGovData, isFalse);
      expect(govPrice.isLiveGovData, isTrue);
    });
  });
}

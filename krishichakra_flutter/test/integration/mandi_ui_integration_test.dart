import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/api/api_client.dart';
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
  group('KrishiChakra Mandi Intelligence UI & Repository Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      final mockStorage = InMemorySecureStorage();
      final client = ApiClient(storage: mockStorage);
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('availableMandiFiltersProvider extracts states, districts, markets, and commodities',
        () async {
      final filters = await container.read(availableMandiFiltersProvider.future);

      expect(filters.states, isNotEmpty);
      expect(filters.districts, isNotEmpty);
      expect(filters.markets, isNotEmpty);
      expect(filters.commodities, isNotEmpty);

      print('Available States (${filters.states.length}): ${filters.states.take(5).toList()}');
      print('Available Districts (${filters.districts.length}): ${filters.districts.take(5).toList()}');
      print('Available Markets (${filters.markets.length}): ${filters.markets.take(5).toList()}');
      print('Available Commodities (${filters.commodities.length}): ${filters.commodities.take(5).toList()}');

      expect(filters.commodities.any((c) => c.toLowerCase().contains('onion')), isTrue);
    });

    test('filteredMandiPricesProvider applies multi-attribute filter query', () async {
      final prices = await container.read(
        filteredMandiPricesProvider((
          commodity: 'Tomato',
          state: null,
          district: null,
          market: null,
          limit: 10,
        )).future,
      );

      expect(prices, isNotEmpty);
      for (final p in prices) {
        expect(p.commodity.toLowerCase(), contains('tomato'));
        expect(p.minPrice, greaterThan(0));
        expect(p.maxPrice, greaterThanOrEqualTo(p.minPrice));
        expect(p.modalPrice, greaterThanOrEqualTo(p.minPrice));
        expect(p.modalPrice, lessThanOrEqualTo(p.maxPrice));
        expect(p.isLiveGovData, isTrue);
        expect(p.source, contains('Government Market Data'));
      }
    });

    test('mandiHistoryProvider returns price history with verified modal and range data',
        () async {
      final history = await container.read(
        mandiHistoryProvider((commodity: 'Tomato', market: null)).future,
      );

      expect(history, isNotEmpty);
      final first = history.first;
      expect(first.commodity.toLowerCase(), contains('tomato'));
      expect(first.arrivalDate, isNotEmpty);
      expect(first.modalPrice, greaterThan(0));
      print('First history record: ${first.market} - ${first.arrivalDate}: Modal ₹${first.modalPrice}/Q');
    });

    test('mandiStatusProvider returns active verified government sync status', () async {
      final status = await container.read(mandiStatusProvider.future);

      expect(status.isLive, isTrue);
      expect(status.source, contains('Government Market Data'));
      expect(status.records, greaterThan(0));
      expect(status.govRecords, greaterThan(0));
      expect(status.lastSync, isNotNull);
      print('Live status: isLive=${status.isLive}, records=${status.records}, lastSync=${status.lastSync}');
    });
  });
}

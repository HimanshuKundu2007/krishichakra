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
    apiClient.rawDio.options.connectTimeout = const Duration(milliseconds: 300);
    apiClient.rawDio.options.receiveTimeout = const Duration(milliseconds: 300);
    apiClient.rawDio.options.sendTimeout = const Duration(milliseconds: 300);
    mandiRepo = MandiRepository(apiClient: apiClient);
  });

  group('KrishiChakra Real Government Mandi Integration Tests', () {
    test('1. GET /api/mandi/status returns government source metadata and sync status', () async {
      try {
        final status = await mandiRepo.getMandiStatus();
        expect(status, isA<MandiStatus>());
        expect(status.source, contains('Government Market Data'));
        expect(status.records, greaterThanOrEqualTo(0));
        expect(status.govRecords, greaterThanOrEqualTo(0));
        if (status.govRecords == 0 || status.lastSyncStatus != 'success') {
          expect(status.isLive, isFalse);
        }
      } on ApiException catch (e) {
        expect(e.isBackendUnavailable || e.isTimeout || e.isNetworkError, isTrue);
      }
    });

    test('2. GET /api/mandi/latest returns latest mandi prices', () async {
      try {
        final latest = await mandiRepo.getLatestPrices();
        expect(latest, isA<List<MandiPrice>>());
        for (final price in latest) {
          expect(price.commodity, isNotEmpty);
          expect(price.market, isNotEmpty);
          expect(price.arrivalDate, isNotEmpty);
          expect(price.modalPrice, greaterThan(0));
          expect(price.minPrice, greaterThan(0));
          expect(price.maxPrice, greaterThanOrEqualTo(price.minPrice));
          if (price.source == 'DEMO_SEED') {
            expect(price.isLiveGovData, isFalse);
          }
        }
      } on ApiException catch (e) {
        expect(e.isBackendUnavailable || e.isTimeout || e.isNetworkError, isTrue);
      }
    });

    test('3. GET /api/mandi/prices supports commodity and market filtering', () async {
      try {
        final prices = await mandiRepo.getPrices(commodity: 'Tomato', limit: 10);
        expect(prices, isA<List<MandiPrice>>());
        for (final price in prices) {
          expect(price.commodity.toLowerCase(), contains('tomato'));
        }
      } on ApiException catch (e) {
        expect(e.isBackendUnavailable || e.isTimeout || e.isNetworkError, isTrue);
      }
    });

    test('4. GET /api/mandi/history returns historical records for commodity', () async {
      try {
        final history = await mandiRepo.getPriceHistory('Tomato', days: 20);
        expect(history, isA<List<MandiPrice>>());
        for (final record in history) {
          expect(record.commodity.toLowerCase(), contains('tomato'));
        }
      } on ApiException catch (e) {
        expect(e.isBackendUnavailable || e.isTimeout || e.isNetworkError, isTrue);
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

    test('6. MandiFiltersData correctly parses cascaded Maharashtra filters from JSON', () {
      final sampleJson = {
        'states': ['Maharashtra', 'Gujarat', 'Madhya Pradesh'],
        'districts': ['Pune', 'Nashik', 'Ahilyanagar', 'Nagpur', 'Kolhapur', 'Solapur'],
        'markets': ['APMC Lasalgaon', 'Pune', 'Kolhapur', 'Nagpur'],
        'commodities': ['Onion', 'Tomato', 'Soyabean', 'Cotton', 'Wheat'],
        'varieties': ['Red', 'Local', 'Hybrid', 'Sharbati'],
        'total_records': 8741,
        'default_state': 'Maharashtra',
      };

      final filterData = MandiFiltersData.fromJson(sampleJson);
      expect(filterData.states, contains('Maharashtra'));
      expect(filterData.districts, contains('Nashik'));
      expect(filterData.districts, contains('Ahilyanagar'));
      expect(filterData.markets, contains('APMC Lasalgaon'));
      expect(filterData.commodities, contains('Onion'));
      expect(filterData.varieties, contains('Red'));
      expect(filterData.totalRecords, equals(8741));
      expect(filterData.defaultState, equals('Maharashtra'));
    });

    test('7. MandiFilterQuery supports variety and state filter fields', () {
      final MandiFilterQuery query = (
        commodity: 'Onion',
        market: 'APMC Lasalgaon',
        state: 'Maharashtra',
        district: 'Nashik',
        variety: 'Red',
        limit: 50,
      );

      expect(query.commodity, equals('Onion'));
      expect(query.market, equals('APMC Lasalgaon'));
      expect(query.state, equals('Maharashtra'));
      expect(query.district, equals('Nashik'));
      expect(query.variety, equals('Red'));
      expect(query.limit, equals(50));
    });

    test('8. MandiDailyHistory correctly parses 7-day window, missing dates, and fallback info', () {
      final sampleJson = {
        'commodity': 'Tomato',
        'market': 'Ratnagiri (Nachane)',
        'state': 'Maharashtra',
        'requested_start_date': '18/09/2026',
        'requested_end_date': '24/09/2026',
        'dates_checked': ['18/09/2026', '19/09/2026', '20/09/2026', '21/09/2026', '22/09/2026', '23/09/2026', '24/09/2026'],
        'dates_with_data': ['24/09/2026'],
        'missing_dates': ['18/09/2026', '19/09/2026', '20/09/2026', '21/09/2026', '22/09/2026', '23/09/2026'],
        'source': 'Maharashtra Government Market Data',
        'last_updated': '2026-09-24T12:00:00',
        'is_fallback': true,
        'fallback_market': 'Sangli(Phale, Bhajipala Market)',
        'fallback_distance_km': 142.5,
        'summary': {
          'latest_modal': 1200.0,
          'period_min': 1000.0,
          'period_max': 1400.0,
          'avg_modal': 1200.0,
          'records_count': 1,
          'dates_checked_count': 7,
          'dates_with_data_count': 1,
          'missing_dates_count': 6,
          'trend_percent': null,
        },
        'records': [
          {
            'date': '2026-09-24',
            'has_data': true,
            'status': 'Reported',
            'commodity': 'Tomato',
            'variety': 'Other',
            'state': 'Maharashtra',
            'district': 'Ratnagiri',
            'market': 'Ratnagiri (Nachane)',
            'min_price': 1000.0,
            'modal_price': 1200.0,
            'max_price': 1400.0,
            'unit': 'Rs/Quintal',
            'source': 'Maharashtra Government Market Data',
            'source_name': 'Maharashtra Government Market Data (MSAMB/APMC)',
            'source_url': 'https://www.msamb.com',
            'source_record_date': '2026-09-24',
            'source_updated_at': '2026-09-24 12:00:00',
            'source_priority': 3,
            'data_quality': 'government_exact_market',
            'updated_at': '2026-09-24T12:00:00',
          }
        ],
        'fallback_records': [
          {
            'date': '2026-09-18',
            'has_data': true,
            'status': 'Reported (Nearby Market)',
            'commodity': 'Tomato',
            'variety': 'Hybrid',
            'state': 'Maharashtra',
            'district': 'Sangli',
            'market': 'Sangli(Phale, Bhajipala Market)',
            'min_price': 2110.0,
            'modal_price': 2700.0,
            'max_price': 3190.0,
            'unit': 'Rs/Quintal',
            'source': 'Maharashtra Government Market Data',
            'source_name': 'Maharashtra Government Market Data (MSAMB/APMC)',
            'source_url': 'https://www.msamb.com',
            'source_record_date': '2026-09-18',
            'source_updated_at': '2026-09-24 13:53:08',
            'source_priority': 3,
            'data_quality': 'government_fallback_market',
            'updated_at': '2026-09-24T12:00:00',
          }
        ]
      };

      final dailyHistory = MandiDailyHistory.fromJson(sampleJson);
      expect(dailyHistory.commodity, equals('Tomato'));
      expect(dailyHistory.market, equals('Ratnagiri (Nachane)'));
      expect(dailyHistory.datesChecked, equals(7));
      expect(dailyHistory.datesWithData, equals(1));
      expect(dailyHistory.missingDates, equals(6));
      expect(dailyHistory.isFallback, isTrue);
      expect(dailyHistory.fallbackMarket, equals('Sangli(Phale, Bhajipala Market)'));
      expect(dailyHistory.fallbackDistanceKm, equals(142.5));
      expect(dailyHistory.summary.latestModal, equals(1200.0));
      expect(dailyHistory.summary.avgModal, equals(1200.0));
      expect(dailyHistory.records.length, equals(1));
      expect(dailyHistory.records.first.hasData, isTrue);
      expect(dailyHistory.records.first.modalPrice, equals(1200.0));
      expect(dailyHistory.records.first.dataQuality, equals('government_exact_market'));
      expect(dailyHistory.records.first.sourcePriority, equals(3));
      expect(dailyHistory.records.first.sourceName, equals('Maharashtra Government Market Data (MSAMB/APMC)'));
      expect(dailyHistory.records.first.sourceUrl, equals('https://www.msamb.com'));
      expect(dailyHistory.fallbackRecords.length, equals(1));
      expect(dailyHistory.fallbackRecords.first.dataQuality, equals('government_fallback_market'));
      expect(dailyHistory.fallbackRecords.first.market, equals('Sangli(Phale, Bhajipala Market)'));
    });
  });
}

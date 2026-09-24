import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krishichakra/core/api/api_client.dart';
import 'package:krishichakra/core/repositories/health_repository.dart';
import 'package:krishichakra/core/repositories/farmer_repository.dart';
import 'package:krishichakra/core/repositories/produce_repository.dart';

// In-memory secure storage using noSuchMethod for seamless version compatibility
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
  late HealthRepository healthRepo;
  late FarmerRepository farmerRepo;
  late ProduceRepository produceRepo;

  setUp(() {
    final mockStorage = InMemorySecureStorage();
    apiClient = ApiClient(storage: mockStorage);
    healthRepo = HealthRepository(apiClient: apiClient);
    farmerRepo = FarmerRepository(apiClient: apiClient);
    produceRepo = ProduceRepository(apiClient: apiClient);
  });

  group('KrishiChakra Flutter <-> FastAPI Backend Integration', () {
    test('1. GET /health returns status ok', () async {
      final health = await healthRepo.checkHealth();
      expect(health.isHealthy, isTrue);
      expect(health.status, equals('ok'));
      expect(health.service, equals('KrishiChakra API'));
      expect(health.version, equals('2.0.0'));
    });

    test('2. POST /api/farmers creates a new farmer', () async {
      final uniquePhone = '98${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final newFarmer = await farmerRepo.createFarmer(
        name: 'Ramesh Patil',
        phone: uniquePhone,
        village: 'Junnar',
        district: 'Pune',
        state: 'Maharashtra',
        landAcres: 5.5,
        vulnerabilityScore: 0.45,
        liquidityNeed: 0.6,
      );

      expect(newFarmer.id, greaterThan(0));
      expect(newFarmer.name, equals('Ramesh Patil'));
      expect(newFarmer.district, equals('Pune'));
      expect(newFarmer.landAcres, equals(5.5));
    });

    test('3. GET /api/farmers/{id} retrieves the created farmer', () async {
      final uniquePhone = '97${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final created = await farmerRepo.createFarmer(
        name: 'Suresh More',
        phone: uniquePhone,
        village: 'Ozar',
        district: 'Nashik',
        state: 'Maharashtra',
        landAcres: 3.2,
      );

      final fetched = await farmerRepo.getFarmer(created.id);
      expect(fetched.id, equals(created.id));
      expect(fetched.name, equals('Suresh More'));
      expect(fetched.district, equals('Nashik'));
    });

    test('4. POST /api/produce/lots creates a produce lot and GET /api/produce/lots/{farmer_id} retrieves it', () async {
      final uniquePhone = '96${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final farmer = await farmerRepo.createFarmer(
        name: 'Vijay Kumar',
        phone: uniquePhone,
        village: 'Lasalgaon',
        district: 'Nashik',
        state: 'Maharashtra',
      );

      final lot = await produceRepo.createProduceLot(
        farmerId: farmer.id,
        commodity: 'Red Onion',
        variety: 'Garwa',
        quantityQuintal: 25.0,
        grade: 'A',
        qualityScore: 94.0,
        harvestDate: '2026-09-20',
      );

      expect(lot.id, greaterThan(0));
      expect(lot.farmerId, equals(farmer.id));
      expect(lot.commodity, equals('Red Onion'));
      expect(lot.quantityQuintal, equals(25.0));

      final lots = await produceRepo.getFarmerLots(farmer.id);
      expect(lots, isNotEmpty);
      expect(lots.any((l) => l.id == lot.id), isTrue);
      expect(lots.firstWhere((l) => l.id == lot.id).commodity, equals('Red Onion'));
    });

    test('5. Error and timeout handling wraps exceptions into ApiException', () async {
      // Request non-existent farmer
      expect(
        () => farmerRepo.getFarmer(999999),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}

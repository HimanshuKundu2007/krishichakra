import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/api/api_client.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/shared/widgets/kc_widgets.dart';

void main() {
  group('KrishiChakra Application Reliability Unit & Widget Tests', () {
    test('ApiClient configures explicit timeouts and maps network errors cleanly', () {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:8000',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      expect(dio.options.connectTimeout, const Duration(seconds: 8));
      expect(dio.options.receiveTimeout, const Duration(seconds: 12));
      expect(dio.options.sendTimeout, const Duration(seconds: 10));

      // Test connection timeout mapping
      final timeoutErr = DioException(
        requestOptions: RequestOptions(path: '/api/mandi/prices'),
        type: DioExceptionType.connectionTimeout,
      );
      final apiEx = ApiException.fromDio(timeoutErr);
      expect(apiEx.isBackendUnavailable, isTrue);
      expect(apiEx.isNetworkError, isTrue);
      expect(apiEx.userMessage, contains('Connection timed out'));

      // Test 503 Service Unavailable mapping
      final serverDownErr = DioException(
        requestOptions: RequestOptions(path: '/api/mandi/prices'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/mandi/prices'),
          statusCode: 503,
          statusMessage: 'Service Unavailable',
        ),
        type: DioExceptionType.badResponse,
      );
      final serverDownEx = ApiException.fromDio(serverDownErr);
      expect(serverDownEx.isServerError, isTrue);
      expect(serverDownEx.isBackendUnavailable, isTrue);
      expect(serverDownEx.userMessage, contains('Server temporarily unavailable'));
    });

    test('MandiStatus correctly differentiates never-synced, live, and stale states', () {
      // 1. Never synced state (0 records)
      final neverSynced = MandiStatus(
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        hasEverSynced: false,
        govRecords: 0,
        records: 0,
        isLive: false,
        isStale: false,
        message: 'No government market data is currently available.',
      );
      expect(neverSynced.isNeverSynced, isTrue);
      expect(neverSynced.hasGovernmentRecords, isFalse);
      expect(neverSynced.hasFailedSync, isFalse);

      // 2. Live synced state
      final liveStatus = MandiStatus(
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        hasEverSynced: true,
        govRecords: 120,
        records: 120,
        latestDataDate: '2026-03-20',
        lastSuccessfulSync: '2026-03-20 10:00:00',
        isLive: true,
        isStale: false,
      );
      expect(liveStatus.isNeverSynced, isFalse);
      expect(liveStatus.hasGovernmentRecords, isTrue);
      expect(liveStatus.isLive, isTrue);

      // 3. Stale synced state (sync failed or delayed)
      final staleStatus = MandiStatus(
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        hasEverSynced: true,
        govRecords: 120,
        records: 120,
        latestDataDate: '2026-03-18',
        lastSuccessfulSync: '2026-03-18 10:00:00',
        lastSyncStatus: 'failed',
        isLive: false,
        isStale: true,
        message: 'Showing last available government data from 2026-03-18.',
      );
      expect(staleStatus.hasEverSynced, isTrue);
      expect(staleStatus.isStale, isTrue);
      expect(staleStatus.hasFailedSync, isTrue);
      expect(staleStatus.latestDataDate, '2026-03-18');
    });

    testWidgets('DataSourceTag displays exact "No government market data is currently available." when never synced',
        (tester) async {
      final unSyncedStatus = MandiStatus(
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        hasEverSynced: false,
        govRecords: 0,
        records: 0,
        isLive: false,
        isStale: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataSourceTag.fromStatus(
              status: unSyncedStatus,
            ),
          ),
        ),
      );

      // Must explicitly show the required text and NOT demo prices
      expect(
        find.text('No government market data is currently available.'),
        findsOneWidget,
      );
    });

    testWidgets('DataSourceTag indicates last available date when stale', (tester) async {
      final staleStatus = MandiStatus(
        source: 'Government Market Data (AGMARKNET / data.gov.in)',
        hasEverSynced: true,
        govRecords: 45,
        records: 45,
        latestDataDate: '2026-03-18',
        lastSuccessfulSync: '2026-03-18 09:30:00',
        isLive: false,
        isStale: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataSourceTag.fromStatus(
              status: staleStatus,
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Showing last available government data (2026-03-18)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Last sync: 18/03/2026 09:30'),
        findsOneWidget,
      );
    });

    testWidgets('KcBackendUnavailableState renders diagnostic message and invokes retry callback',
        (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KcBackendUnavailableState(
              title: 'Backend Unavailable',
              message: 'Cannot reach server at http://127.0.0.1:8000',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Backend Unavailable'), findsOneWidget);
      expect(find.text('Cannot reach server at http://127.0.0.1:8000'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('KcLoadingIndicator renders spinner with informative message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KcLoadingIndicator(
              message: 'Contacting Agmarknet official repository...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Contacting Agmarknet official repository...'),
        findsOneWidget,
      );
    });

    testWidgets('KcEmptyState renders icon, title, description, and action button', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KcEmptyState(
              title: 'No Active Transporters',
              message: 'No logistics providers have registered for this transit corridor.',
              icon: Icons.local_shipping_outlined,
              actionLabel: 'Refresh Transporters',
              action: () => refreshed = true,
            ),
          ),
        ),
      );

      expect(find.text('No Active Transporters'), findsOneWidget);
      expect(
        find.text('No logistics providers have registered for this transit corridor.'),
        findsOneWidget,
      );
      expect(find.text('Refresh Transporters'), findsOneWidget);

      await tester.tap(find.text('Refresh Transporters'));
      await tester.pump();
      expect(refreshed, isTrue);
    });
  });
}

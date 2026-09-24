import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/logistics_repository.dart';
import 'package:krishichakra/features/logistics/screens/logistics_booking_screen.dart';
import 'package:krishichakra/features/logistics/screens/storage_booking_screen.dart';

void main() {
  group('Logistics and Storage Models & Repository Tests', () {
    test('LogisticsOption parses from JSON with all Stitch fields', () {
      final json = {
        'id': 1,
        'provider_name': 'Maha AgriHaul Express',
        'vehicle_type': 'Tata 407 LCV',
        'vehicle_number': 'MH-14-AZ-4921',
        'driver_name': 'Suresh Shinde',
        'driver_phone': '+91 98220 12345',
        'driver_rating': 4.9,
        'verified_trips': 142,
        'origin': 'Junnar Farm Gate',
        'destination': 'Vashi APMC',
        'cost_per_quintal': 160.0,
        'capacity_quintal': 25.0,
        'is_empty_return': true,
        'discount_percentage': 35.0,
        'distance_km': 124.0,
        'transit_duration_minutes': 220,
        'ventilated': true,
        'gps_active': true,
        'departure_time': 'Today • 05:00 PM',
        'available': true,
      };

      final opt = LogisticsOption.fromJson(json);
      expect(opt.id, 1);
      expect(opt.providerName, 'Maha AgriHaul Express');
      expect(opt.vehicleType, 'Tata 407 LCV');
      expect(opt.vehicleNumber, 'MH-14-AZ-4921');
      expect(opt.driverName, 'Suresh Shinde');
      expect(opt.driverRating, 4.9);
      expect(opt.verifiedTrips, 142);
      expect(opt.costPerQuintal, 160.0);
      expect(opt.isEmptyReturn, true);
      expect(opt.discountPercentage, 35.0);
      expect(opt.ventilated, true);
      expect(opt.gpsActive, true);
      expect(opt.available, true);
    });

    test('StorageOption parses from JSON with MSWC & e-NWR fields', () {
      final json = {
        'id': 10,
        'provider_name': 'MSWC Nashik Cold Storage',
        'location': 'Ambad Warehousing Zone, Nashik',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'capacity_quintal': 5000.0,
        'available_capacity_quintal': 1200.0,
        'cost_per_quintal_day': 1.50,
        'distance_km': 45.0,
        'storage_type': 'Cold Storage',
        'is_certified': true,
        'enwr_loan_eligible': true,
        'loan_advance_pct': 70.0,
        'available': true,
      };

      final storage = StorageOption.fromJson(json);
      expect(storage.id, 10);
      expect(storage.providerName, 'MSWC Nashik Cold Storage');
      expect(storage.costPerQuintalDay, 1.50);
      expect(storage.isCertified, true);
      expect(storage.enwrLoanEligible, true);
      expect(storage.loanAdvancePct, 70.0);
      expect(storage.available, true);
    });
  });

  group('LogisticsBookingScreen UI Widget Tests', () {
    testWidgets('Renders all Stitch transport components and completes booking',
        (tester) async {
      // Set high physical size for full sliver view rendering
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockLogistics = [
        const LogisticsOption(
          id: 1,
          providerName: 'Maha AgriHaul Express',
          vehicleType: 'Tata 407 LCV',
          vehicleNumber: 'MH-14-AZ-4921',
          driverName: 'Suresh Shinde',
          driverPhone: '+91 98220 12345',
          driverRating: 4.9,
          verifiedTrips: 142,
          origin: 'Junnar, Pune',
          destination: 'Vashi APMC',
          costPerQuintal: 160.0,
          capacityQuintal: 25.0,
          isEmptyReturn: true,
          discountPercentage: 35.0,
          distanceKm: 124.0,
          transitDurationMinutes: 220,
          ventilated: true,
          gpsActive: true,
          departureTime: 'Today • 05:00 PM',
          available: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logisticsOptionsProvider
                .overrideWith((ref) async => mockLogistics),
          ],
          child: const MaterialApp(
            home: LogisticsBookingScreen(
              lotId: 'ON-9021',
              crop: 'Onion',
              quantityQuintals: 20.0,
              origin: 'Junnar, Pune',
              destination: 'Vashi APMC',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header & Breadcrumb
      expect(find.text('Farm-to-Mandi Transport'), findsOneWidget);
      expect(find.text('124 km Express'), findsOneWidget);
      expect(find.text('Junnar → Vashi APMC'), findsOneWidget);

      // Active Lot Context
      expect(find.text('Lot #ON-9021'), findsOneWidget);
      expect(find.text('Agmarknet Grade-A'), findsOneWidget);
      expect(find.text('20 Quintals'), findsOneWidget);
      expect(find.text('Pre-weighed'), findsOneWidget);

      // Route Map Telemetry
      expect(find.text('GPS Signal: Strong (10s live)'), findsOneWidget);
      expect(find.text('Toll Fastag Incl.'), findsOneWidget);
      expect(find.text('3 hrs 40 mins transit drive'), findsOneWidget);

      // Empty Return Hero Freight Card
      expect(find.text('35% Discount (Empty Returning Truck)'), findsOneWidget);
      expect(find.text('Tata 407 LCV'), findsAtLeastNWidgets(1));
      expect(find.text('Suresh Shinde'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('(142 Verified Mandi Trips)'), findsOneWidget);
      expect(find.text('Call Driver'), findsOneWidget);
      expect(find.text('Today • 05:00 PM'), findsOneWidget);
      expect(find.text('₹160 / Quintal • Zero Hidden Fees'), findsOneWidget);

      // 4-Stage Milestone Tracker
      expect(find.text('Transit Milestones'), findsOneWidget);
      expect(find.text('QR Synced'), findsOneWidget);
      expect(find.text('Farm Gate Loading & Crate QR Scan'), findsOneWidget);
      expect(find.text('On Route - NH60 Highway'), findsOneWidget);
      expect(find.text('APMC Weighbridge Gate Arrival'), findsOneWidget);
      expect(find.text('Delivery Receipt & Settlement'), findsOneWidget);

      // Action Bar: Share GPS & Freight Shield
      expect(find.text('Share Live GPS Link with Buyer / FPO'), findsOneWidget);
      expect(find.text('AgriStack Freight Shield Included'), findsOneWidget);
      expect(find.text('1800-180-1551 (Toll-Free)'), findsOneWidget);

      // Tap Confirm Booking
      final bookBtn = find.text('Confirm Truck Booking (Pay on Delivery)');
      expect(bookBtn, findsOneWidget);
      await tester.tap(bookBtn);
      await tester.pump();
      expect(find.text('Confirming Booking...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Truck Booked (Driver Dispatched)'), findsOneWidget);
    });
  });

  group('StorageBookingScreen UI Widget Tests', () {
    testWidgets('Renders e-NWR banner, storage list and loan calculator',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockStorage = [
        const StorageOption(
          id: 1,
          providerName: 'MSWC Nashik Cold Storage',
          location: 'Ambad Warehousing Hub',
          capacityQuintal: 5000,
          availableCapacityQuintal: 1200,
          costPerQuintalDay: 1.5,
          distanceKm: 45,
          isCertified: true,
          enwrLoanEligible: true,
          loanAdvancePct: 70.0,
          available: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageOptionsProvider.overrideWith((ref) async => mockStorage),
          ],
          child: const MaterialApp(
            home: StorageBookingScreen(
              lotId: 'ON-9021',
              crop: 'Onion',
              quantityQuintals: 20.0,
              benchmarkPrice: 2400.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // e-NWR Banner
      expect(find.text('Electronic Warehouse Receipt (e-NWR)'), findsOneWidget);
      expect(find.text('70% Instant Cash Advance'), findsOneWidget);
      expect(find.text('Disbursed in 4 Hours'), findsOneWidget);

      // Produce Context
      expect(find.text('Lot #ON-9021'), findsOneWidget);
      expect(find.text('20 Quintals Onion'), findsOneWidget);
      expect(find.text('Grade-A Verified'), findsOneWidget);
      expect(find.text('₹48000'), findsOneWidget); // 20 * 2400

      // Storage List
      expect(find.text('MSWC Nashik Cold Storage'), findsOneWidget);
      expect(find.text('MSWC Certified'), findsOneWidget);
      expect(find.text('e-NWR 70% Loan'), findsOneWidget);
      expect(find.text('₹1.50'), findsOneWidget);

      // Loan Calculator
      expect(find.text('e-NWR Instant Cash Advance'), findsOneWidget);
      // 70% of 48,000 = 33,600
      expect(find.text('₹33600'), findsOneWidget);
      // Daily storage rent: 1.5 * 20 = 30.0 / day
      expect(find.text('₹30.0 / day'), findsOneWidget);

      // Book & Apply Action
      final bookLoanBtn = find.text('Book Storage & Apply e-NWR Loan');
      expect(bookLoanBtn, findsOneWidget);
      await tester.tap(bookLoanBtn);
      await tester.pump();
      expect(find.text('Submitting e-NWR Loan Request...'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Space Reserved & e-NWR Loan Applied'), findsOneWidget);
    });
  });
}

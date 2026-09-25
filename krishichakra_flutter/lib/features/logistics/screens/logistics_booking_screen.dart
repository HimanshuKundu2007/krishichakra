import '../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/logistics_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/kc_widgets.dart';

class LogisticsBookingScreen extends ConsumerStatefulWidget {
  const LogisticsBookingScreen({
    super.key,
    this.lotId = 'ON-9021',
    this.crop = 'Onion',
    this.quantityQuintals = 20.0,
    this.origin = 'Junnar, Pune',
    this.destination = 'Vashi APMC, Mumbai',
  });

  final String lotId;
  final String crop;
  final double quantityQuintals;
  final String origin;
  final String destination;

  @override
  ConsumerState<LogisticsBookingScreen> createState() =>
      _LogisticsBookingScreenState();
}

class _LogisticsBookingScreenState extends ConsumerState<LogisticsBookingScreen> {
  int? _selectedOptionId;
  bool _isBooking = false;
  bool _isBooked = false;
  bool _copiedGps = false;

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(logisticsOptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(logisticsOptionsProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: false,
              pinned: true,
              expandedHeight: AppSpacing.headerHeight,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: 'Farm-to-Mandi Transport',
                subtitle: 'Return-Truck Pool • 35% Discount',
                showBack: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh transport options',
                    onPressed: () => ref.invalidate(logisticsOptionsProvider),
                  ),
                ],
              ),
              toolbarHeight: AppSpacing.headerHeight,
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.sm),

                // Sub-Header & Breadcrumb Bar
                _buildBreadcrumbBar(),
                const SizedBox(height: AppSpacing.md),

                // 1. Active Harvest Lot Context Banner
                _buildActiveLotCard(),
                const SizedBox(height: AppSpacing.md),

                // 2. Simulated Route Map Card
                _buildRouteMapCard(),
                const SizedBox(height: AppSpacing.md),

                // 3. Live Logistics Options Section
                _buildLogisticsList(optionsAsync),
                const SizedBox(height: AppSpacing.md),

                // 4. 4-Stage Live Milestone Tracker
                _buildMilestoneTracker(),
                const SizedBox(height: AppSpacing.md),

                // 5. Actions, Shield & Helpline Strip
                _buildFooterActions(),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBreadcrumbBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOGISTICS DISPATCH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${widget.origin.split(',').first} â†’ ${widget.destination.split(',').first}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '124 km Express',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveLotCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lot #${widget.lotId}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDCC3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified,
                            size: 13, color: Color(0xFF5C2F00)),
                        SizedBox(width: 3),
                        Text(
                          'Agmarknet Grade-A',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5C2F00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.pin_drop,
                      size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    widget.origin,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.quantityQuintals.toStringAsFixed(0)} Quintals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '40 Crates • Premium ${widget.crop} (Nashik-Junnar Belt)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Pre-weighed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMapCard() {
    return Container(
      height: 208,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Vector Map Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _RouteMapPainter(),
            ),
          ),
          // Top Telemetry Badges
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'GPS Signal: Strong (10s live)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.toll, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Toll Fastag Incl.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Origin Label
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Junnar Gate',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface),
                      ),
                      Text(
                        'Origin km 0',
                        style: TextStyle(
                            fontSize: 9, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Alephata Mid-Route Marker
          Positioned(
            top: 60,
            left: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.local_shipping, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MH-14 • Alephata',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      Text(
                        'Speed 48 km/h',
                        style: TextStyle(fontSize: 8, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom Transit Duration Pill
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF283044).withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.timer, size: 14, color: Color(0xFF6FFBBE)),
                  SizedBox(width: 5),
                  Text(
                    '3 hrs 40 mins transit drive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsList(AsyncValue<List<LogisticsOption>> optionsAsync) {
    return optionsAsync.when(
      loading: () => const KcLoadingIndicator(
        message: 'Finding verified transport routes...',
      ),
      error: (err, _) => KcBackendUnavailableState(
        message: 'Unable to load logistics options: $err',
        onRetry: () => ref.invalidate(logisticsOptionsProvider),
      ),
      data: (options) {
        if (options.isEmpty) {
          return KcEmptyState(
            title: 'No Transport Options Found',
            message: 'No transport providers are currently available for this route.',
            icon: Icons.local_shipping_outlined,
            actionLabel: 'Refresh Routes',
            action: () => ref.invalidate(logisticsOptionsProvider),
          );
        }

        // Set default selection to first option if not selected
        final selectedOpt = options.firstWhere(
          (o) => o.id == _selectedOptionId,
          orElse: () => options.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Discount Card for Selected / Best Option
            _buildFreightHeroCard(selectedOpt),
            const SizedBox(height: AppSpacing.md),

            // Available Transport Alternatives Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Vehicles (${options.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Tap to select',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Vehicle Cards List
            ...options.map((opt) {
              final isSelected = opt.id == selectedOpt.id;
              return _buildVehicleCard(opt, isSelected);
            }),
          ],
        );
      },
    );
  }

  Widget _buildFreightHeroCard(LogisticsOption opt) {
    final discountPct = opt.discountPercentage > 0 ? opt.discountPercentage : 35.0;
    final totalCost = opt.costPerQuintal * widget.quantityQuintals;
    final originalCost = totalCost / (1 - (discountPct / 100));
    final savings = originalCost - totalCost;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ribbon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${discountPct.toStringAsFixed(0)}% Discount (Empty Returning Truck)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Save ₹${savings.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Save ₹${savings.toStringAsFixed(0)} by booking an empty commercial truck returning on the ${opt.origin} to ${opt.destination} corridor.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle info container
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_bus,
                      size: 28, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.vehicleType,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${opt.capacityQuintal.toStringAsFixed(0)} Quintals Capacity • Fits Produce Lot',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (opt.vehicleNumber != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                opt.vehicleNumber!,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (opt.ventilated) ...[
                            Icon(Icons.air,
                                size: 12, color: AppColors.secondary),
                            const SizedBox(width: 2),
                            const Text(
                              'Ventilated',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (opt.gpsActive) ...[
                            Icon(Icons.sensors,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 2),
                            const Text(
                              'GPS Active',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Driver Credibility Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceContainer,
                    child: Icon(Icons.person,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            opt.driverName ?? 'Suresh Shinde',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.verified,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 13, color: Color(0xFFE5A100)),
                          const SizedBox(width: 2),
                          Text(
                            opt.driverRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${opt.verifiedTrips} Verified Mandi Trips)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${opt.driverName ?? "Driver"} (${opt.driverPhone ?? "+91 98220 12345"})...'),
                    ),
                  );
                },
                icon: Icon(Icons.call, size: 16),
                label: const Text('Call Driver'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 40),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.outline.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fare & Pickup Timing Grid
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Empty Return Rate',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${totalCost.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${originalCost.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.outline,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${opt.costPerQuintal.toStringAsFixed(0)} / Quintal • Zero Hidden Fees',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.outline.withOpacity(0.15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guaranteed Pickup',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt.departureTime ?? 'Today • 05:00 PM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Direct farm gate loading',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Primary Booking Action
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isBooking
                  ? null
                  : () async {
                      setState(() => _isBooking = true);
                      await Future.delayed(const Duration(milliseconds: 900));
                      if (mounted) {
                        setState(() {
                          _isBooking = false;
                          _isBooked = true;
                          _selectedOptionId = opt.id;
                        });
                        ref.read(selectedLogisticsOptionProvider.notifier).select(opt);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text(
                                'Truck Booked! Driver ${opt.driverName ?? "Suresh"} notified for pickup.'),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isBooked ? AppColors.secondary : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
              ),
              child: _isBooking
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Confirming Booking...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isBooked
                              ? 'Truck Booked (Driver Dispatched)'
                              : 'Confirm Truck Booking (Pay on Delivery)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_isBooked ? Icons.check_circle : Icons.arrow_forward,
                            size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
              SizedBox(width: 4),
              Text(
                'No advance needed • Payout deducted at APMC or Cash on Delivery',
                style: TextStyle(
                    fontSize: 10, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(LogisticsOption opt, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOptionId = opt.id;
          _isBooked = false;
        });
        ref.read(selectedLogisticsOptionProvider.notifier).select(opt);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: AppColors.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withOpacity(0.2)
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_shipping,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        opt.vehicleType,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (opt.isEmptyReturn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${opt.discountPercentage.toStringAsFixed(0)}% Off',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${opt.providerName} • ${opt.driverName ?? "Driver"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${opt.costPerQuintal.toStringAsFixed(0)} / Q',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '₹${(opt.costPerQuintal * widget.quantityQuintals).toStringAsFixed(0)} Total',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneTracker() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transit Milestones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Farm-to-Mandi e-Way Bill tracking',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.qr_code_2, size: 14, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      'QR Synced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Milestone 1: Done
          _buildMilestoneStep(
            icon: Icons.check,
            iconBg: AppColors.primary,
            iconColor: Colors.white,
            title: 'Farm Gate Loading & Crate QR Scan',
            tag: 'Done',
            tagColor: AppColors.secondary,
            description:
                '05:15 PM • 40 Crates Scanned • Zero transit disputes guaranteed',
            seal: 'Digital Consignment Seal #AG-4982',
            isDone: true,
          ),

          // Milestone 2: Active In Transit
          _buildMilestoneStep(
            icon: Icons.navigation,
            iconBg: AppColors.secondary,
            iconColor: Colors.white,
            title: 'On Route - NH60 Highway',
            tag: 'In Transit',
            tagColor: AppColors.primary,
            description: 'Speed: 48 km/h • Current location: Khed Ghat section',
            extraBox: 'ETA to Vashi APMC: 08:55 PM Tonight',
            isActive: true,
          ),

          // Milestone 3: Upcoming
          _buildMilestoneStep(
            icon: Icons.scale,
            iconBg: AppColors.surfaceContainerHigh,
            iconColor: AppColors.outline,
            title: 'APMC Weighbridge Gate Arrival',
            tag: 'Upcoming',
            tagColor: AppColors.outline,
            description:
                'Automated digital weight slip generation at Gate No. 4, Vashi APMC.',
          ),

          // Milestone 4: Upcoming Final
          _buildMilestoneStep(
            icon: Icons.receipt_long,
            iconBg: AppColors.surfaceContainerHigh,
            iconColor: AppColors.outline,
            title: 'Delivery Receipt & Settlement',
            tag: 'Upcoming',
            tagColor: AppColors.outline,
            description:
                'Buyer acceptance sign-off & instant escrow release directly to bank account.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneStep({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String tag,
    required Color tagColor,
    required String description,
    String? seal,
    String? extraBox,
    bool isDone = false,
    bool isActive = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator column
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? AppColors.primary
                        : AppColors.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (seal != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            seal,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (extraBox != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ETA to Vashi APMC:',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant),
                          ),
                          Text(
                            '08:55 PM Tonight',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    return Column(
      children: [
        // Share GPS Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => _copiedGps = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Live GPS Tracking link copied to clipboard! (Ready to share with Buyer / FPO)'),
                ),
              );
            },
            icon: Icon(
              _copiedGps ? Icons.check : Icons.share_location,
              color: AppColors.secondary,
              size: 20,
            ),
            label: Text(
              _copiedGps
                  ? 'Tracking Link Copied to Clipboard!'
                  : 'Share Live GPS Link with Buyer / FPO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(color: AppColors.outline.withOpacity(0.15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // AgriStack Freight Shield
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgriStack Freight Shield Included',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'In-transit produce spoilage and road accident transit insurance covered up to ₹1,00,00,000 at zero extra premium.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Helpline Strip
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.support_agent,
                    size: 16, color: AppColors.onSurfaceVariant),
                SizedBox(width: 4),
                Text(
                  'Transport Control Desk',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const Text(
              '1800-180-1551 (Toll-Free)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF006C49)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trackPath = Path();
    trackPath.moveTo(size.width * 0.15, size.height * 0.78);
    trackPath.cubicTo(
      size.width * 0.35,
      size.height * 0.65,
      size.width * 0.55,
      size.height * 0.45,
      size.width * 0.85,
      size.height * 0.22,
    );
    canvas.drawPath(trackPath, trackPaint);

    final progressPath = Path();
    progressPath.moveTo(size.width * 0.15, size.height * 0.78);
    progressPath.cubicTo(
      size.width * 0.30,
      size.height * 0.70,
      size.width * 0.40,
      size.height * 0.58,
      size.width * 0.50,
      size.height * 0.48,
    );
    canvas.drawPath(progressPath, progressPaint);

    // Origin Pin
    final originPaint = Paint()..color = const Color(0xFF00450D);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.78), 7, originPaint);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.78), 3, Paint()..color = Colors.white);

    // Dest Pin
    final destPaint = Paint()..color = const Color(0xFF5C2F00);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.22), 7, destPaint);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.22), 3, Paint()..color = Colors.white);

    // Live Moving Truck Indicator
    final truckPaint = Paint()..color = const Color(0xFF006C49);
    canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.48), 9, truckPaint);
    canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.48), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

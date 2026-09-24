import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/api/api_client.dart';
import '../../../core/repositories/logistics_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/kc_widgets.dart';

class StorageBookingScreen extends ConsumerStatefulWidget {
  const StorageBookingScreen({
    super.key,
    this.lotId = 'ON-9021',
    this.crop = 'Onion',
    this.quantityQuintals = 20.0,
    this.benchmarkPrice = 2400.0,
  });

  final String lotId;
  final String crop;
  final double quantityQuintals;
  final double benchmarkPrice;

  @override
  ConsumerState<StorageBookingScreen> createState() =>
      _StorageBookingScreenState();
}

class _StorageBookingScreenState extends ConsumerState<StorageBookingScreen> {
  int? _selectedStorageId;
  int _holdingDays = 30;
  bool _isBooking = false;
  bool _isBooked = false;

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(storageOptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storageOptionsProvider);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              expandedHeight: AppSpacing.headerHeight,
              backgroundColor: Colors.transparent,
              flexibleSpace: KcAppBar(
                title: 'Storage & Emergency Cash',
                subtitle: "Don't sell cheap. Store & get 70% loan.",
                showBack: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh storage facilities',
                    onPressed: () => ref.invalidate(storageOptionsProvider),
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

                // 1. MSWC e-NWR Instant Cash Advance Banner
                _buildEnwrBanner(),
                const SizedBox(height: AppSpacing.md),

                // 2. Active Produce Context
                _buildLotContextCard(),
                const SizedBox(height: AppSpacing.md),

                // 3. Storage Facilities Live List
                _buildStorageList(storageAsync),
                const SizedBox(height: AppSpacing.md),

                // 4. Instant Cash Advance Loan Calculator
                _buildLoanCalculator(storageAsync),
                const SizedBox(height: AppSpacing.md),

                // 5. Assurance & Helpline Strip
                _buildAssuranceStrip(),
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEnwrBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warehouse,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Electronic Warehouse Receipt (e-NWR)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'WDRA & MSWC Accredited Warehouses',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Deposit your harvest in accredited cold storage. An instant digital e-NWR receipt is generated on your AgriStack ID, entitling you to an immediate 70% working capital loan directly in your bank account.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFeaturePill(Icons.account_balance, '70% Instant Cash Advance'),
              const SizedBox(width: 8),
              _buildFeaturePill(Icons.speed, 'Disbursed in 4 Hours'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotContextCard() {
    final estValue = widget.quantityQuintals * widget.benchmarkPrice;

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
                      borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(width: 8),
                  Text(
                    '${widget.quantityQuintals.toStringAsFixed(0)} Quintals ${widget.crop}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Grade-A Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Lot Value',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '₹${estValue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Benchmark Mandi Rate',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '₹${widget.benchmarkPrice.toStringAsFixed(0)} / Q',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageList(AsyncValue<List<StorageOption>> storageAsync) {
    return storageAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: const KcLoadingIndicator(
            message: 'Loading WDRA-accredited cold storage facilities...',
          ),
        ),
      ),
      error: (err, _) {
        if (err is ApiException && err.isBackendUnavailable) {
          return KcBackendUnavailableState(
            onRetry: () => ref.invalidate(storageOptionsProvider),
          );
        }
        return KcErrorState(
          message: 'Failed to load storage facilities: $err',
          onRetry: () => ref.invalidate(storageOptionsProvider),
        );
      },
      data: (facilities) {
        if (facilities.isEmpty) {
          return const KcEmptyState(
            title: 'No Storage Facilities Available',
            message:
                'No accredited cold storage warehouses found matching this district. Please check nearby districts.',
            icon: Icons.warehouse_outlined,
          );
        }

        final selected = facilities.firstWhere(
          (f) => f.id == _selectedStorageId,
          orElse: () => facilities.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accredited Cold Storages (${facilities.length})',
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
            ...facilities.map((fac) {
              final isSelected = fac.id == selected.id;
              return _buildFacilityCard(fac, isSelected);
            }),
          ],
        );
      },
    );
  }

  Widget _buildFacilityCard(StorageOption fac, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStorageId = fac.id;
          _isBooked = false;
        });
        ref.read(selectedStorageOptionProvider.notifier).select(fac);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: AppColors.outline.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryContainer.withOpacity(0.2)
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.ac_unit,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fac.providerName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${fac.location} • ${fac.distanceKm?.toStringAsFixed(0) ?? "12"} km away',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${fac.costPerQuintalDay.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '/ Q / day',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (fac.isCertified) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified,
                            size: 12, color: AppColors.secondary),
                        SizedBox(width: 3),
                        Text(
                          'MSWC Certified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (fac.enwrLoanEligible) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDCC3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.account_balance,
                            size: 12, color: Color(0xFF5C2F00)),
                        SizedBox(width: 3),
                        Text(
                          'e-NWR 70% Loan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5C2F00),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '${fac.availableCapacityQuintal?.toStringAsFixed(0) ?? "1200"} Q space free',
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

  Widget _buildLoanCalculator(AsyncValue<List<StorageOption>> storageAsync) {
    final facilities = storageAsync.asData?.value ?? [];
    final selected = facilities.firstWhere(
      (f) => f.id == _selectedStorageId,
      orElse: () => facilities.isNotEmpty
          ? facilities.first
          : StorageOption(
              id: 1,
              providerName: 'MSWC Nashik Cold Storage',
              location: 'Ambad Hub',
              capacityQuintal: 5000,
              costPerQuintalDay: 1.5,
              available: true,
            ),
    );

    final lotValue = widget.quantityQuintals * widget.benchmarkPrice;
    final loanAmount = (lotValue * (selected.loanAdvancePct / 100));
    final storageDailyCost = selected.costPerQuintalDay * widget.quantityQuintals;
    final totalStorageCost = storageDailyCost * _holdingDays;

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
              Text(
                'e-NWR Instant Cash Advance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '70% Valuation Advance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Loan Amount Display Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Eligible Cash Loan:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹${loanAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Storage Rent (${widget.quantityQuintals.toStringAsFixed(0)} Q):',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹${storageDailyCost.toStringAsFixed(1)} / day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Holding Period (${_holdingDays} days):',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₹${totalStorageCost.toStringAsFixed(0)} Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Holding days chips
          Row(
            children: [
              Text(
                'Holding Target:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              ...[15, 30, 60].map((d) {
                final isSelected = _holdingDays == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$d Days'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _holdingDays = d);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Book Storage & Loan Button
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
                        });
                        ref.read(selectedStorageOptionProvider.notifier).select(selected);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text(
                                'Storage Booked at ${selected.providerName}! e-NWR Loan Application (₹${loanAmount.toStringAsFixed(0)}) submitted.'),
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
                        Text('Submitting e-NWR Loan Request...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isBooked
                              ? 'Space Reserved & e-NWR Loan Applied'
                              : 'Book Storage & Apply e-NWR Loan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_isBooked ? Icons.check_circle : Icons.account_balance,
                            size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'No collateral needed • Repaid automatically upon produce sale',
              style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssuranceStrip() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.phone_in_talk, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'MSWC Warehousing Desk',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Text(
            '1800-233-1080 (Toll-Free)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

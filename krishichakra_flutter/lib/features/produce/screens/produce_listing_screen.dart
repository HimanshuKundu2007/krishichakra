import '../../../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/farmer_repository.dart';
import '../../../core/repositories/produce_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_app_bar.dart';
import '../../../shared/widgets/kc_widgets.dart';

// â”€â”€â”€ Screen entry point â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Screen: List Your Harvest — Produce Lot & AI Grading
/// Faithful to the Stitch design (krishichakra_produce_listing_ai_grading).
class ProduceListingScreen extends ConsumerStatefulWidget {
  const ProduceListingScreen({super.key});

  @override
  ConsumerState<ProduceListingScreen> createState() =>
      _ProduceListingScreenState();
}

class _ProduceListingScreenState
    extends ConsumerState<ProduceListingScreen> {
  static String _formatAmount(double amount) {
    final intVal = amount.round();
    final s = intVal.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final remaining = s.substring(0, s.length - 3);
    final formatted = remaining.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$formatted,$last3';
  }

  // ── Step management ────────────────────────────────────────────────────────
  int _currentStep = 0; // 0: Photo & Harvest, 1: Location & FPO, 2: Price Lock

  // ── Form state (Step 1) ────────────────────────────────────────────────────
  String _commodity = 'Onion';
  String _variety = 'Nasik Red';
  double _quantity = 20.0;
  String _grade = 'A';
  bool _isListening = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ── Camera / image state ───────────────────────────────────────────────────
  XFile? _imageFile;
  String? _imageBase64;
  bool _isGrading = false;
  ProduceGradeResult? _gradeResult;

  // ── Location & FPO state (Step 2) ──────────────────────────────────────────
  String _state = 'Maharashtra';
  String _district = 'Pune';
  String _market = 'Junnar';
  String _village = 'Otur';
  String _fpoName = 'Sahyadri Farmers Producer Co.';
  bool _enableFpoPool = false;
  bool _transportAssistance = true;

  // ── Price Lock state (Step 3) ──────────────────────────────────────────────
  double _basePricePerQ = 2200.0;
  bool _enableQrTraceability = true;
  bool _priceLockConfirmed = false;

  final ImagePicker _picker = ImagePicker();

  // â”€â”€ Computed values â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int get _crateCount => (_quantity * 2).round(); // 1Q â‰ˆ 2 crates of 50kg
  double get _estimatedGrossValue =>
      _quantity * _basePricePerQ * (_enableFpoPool ? 1.068 : 1.0);

  // â”€â”€ Image pick â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 75);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        _imageFile = file;
        _imageBase64 = b64;
        _gradeResult = null;
        _errorMessage = null;
      });
      await _runGrading();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _runGrading() async {
    setState(() {
      _isGrading = true;
      _gradeResult = null;
    });
    try {
      final repo = ref.read(produceRepositoryProvider);
      final result = await repo.gradeProduce(
        crop: _commodity.trim().isNotEmpty ? _commodity : 'Onion',
        imageBytesBase64: _imageBase64,
      );
      if (mounted) {
        setState(() {
          _gradeResult = result;
          if (result.grade != null) _grade = result.grade!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Grading assistant unavailable ($e). You may select a grade manually.'),
            backgroundColor: AppColors.tertiary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGrading = false);
    }
  }

    void _handleVoiceMicTap() {
    setState(() {
      _isListening = true;
      _commodity = 'Onion';
      _variety = 'Nasik Red';
      _quantity = 20.0;
      _grade = 'A';
      _state = 'Maharashtra';
      _district = 'Pune';
      _market = 'Junnar';
      _basePricePerQ = 2200.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.mic, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Voice Recognized: "20 quintals Red Onion Grade A, Junnar"',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isListening = false);
    });
  }

  // ── Submit lot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _submitLot() async {
    if (_commodity.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a crop/commodity name.')),
      );
      return;
    }

    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please specify a positive lot quantity.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final farmerId = ref.read(currentFarmerIdProvider) ?? 1;
      final repo = ref.read(produceRepositoryProvider);

      final newLot = await repo.createProduceLot(
        farmerId: farmerId,
        commodity: _commodity.trim(),
        variety: _variety.trim().isEmpty ? null : _variety.trim(),
        quantityQuintal: _quantity,
        grade: _grade,
        qualityScore: _gradeResult?.qualityScore,
        harvestDate: DateTime.now().toIso8601String().substring(0, 10),
      );

      ref.invalidate(farmerLotsProvider(farmerId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lot #${newLot.id} published! Grade ${newLot.grade ?? _grade}',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );

      final uri = Uri(
        path: AppRoutes.buyerMatches,
        queryParameters: {
          'lot_id': newLot.id.toString(),
          'commodity': _commodity.trim(),
          'variety': _variety.trim(),
          'quantity': _quantity.toString(),
          'grade': _grade,
          'market': _market,
          'expected_price': _basePricePerQ.round().toString(),
        },
      );
      context.push(uri.toString());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // â”€â”€ Quantity stepper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _goToStep2() {
    if (_commodity.trim().isEmpty) {
      setState(() => _errorMessage = 'Please select or enter a crop/commodity.');
      return;
    }
    if (_quantity <= 0) {
      setState(() => _errorMessage = 'Please specify a positive harvest quantity.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _currentStep = 1;
    });
  }

  void _goToStep3() {
    setState(() {
      _errorMessage = null;
      _currentStep = 2;
    });
  }

  void _confirmPriceLock() {
    setState(() => _priceLockConfirmed = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.verified_user, color: AppColors.secondary, size: 24),
            SizedBox(width: 8),
            Text('Price Lock Confirmed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commodity: $_commodity ($_variety)', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Quantity: ${_quantity.round()} Q (${_crateCount} Crates)'),
            const SizedBox(height: 4),
            Text('Market: $_market Mandi, $_district'),
            const SizedBox(height: 4),
            Text('Locked Benchmark: ₹${_basePricePerQ.round()}/Q', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Estimated Gross: ₹${_formatAmount(_estimatedGrossValue)}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓ KrishiChakra Smart Escrow & Dispute Shield activated for this deal.',
                style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _incrementQty() =>
      setState(() => _quantity = (_quantity + 5).clamp(1, 500));
  void _decrementQty() =>
      setState(() => _quantity = (_quantity - 5).clamp(1, 500));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: false,
            pinned: true,
            expandedHeight: AppSpacing.headerHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: KcAppBar(
              title: 'List Your Harvest',
              subtitle: _currentStep == 0
                  ? 'Step 1 of 3 — Photo & Harvest Details'
                  : _currentStep == 1
                      ? 'Step 2 of 3 — Location & FPO'
                      : 'Step 3 of 3 — Price Lock',
              showBack: true,
              onBack: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                }
              },
            ),
            toolbarHeight: AppSpacing.headerHeight,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl * 2,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Step progress bar
                _StepBar(current: _currentStep),
                const SizedBox(height: AppSpacing.md),

                // ── STEP 1: Photo & Harvest Details ─────────────────────────
                if (_currentStep == 0) ...[
                  _CameraCard(
                    imageFile: _imageFile,
                    imageBase64: _imageBase64,
                    isGrading: _isGrading,
                    gradeResult: _gradeResult,
                    onTapCamera: () => _showImageSourceSheet(context),
                    onRetake: () => _pickImage(ImageSource.camera),
                    onChange: () => _showImageSourceSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_gradeResult != null) ...[
                    _GradingResultBanner(result: _gradeResult!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  VoiceSearchBar(
                    hint: 'Say: "20 quintals Red Onion Grade A, Junnar"',
                    isListening: _isListening,
                    onMicTap: _handleVoiceMicTap,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_errorMessage != null) ...[
                    _ErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  _CropDetailsCard(
                    commodity: _commodity,
                    variety: _variety,
                    quantity: _quantity,
                    grade: _grade,
                    onCommodityChanged: (v) => setState(() => _commodity = v),
                    onVarietyChanged: (v) => setState(() => _variety = v),
                    onGradeChanged: (v) => setState(() => _grade = v),
                    onIncrement: _incrementQty,
                    onDecrement: _decrementQty,
                    crateCount: _crateCount,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  ElevatedButton(
                    onPressed: _goToStep2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Continue to Location & FPO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],

                // ── STEP 2: Location & FPO ──────────────────────────────────
                if (_currentStep == 1) ...[
                  _LocationFpoStepCard(
                    state: _state,
                    district: _district,
                    market: _market,
                    village: _village,
                    fpoName: _fpoName,
                    transportAssistance: _transportAssistance,
                    onStateChanged: (v) => setState(() => _state = v),
                    onDistrictChanged: (v) => setState(() => _district = v),
                    onMarketChanged: (v) => setState(() => _market = v),
                    onVillageChanged: (v) => setState(() => _village = v),
                    onFpoChanged: (v) => setState(() => _fpoName = v),
                    onTransportChanged: (v) => setState(() => _transportAssistance = v),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _FpoPoolCard(
                    enabled: _enableFpoPool,
                    onToggle: (v) => setState(() => _enableFpoPool = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _currentStep = 0),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _goToStep3,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Continue to Price Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── STEP 3: Price Lock & Publish ────────────────────────────
                if (_currentStep == 2) ...[
                  // Summary review card
                  _HarvestReviewCard(
                    commodity: _commodity,
                    variety: _variety,
                    quantity: _quantity,
                    crateCount: _crateCount,
                    grade: _grade,
                    state: _state,
                    district: _district,
                    market: _market,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _PriceEstimateCard(
                    basePricePerQ: _basePricePerQ,
                    quantity: _quantity,
                    estimatedGross: _estimatedGrossValue,
                    onPriceChanged: (v) => setState(() => _basePricePerQ = v),
                    fpoBonus: _enableFpoPool,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _QrTraceabilityCard(
                    enabled: _enableQrTraceability,
                    crateCount: _crateCount,
                    onToggle: (v) => setState(() => _enableQrTraceability = v),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _MandiPriceLockCard(
                    commodity: _commodity,
                    market: _market,
                    basePricePerQ: _basePricePerQ,
                    isLocked: _priceLockConfirmed,
                    onLockTap: _confirmPriceLock,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (_errorMessage != null) ...[
                    _ErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _currentStep = 1),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: _PublishButton(
                          isSubmitting: _isSubmitting,
                          onPressed: _submitLot,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: AppColors.secondary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            // Quick demo grading without an image
            ListTile(
              leading: Icon(Icons.science_outlined,
                  color: AppColors.tertiary),
              title: const Text('Run Inspection (Demo — no photo)'),
              subtitle: const Text('Integration boundary prototype'),
              onTap: () {
                Navigator.pop(context);
                _runGrading();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Step bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});
  final int current;

  static const _labels = ['Photo & Harvest', 'Location & FPO', 'Price Lock'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == current;
          final done = i < current;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: (done || active)
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
                      color: active
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Camera / image upload card with scanning grid overlay
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CameraCard extends StatelessWidget {
  const _CameraCard({
    required this.imageFile,
    this.imageBase64,
    required this.isGrading,
    required this.gradeResult,
    required this.onTapCamera,
    required this.onRetake,
    required this.onChange,
  });

  final XFile? imageFile;
  final String? imageBase64;
  final bool isGrading;
  final ProduceGradeResult? gradeResult;
  final VoidCallback onTapCamera;
  final VoidCallback onRetake;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage = imageBase64 != null && imageBase64!.isNotEmpty;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGrading
              ? AppColors.primary
              : (hasImage ? AppColors.secondary : AppColors.outlineVariant),
          width: isGrading ? 2 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background: image preview or placeholder
          if (hasImage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.06),
                child: Image.memory(
                  base64Decode(imageBase64!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _CameraPlaceholder(
                    isGrading: isGrading,
                    onTap: onTapCamera,
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: _CameraPlaceholder(
                isGrading: isGrading,
                onTap: onTapCamera,
              ),
            ),

          // Scanning grid overlay when grading
          if (isGrading) const _ScanGridOverlay(),

          // Bounding markers overlay (from grading result)
          if (gradeResult != null && gradeResult!.detectedMarkers.isNotEmpty)
            _MarkersOverlay(markers: gradeResult!.detectedMarkers),

          // Uploaded status badge
          if (hasImage && !isGrading)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      '✓ Photo uploaded',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Grading spinner in corner
          if (isGrading)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI Quality Check — Prototype',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons when photo is uploaded
          if (hasImage)
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: onRetake,
                        icon: const Icon(Icons.camera_alt_outlined, size: 14),
                        label: const Text(
                          'Retake Photo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.7),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: onChange,
                        icon: const Icon(Icons.photo_library_outlined, size: 14),
                        label: const Text(
                          'Change Photo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.95),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Tap hint button
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.isGrading,
    this.onTap,
  });

  final bool isGrading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isGrading
                    ? AppColors.primaryFixed.withValues(alpha: 0.3)
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGrading ? Icons.science_outlined : Icons.camera_alt_outlined,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isGrading
                  ? 'AI Quality Check — Prototype'
                  : 'Take or Upload Produce Photo',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isGrading
                  ? 'Analyzing produce image features…'
                  : 'Camera or gallery — checks produce quality',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanGridOverlay extends StatelessWidget {
  const _ScanGridOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Corner brackets
    final bracket = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    const br = 16.0;
    const bm = 20.0;
    // top-left
    canvas.drawLine(
        Offset(bm, bm), Offset(bm + br, bm), bracket);
    canvas.drawLine(
        Offset(bm, bm), Offset(bm, bm + br), bracket);
    // top-right
    canvas.drawLine(
        Offset(size.width - bm, bm),
        Offset(size.width - bm - br, bm),
        bracket);
    canvas.drawLine(
        Offset(size.width - bm, bm),
        Offset(size.width - bm, bm + br),
        bracket);
    // bottom-left
    canvas.drawLine(
        Offset(bm, size.height - bm),
        Offset(bm + br, size.height - bm),
        bracket);
    canvas.drawLine(
        Offset(bm, size.height - bm),
        Offset(bm, size.height - bm - br),
        bracket);
    // bottom-right
    canvas.drawLine(
        Offset(size.width - bm, size.height - bm),
        Offset(size.width - bm - br, size.height - bm),
        bracket);
    canvas.drawLine(
        Offset(size.width - bm, size.height - bm),
        Offset(size.width - bm, size.height - bm - br),
        bracket);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarkersOverlay extends StatelessWidget {
  const _MarkersOverlay({required this.markers});
  final List<ProduceBoundingMarker> markers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Stack(
            children: markers.map((m) {
              final x = m.x * constraints.maxWidth;
              final y = m.y * constraints.maxHeight;
              return Positioned(
                left: x.clamp(0, constraints.maxWidth - 80),
                top: y.clamp(0, constraints.maxHeight - 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Grading result banner
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _GradingResultBanner extends StatelessWidget {
  const _GradingResultBanner({required this.result});
  final ProduceGradeResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUnsupported = result.status == 'model_not_available';

    return Container(
      decoration: BoxDecoration(
        color: isUnsupported
            ? AppColors.surfaceContainerHigh
            : AppColors.primaryFixed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnsupported
              ? AppColors.outlineVariant
              : AppColors.primaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUnsupported
                  ? AppColors.surfaceContainerHigh
                  : AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(
                  isUnsupported
                      ? Icons.science_outlined
                      : Icons.check_circle_outline,
                  color: isUnsupported
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUnsupported
                            ? 'Manual Quality Selection'
                            : 'Produce Quality Check: Grade ${result.grade ?? "A"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Text(
                        'AI Quality Check — Prototype',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Prototype badge — always visible
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'PROTOTYPE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isUnsupported) ...[
            // Diagnostic metrics pill bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  _MetricPill(
                    label: 'Uniformity',
                    value: '${result.uniformityPct?.toStringAsFixed(0) ?? "--"}%',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  _MetricPill(
                    label: 'Moisture',
                    value: '${result.moisturePct?.toStringAsFixed(0) ?? "--"}%',
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 8),
                  _MetricPill(
                    label: 'Pest Dmg',
                    value: '${result.pestDamagePct?.toStringAsFixed(1) ?? "--"}%',
                    color: result.pestDamagePct == 0
                        ? AppColors.primary
                        : Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Disclaimer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 13,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    result.disclaimer.isNotEmpty
                        ? result.disclaimer
                        : 'Integration boundary prototype • Agmarknet Grade ${result.grade ?? "A"} baseline',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Error banner
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: AppColors.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close,
                size: 16, color: AppColors.onErrorContainer),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Crop details card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CropDetailsCard extends StatelessWidget {
  const _CropDetailsCard({
    required this.commodity,
    required this.variety,
    required this.quantity,
    required this.grade,
    required this.crateCount,
    required this.onCommodityChanged,
    required this.onVarietyChanged,
    required this.onGradeChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String commodity;
  final String variety;
  final double quantity;
  final String grade;
  final int crateCount;
  final ValueChanged<String> onCommodityChanged;
  final ValueChanged<String> onVarietyChanged;
  final ValueChanged<String> onGradeChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Crop Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _FieldLabel('Crop / Commodity'),
          TextFormField(
            initialValue: commodity,
            onChanged: onCommodityChanged,
            decoration: const InputDecoration(
              hintText: 'e.g. Onion, Tomato, Soybean',
              prefixIcon: Icon(Icons.eco_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _FieldLabel('Variety'),
          TextFormField(
            initialValue: variety,
            onChanged: onVarietyChanged,
            decoration: const InputDecoration(
              hintText: 'e.g. Nasik Red, Hybrid, Yellow',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _FieldLabel('Quantity (Quintal)'),
          Row(
            children: [
              // Decrement button
              _StepperBtn(icon: Icons.remove, onTap: onDecrement),
              const SizedBox(width: AppSpacing.sm),
              // Display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${quantity.round()} Q',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '$crateCount Crates of 50 kg each',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Increment button
              _StepperBtn(icon: Icons.add, onTap: onIncrement),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          _FieldLabel('Quality Grade'),
          Row(
            children: ['A', 'B', 'C'].map((g) {
              final selected = grade == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text('Grade $g'),
                    selected: selected,
                    selectedColor: AppColors.primaryFixed,
                    onSelected: (val) {
                      if (val) onGradeChanged(g);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryContainer),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Price estimate card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PriceEstimateCard extends StatelessWidget {
  const _PriceEstimateCard({
    required this.basePricePerQ,
    required this.quantity,
    required this.estimatedGross,
    required this.onPriceChanged,
    required this.fpoBonus,
  });

  final double basePricePerQ;
  final double quantity;
  final double estimatedGross;
  final ValueChanged<double> onPriceChanged;
  final bool fpoBonus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expected Price & Gross Value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FieldLabel('Expected Base Price per Quintal (₹)'),
          Slider(
            value: basePricePerQ.clamp(500, 8000),
            min: 500,
            max: 8000,
            divisions: 150,
            label: '₹${basePricePerQ.round()}',
            activeColor: AppColors.primaryContainer,
            onChanged: onPriceChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${basePricePerQ.round()}/Q × ${quantity.round()} Q',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'â‰ˆ ₹${estimatedGross.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          if (fpoBonus) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.trending_up,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 5),
                const Text(
                  'FPO Institutional Premium: +₹150/Q included',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 12, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'KrishiChakra estimate — not a guaranteed future price.',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Crate QR traceability card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _QrTraceabilityCard extends StatelessWidget {
  const _QrTraceabilityCard({
    required this.enabled,
    required this.crateCount,
    required this.onToggle,
  });

  final bool enabled;
  final int crateCount;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final previewCrates = ['#C-01', '#C-02', '#C-03', '…#C-${crateCount.toString().padLeft(2, "0")}'];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crate-Level QR Traceability',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Serialized Crate QR Codes · Dispute Shield',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            // Crate sticker preview row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: previewCrates.map((code) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primaryContainer),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.qr_code,
                            color: AppColors.primary, size: 28),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 13, color: AppColors.secondary),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Dispute Shield: Immutable scan log prevents weight & quality fraud at delivery.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// FPO bulk pooling card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FpoPoolCard extends StatelessWidget {
  const _FpoPoolCard({required this.enabled, required this.onToggle});
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.secondaryContainer.withValues(alpha: 0.3)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? AppColors.secondary.withValues(alpha: 0.4)
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.secondary.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              color: enabled ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Junnar FPO Bulk Pool',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  enabled
                      ? '+₹150/Q Institutional Premium — Active'
                      : 'Join FPO lot for institutional buyers (+₹150/Q)',
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
                    fontWeight:
                        enabled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Publish button
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.people_alt_outlined, size: 20),
        label: Text(
          isSubmitting
              ? 'Publishing Lot on Server…'
              : 'Publish Lot & Receive Buyer Bids',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Field label helper
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Location & FPO Card
// ─────────────────────────────────────────────────────────────────────────────
class _LocationFpoStepCard extends StatelessWidget {
  const _LocationFpoStepCard({
    required this.state,
    required this.district,
    required this.market,
    required this.village,
    required this.fpoName,
    required this.transportAssistance,
    required this.onStateChanged,
    required this.onDistrictChanged,
    required this.onMarketChanged,
    required this.onVillageChanged,
    required this.onFpoChanged,
    required this.onTransportChanged,
  });

  final String state;
  final String district;
  final String market;
  final String village;
  final String fpoName;
  final bool transportAssistance;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onDistrictChanged;
  final ValueChanged<String> onMarketChanged;
  final ValueChanged<String> onVillageChanged;
  final ValueChanged<String> onFpoChanged;
  final ValueChanged<bool> onTransportChanged;

  @override
  Widget build(BuildContext context) {
    final states = ['Maharashtra', 'Madhya Pradesh', 'Gujarat', 'Karnataka'];
    final districts = ['Nashik', 'Pune', 'Ahmednagar', 'Solapur', 'Kolhapur', 'Nagpur', 'Aurangabad'];
    final mandis = [
      'Lasalgaon APMC',
      'Pimpalgaon APMC',
      'Junnar APMC',
      'Pune APMC',
      'Vashi APMC (Mumbai)',
      'Nashik APMC',
      'Ahmednagar APMC',
    ];
    final fpos = [
      'Sahyadri Farmer Producer Co. Ltd.',
      'Junnar Krishi Vikas FPO',
      'MahaFPC District Consortium',
      'Nashik Onion & Agri Producers Co.',
    ];

    final effectiveState = states.contains(state) ? state : states.first;
    final effectiveDistrict = districts.contains(district) ? district : districts.first;
    final effectiveMarket = mandis.contains(market) ? market : mandis.first;
    final effectiveFpo = fpos.contains(fpoName) ? fpoName : fpos.first;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, color: AppColors.primaryContainer, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Farmgate Location & APMC Linkage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Origin farm, target mandi and aggregation hub', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // State and District
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('State'),
                    DropdownButtonFormField<String>(
                      value: effectiveState,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) { if (v != null) onStateChanged(v); },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('District'),
                    DropdownButtonFormField<String>(
                      value: effectiveDistrict,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) { if (v != null) onDistrictChanged(v); },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Target Mandi
          const _FieldLabel('Target Mandi / APMC Yard'),
          DropdownButtonFormField<String>(
            value: effectiveMarket,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: mandis.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) onMarketChanged(v); },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Village / Farm address
          const _FieldLabel('Village / Farmgate Landmark'),
          TextFormField(
            initialValue: village,
            decoration: InputDecoration(
              hintText: 'e.g., Junnar, Taluka Junnar',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: onVillageChanged,
          ),
          const SizedBox(height: AppSpacing.sm),

          // FPO Consortium
          const _FieldLabel('Affiliated FPO Consortium'),
          DropdownButtonFormField<String>(
            value: effectiveFpo,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: fpos.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) onFpoChanged(v); },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Transport Assistance switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Farmgate Logistics Pickup', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Connect with verified transporters nearby', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Switch(
                  value: transportAssistance,
                  onChanged: onTransportChanged,
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Harvest Review Card
// ─────────────────────────────────────────────────────────────────────────────
class _HarvestReviewCard extends StatelessWidget {
  const _HarvestReviewCard({
    required this.commodity,
    required this.variety,
    required this.quantity,
    required this.crateCount,
    required this.grade,
    required this.state,
    required this.district,
    required this.market,
  });

  final String commodity;
  final String variety;
  final double quantity;
  final int crateCount;
  final String grade;
  final String state;
  final String district;
  final String market;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fact_check_outlined, color: AppColors.primaryContainer, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lot Review & Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Summary of details configured in Steps 1 & 2', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Grade $grade', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _reviewItem('Crop & Variety', '$commodity ($variety)'),
              _reviewItem('Quantity', '${quantity.toStringAsFixed(0)} Q ($crateCount Crates)'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _reviewItem('Origin', '$district, $state'),
              _reviewItem('Target Mandi', market),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: APMC Mandi Price Lock Card
// ─────────────────────────────────────────────────────────────────────────────
class _MandiPriceLockCard extends StatelessWidget {
  const _MandiPriceLockCard({
    required this.commodity,
    required this.market,
    required this.basePricePerQ,
    required this.isLocked,
    required this.onLockTap,
  });

  final String commodity;
  final String market;
  final double basePricePerQ;
  final bool isLocked;
  final VoidCallback onLockTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked ? AppColors.primary : AppColors.outlineVariant,
          width: isLocked ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                color: isLocked ? AppColors.primary : AppColors.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isLocked ? 'Price Lock Active' : 'APMC Mandi Price Lock Guarantee',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLocked ? AppColors.primary : AppColors.onSurface,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                    Text(
                      isLocked
                          ? 'Floor price ₹${basePricePerQ.toStringAsFixed(0)}/Q guaranteed against market drops'
                          : 'Benchmarked with $market real-time rates',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Smart Contract Floor: Bids below ₹${basePricePerQ.toStringAsFixed(0)}/Q will be automatically rejected by KrishiChakra contract.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLockTap,
              icon: Icon(isLocked ? Icons.check_circle : Icons.lock_outline, size: 16),
              label: Text(
                isLocked ? 'Price Lock Verified (Tap to edit)' : 'Confirm & Lock Floor Price',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isLocked ? AppColors.primary : AppColors.primaryContainer,
                side: BorderSide(color: isLocked ? AppColors.primary : AppColors.primaryContainer),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

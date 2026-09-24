import 'dart:convert';
import 'dart:math' as math;
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

// ─── Screen entry point ────────────────────────────────────────────────────────

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
  // ── Form state ────────────────────────────────────────────────────────────
  String _commodity = 'Onion';
  String _variety = 'Nasik Red';
  double _quantity = 20.0;
  String _grade = 'A';
  bool _isListening = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ── Camera / image state ──────────────────────────────────────────────────
  XFile? _imageFile;
  String? _imageBase64;
  bool _isGrading = false;
  ProduceGradeResult? _gradeResult;

  // ── Additional options state ──────────────────────────────────────────────
  double _basePricePerQ = 2200.0;
  bool _enableQrTraceability = true;
  bool _enableFpoPool = false;

  final ImagePicker _picker = ImagePicker();

  // ── Computed values ───────────────────────────────────────────────────────
  int get _crateCount => (_quantity * 2).round(); // 1Q ≈ 2 crates of 50kg
  double get _estimatedGrossValue =>
      _quantity * _basePricePerQ * (_enableFpoPool ? 1.068 : 1.0);

  // ── Image pick ────────────────────────────────────────────────────────────
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

  // ── Submit lot ────────────────────────────────────────────────────────────
  Future<void> _submitLot() async {
    if (_commodity.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a crop/commodity name.')),
      );
      return;
    }

    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify a positive lot quantity.')),
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

      context.push('${AppRoutes.buyerMatches}?lot_id=${newLot.id}');
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

  // ── Quantity stepper ──────────────────────────────────────────────────────
  void _incrementQty() =>
      setState(() => _quantity = (_quantity + 5).clamp(1, 500));
  void _decrementQty() =>
      setState(() => _quantity = (_quantity - 5).clamp(1, 500));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            expandedHeight: AppSpacing.headerHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: KcAppBar(
              title: 'List Your Harvest',
              subtitle: 'Step 1 of 3 — Photo & Harvest Details',
              showBack: true,
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
                _StepBar(current: 0),
                const SizedBox(height: AppSpacing.md),

                // ── Camera / image upload card ──────────────────────────────
                _CameraCard(
                  imageFile: _imageFile,
                  isGrading: _isGrading,
                  gradeResult: _gradeResult,
                  onTapCamera: () => _showImageSourceSheet(context),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Grading result banner (only after grading) ──────────────
                if (_gradeResult != null) ...[
                  _GradingResultBanner(result: _gradeResult!),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Voice search bar ────────────────────────────────────────
                VoiceSearchBar(
                  hint: 'Say: "20 quintals Red Onion Grade A, Junnar"',
                  isListening: _isListening,
                  onMicTap: () =>
                      setState(() => _isListening = !_isListening),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Error banner ────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  _ErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Crop details form ───────────────────────────────────────
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
                const SizedBox(height: AppSpacing.md),

                // ── Base price & estimated gross ────────────────────────────
                _PriceEstimateCard(
                  basePricePerQ: _basePricePerQ,
                  quantity: _quantity,
                  estimatedGross: _estimatedGrossValue,
                  onPriceChanged: (v) =>
                      setState(() => _basePricePerQ = v),
                  fpoBonus: _enableFpoPool,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Crate QR traceability card ──────────────────────────────
                _QrTraceabilityCard(
                  enabled: _enableQrTraceability,
                  crateCount: _crateCount,
                  onToggle: (v) =>
                      setState(() => _enableQrTraceability = v),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── FPO bulk pooling ────────────────────────────────────────
                _FpoPoolCard(
                  enabled: _enableFpoPool,
                  onToggle: (v) =>
                      setState(() => _enableFpoPool = v),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Publish button ──────────────────────────────────────────
                _PublishButton(
                  isSubmitting: _isSubmitting,
                  onPressed: _submitLot,
                ),
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
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.secondary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            // Quick demo grading without an image
            ListTile(
              leading: const Icon(Icons.science_outlined,
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

// ──────────────────────────────────────────────────────────────────────────────
// Step bar
// ──────────────────────────────────────────────────────────────────────────────
class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});
  final int current;

  static const _labels = ['Photo & Harvest', 'Location & FPO', 'Price Lock'];

  @override
  Widget build(BuildContext context) {
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

// ──────────────────────────────────────────────────────────────────────────────
// Camera / image upload card with scanning grid overlay
// ──────────────────────────────────────────────────────────────────────────────
class _CameraCard extends StatelessWidget {
  const _CameraCard({
    required this.imageFile,
    required this.isGrading,
    required this.gradeResult,
    required this.onTapCamera,
  });

  final XFile? imageFile;
  final bool isGrading;
  final ProduceGradeResult? gradeResult;
  final VoidCallback onTapCamera;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCamera,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGrading
                ? AppColors.primary
                : AppColors.outlineVariant,
            width: isGrading ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background: image preview or placeholder
            if (imageFile != null)
              Positioned.fill(
                child: Image.network(
                  imageFile!.path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _CameraPlaceholder(
                    isGrading: isGrading,
                  ),
                ),
              )
            else
              _CameraPlaceholder(isGrading: isGrading),

            // Scanning grid overlay when grading
            if (isGrading) const _ScanGridOverlay(),

            // Bounding markers overlay (from grading result)
            if (gradeResult != null && gradeResult!.detectedMarkers.isNotEmpty)
              _MarkersOverlay(markers: gradeResult!.detectedMarkers),

            // Grading spinner in corner
            if (isGrading)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Inspecting…',
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

            // Camera icon tap hint in bottom-right
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
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.isGrading});
  final bool isGrading;

  @override
  Widget build(BuildContext context) {
    return Center(
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
                ? 'Running Inspection Prototype…'
                : 'Tap to Take / Upload Produce Photo',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isGrading
                ? 'Integration boundary prototype'
                : 'Camera or gallery — triggers automated inspection',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanGridOverlay extends StatelessWidget {
  const _ScanGridOverlay();

  @override
  Widget build(BuildContext context) {
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

// ──────────────────────────────────────────────────────────────────────────────
// Grading result banner
// ──────────────────────────────────────────────────────────────────────────────
class _GradingResultBanner extends StatelessWidget {
  const _GradingResultBanner({required this.result});
  final ProduceGradeResult result;

  @override
  Widget build(BuildContext context) {
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
                            ? 'Crop Not Yet Supported'
                            : 'Automated Inspection Prototype: Grade ${result.grade ?? "A"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Integration Boundary Prototype • Not AI Certified',
                        style: const TextStyle(
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
                const Icon(
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

// ──────────────────────────────────────────────────────────────────────────────
// Error banner
// ──────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
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
            icon: const Icon(Icons.close,
                size: 16, color: AppColors.onErrorContainer),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Crop details card
// ──────────────────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────────────────
// Price estimate card
// ──────────────────────────────────────────────────────────────────────────────
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
                  '≈ ₹${estimatedGross.toStringAsFixed(0)}',
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
                const Icon(Icons.trending_up,
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
              const Icon(Icons.info_outline,
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

// ──────────────────────────────────────────────────────────────────────────────
// Crate QR traceability card
// ──────────────────────────────────────────────────────────────────────────────
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
              const Icon(Icons.qr_code_2_outlined,
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
                        const Icon(Icons.qr_code,
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
                const Icon(Icons.shield_outlined,
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

// ──────────────────────────────────────────────────────────────────────────────
// FPO bulk pooling card
// ──────────────────────────────────────────────────────────────────────────────
class _FpoPoolCard extends StatelessWidget {
  const _FpoPoolCard({required this.enabled, required this.onToggle});
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
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

// ──────────────────────────────────────────────────────────────────────────────
// Publish button
// ──────────────────────────────────────────────────────────────────────────────
class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
            : const Icon(Icons.people_alt_outlined, size: 20),
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

// ──────────────────────────────────────────────────────────────────────────────
// Field label helper
// ──────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
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

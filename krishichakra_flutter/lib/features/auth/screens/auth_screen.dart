import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

import '../../../shared/widgets/krishichakra_logo.dart';
import '../../../core/providers/language_provider.dart';

/// Screen 1 Ã¢â‚¬â€ Authentication
/// Faithfully reproduces the Stitch KrishiChakra auth screen:
///  - Language switcher (EN / Ã Â¤Â¹Ã Â¤Â¿Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¦Ã Â¥â‚¬ / Ã Â¤Â®Ã Â¤Â°Ã Â¤Â¾Ã Â¤Â Ã Â¥â‚¬)
///  - Phone + OTP input
///  - Role picker (Farmer/FPO | Buyer/Trader | Transporter)
///  - Trust badges
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/health_repository.dart';
import '../../../core/repositories/farmer_repository.dart';

/// Screen 1 Ã¢â‚¬â€ Authentication
/// Faithfully reproduces the Stitch KrishiChakra auth screen:
///  - Language switcher (EN / Ã Â¤Â¹Ã Â¤Â¿Ã Â¤Â¨Ã Â¥ÂÃ Â¤Â¦Ã Â¥â‚¬ / Ã Â¤Â®Ã Â¤Â°Ã Â¤Â¾Ã Â¤Â Ã Â¥â‚¬)
///  - Phone + OTP input
///  - Role picker (Farmer/FPO | Buyer/Trader | Transporter)
///  - Trust badges
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // Ã¢â€â‚¬Ã¢â€â‚¬ State Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // Global language managed by languageProvider
  String _role = 'farmer';
  String _phone = '';
  final List<String> _otp = ['', '', '', ''];
  bool _otpSent = false;
  bool _loading = false;
  int _resendSeconds = 30;
  bool _isListening = false;

  final _focusNodes = List.generate(4, (_) => FocusNode());
  final _otpControllers = List.generate(4, (_) => TextEditingController());

  // Ã¢â€â‚¬Ã¢â€â‚¬ Helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  bool get _phoneValid => _phone.length == 10;

  void _sendOtp() {
    if (!_phoneValid) return;
    setState(() {
      _otpSent = true;
      _resendSeconds = 30;
      _loading = false;
    });
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      return _resendSeconds > 0;
    });
  }

  Future<void> _verifyAndEnter() async {
    final entered = _otp.join();
    if (entered.length == 4) {
      setState(() => _loading = true);
      try {
        final repo = ref.read(farmerRepositoryProvider);
        final farmer = await repo.createFarmer(
          name: 'Ramesh Patil',
          phone: _phone.isNotEmpty ? _phone : '9876543210',
          village: 'Junnar',
          district: 'Pune',
          state: 'Maharashtra',
          landAcres: 4.5,
        );
        ref.read(currentFarmerIdProvider.notifier).setFarmerId(farmer.id);
      } catch (_) {
        // Fallback to default farmer ID if offline
        ref.read(currentFarmerIdProvider.notifier).setFarmerId(1);
      } finally {
        if (mounted) {
          setState(() => _loading = false);
          context.go(AppRoutes.home);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Build Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _Header(),
                const SizedBox(height: AppSpacing.md),
                Consumer(
                  builder: (ctx, ref, _) {
                    final currentLocale = ref.watch(languageProvider);
                    return _LanguageSwitcher(
                      selected: currentLocale.languageCode,
                      onChanged: (l) => ref.read(languageProvider.notifier).setLocale(Locale(l)),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _PhoneInput(
                  onChanged: (v) => setState(() => _phone = v),
                  enabled: !_otpSent,
                  isListening: _isListening,
                  onMicTap: () => setState(() => _isListening = !_isListening),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!_otpSent)
                  _PrimaryButton(
                    label: 'Send OTP (SMS)',
                    icon: Icons.sms_outlined,
                    onPressed: _phoneValid ? _sendOtp : null,
                  )
                else ...[
                  _OtpGrid(
                    controllers: _otpControllers,
                    focusNodes: _focusNodes,
                    onChanged: (idx, val) {
                      setState(() => _otp[idx] = val);
                      if (val.isNotEmpty && idx < 3) {
                        _focusNodes[idx + 1].requestFocus();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ResendRow(
                    seconds: _resendSeconds,
                    onResend: _resendSeconds == 0 ? _sendOtp : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.md),
                _RolePicker(
                  selected: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TrustBadges(),
                const SizedBox(height: AppSpacing.md),
                _PrimaryButton(
                  label: 'Verify & Enter KrishiChakra',
                  icon: Icons.arrow_forward,
                  trailing: true,
                  onPressed: _otpSent && _otp.join().length == 4
                      ? _verifyAndEnter
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Sub-widgets Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final healthAsync = ref.watch(backendHealthProvider);

    return Column(
      children: [
        // Logo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KrishiChakraLogo(size: 48, showShadow: true),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KrishiChakra',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AGRI-OS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSecondaryContainer,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Strengthening Market Linkages\nfor Every Farmer',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Live backend status badge
        InkWell(
          onTap: () => ref.invalidate(backendHealthProvider),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: healthAsync.when(
                data: (h) => h.isHealthy
                    ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                    : AppColors.errorContainer,
                loading: () => AppColors.surfaceContainerHigh,
                error: (_, __) => AppColors.surfaceContainerHigh,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: healthAsync.when(
                  data: (h) => h.isHealthy
                      ? AppColors.secondary
                      : AppColors.error,
                  loading: () => AppColors.outlineVariant,
                  error: (_, __) => AppColors.outlineVariant,
                ),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: healthAsync.when(
                      data: (h) => h.isHealthy
                          ? AppColors.secondary
                          : AppColors.error,
                      loading: () => Colors.grey,
                      error: (_, __) => Colors.orange,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  healthAsync.when(
                    data: (h) => h.isHealthy
                        ? 'FastAPI Connected (v${h.version})'
                        : 'Server Status: ${h.status}',
                    loading: () => 'Connecting to backend...',
                    error: (_, __) => 'Offline / Tap to Retry',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: healthAsync.when(
                      data: (h) => h.isHealthy
                          ? AppColors.secondary
                          : AppColors.error,
                      loading: () => AppColors.onSurfaceVariant,
                      error: (_, __) => AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher(
      {required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _langs = [
    ('en', 'English'),
    ('hi', 'हिन्दी'),
    ('mr', 'मराठी'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _langs.map((l) {
          final isSelected = l.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(l.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    l.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  const _PhoneInput({
    required this.onChanged,
    required this.enabled,
    required this.isListening,
    required this.onMicTap,
  });

  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool isListening;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          // Country code
          Container(
            width: 64,
            alignment: Alignment.center,
            child: Text(
              '+91',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Container(
              width: 1, height: 32, color: AppColors.outlineVariant),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: onChanged,
              enabled: enabled,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                hintStyle: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ),
          // Voice mic "Bolie"
          _MicTouchTarget(isListening: isListening, onTap: onMicTap),
        ],
      ),
    );
  }
}

class _MicTouchTarget extends StatelessWidget {
  const _MicTouchTarget({required this.isListening, required this.onTap});
  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? AppColors.secondary : AppColors.primary,
              size: 22,
            ),
            Text(
              'Ã Â¤Â¬Ã Â¥â€¹Ã Â¤Â²Ã Â¤Â¿Ã Â¤Â',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpGrid extends StatelessWidget {
  const _OtpGrid({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == 3 ? 0 : 6,
            ),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) => onChanged(i, v),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.seconds, required this.onResend});
  final int seconds;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          seconds > 0 ? 'Resend OTP in ${seconds}s' : 'Didn\'t receive OTP? ',
          style: TextStyle(
              fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        if (onResend != null)
          TextButton(
            onPressed: onResend,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              'Resend',
              style: TextStyle(
                  color: AppColors.secondary, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _roles = [
    (
      'farmer',
      '🌾',
      'Farmer / FPO Member',
      'Zero Commission • Instant MSP Alerts'
    ),
    (
      'buyer',
      'Ã°Å¸ÂÂ¢',
      'Institutional Buyer / Trader',
      'Pan-India Delivery • Assured Grades'
    ),
    (
      'transporter',
      '🚚',
      'Transporter / Driver',
      'Same-Day Settlement • Pooled Routes'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'I am a',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._roles.map((r) => _RoleCard(
              emoji: r.$2,
              title: r.$3,
              subtitle: r.$4,
              isSelected: selected == r.$1,
              onTap: () => onChanged(r.$1),
            )),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withOpacity(0.1)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
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
    );
  }
}

class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge(
          icon: Icons.account_balance_outlined,
          label: 'Govt. AgriStack Ready',
        ),
        const SizedBox(width: AppSpacing.xs),
        _Badge(
          icon: Icons.verified_user_outlined,
          label: 'e-NAM & MSWC',
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.trailing = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHigh,
          foregroundColor: onPressed != null
              ? AppColors.onPrimary
              : AppColors.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!trailing) Icon(icon, size: 20),
            if (!trailing) const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (trailing) const SizedBox(width: AppSpacing.xs),
            if (trailing) Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

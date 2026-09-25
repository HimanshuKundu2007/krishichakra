import 'package:flutter/material.dart';

/// Reusable KrishiChakra brand logo widget.
///
/// Uses the actual PNG asset from assets/branding/krishichakra_logo.png.
/// Fallback: neutral rounded KC text placeholder (never the generic leaf icon).
///
/// Usage:
///   KrishiChakraLogo(size: 36)   // header bar
///   KrishiChakraLogo(size: 48)   // auth screen
///   KrishiChakraLogo(size: 64)   // splash / onboarding
class KrishiChakraLogo extends StatelessWidget {
  const KrishiChakraLogo({
    super.key,
    this.size = 36,
    this.showShadow = false,
  });

  /// Width and height of the logo (it is square / circular).
  final double size;

  /// Whether to add a subtle drop-shadow (useful on white backgrounds).
  final bool showShadow;

  static const String _assetPath = 'assets/branding/krishichakra_logo.png';

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackLogo(size: size),
    );

    if (showShadow) {
      logo = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: logo,
      );
    }

    return SizedBox(width: size, height: size, child: logo);
  }
}

/// Neutral fallback shown only if the asset file cannot be loaded.
class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2D7A3A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'KC',
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

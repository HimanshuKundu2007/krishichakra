import 'package:flutter/material.dart';

/// Reusable widget for displaying standardized, high-quality commodity icons.
///
/// Automatically normalizes commodity name variants (e.g., 'Brinjal', 'Eggplant',
/// 'Paddy', 'Rice', etc.) and loads local offline asset graphics with a fallback.
class CommodityIcon extends StatelessWidget {
  const CommodityIcon({
    super.key,
    required this.commodity,
    this.size = 24.0,
    this.showBackground = false,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Name of the commodity (e.g., 'Onion', 'Potato', 'Brinjal', 'Eggplant', 'Paddy (Dhan)')
  final String commodity;

  /// Width and height of the icon
  final double size;

  /// Whether to wrap the icon in a soft rounded background container
  final bool showBackground;

  /// Background color when [showBackground] is true
  final Color? backgroundColor;

  /// Border radius when [showBackground] is true
  final BorderRadius? borderRadius;

  /// Normalizes any commodity name variant to the matching local asset path.
  static String getAssetPath(String rawName) {
    final lower = rawName.toLowerCase().trim();

    if (lower.contains('onion') || lower.contains('pyaz') || lower.contains('kanda')) {
      return 'assets/commodities/onion.png';
    }
    if (lower.contains('potato') || lower.contains('alu') || lower.contains('batata')) {
      return 'assets/commodities/potato.png';
    }
    if (lower.contains('tomato') || lower.contains('tamatar')) {
      return 'assets/commodities/tomato.png';
    }
    if (lower.contains('banana') || lower.contains('kela')) {
      return 'assets/commodities/banana.png';
    }
    if (lower.contains('guava') || lower.contains('amrood') || lower.contains('peru')) {
      return 'assets/commodities/guava.png';
    }
    if (lower.contains('orange') ||
        lower.contains('santre') ||
        lower.contains('mosambi') ||
        lower.contains('mandarin') ||
        lower.contains('citrus')) {
      return 'assets/commodities/orange.png';
    }
    if (lower.contains('carrot') || lower.contains('gajar')) {
      return 'assets/commodities/carrot.png';
    }
    if (lower.contains('cucumber') || lower.contains('kheera') || lower.contains('kakdi')) {
      return 'assets/commodities/cucumber.png';
    }
    if (lower.contains('brinjal') ||
        lower.contains('eggplant') ||
        lower.contains('baingan') ||
        lower.contains('aubergine')) {
      return 'assets/commodities/brinjal.png';
    }
    if (lower.contains('paddy') ||
        lower.contains('rice') ||
        lower.contains('dhan') ||
        lower.contains('chawal') ||
        lower.contains('basmati')) {
      return 'assets/commodities/paddy.png';
    }
    if (lower.contains('wheat') || lower.contains('gehun') || lower.contains('atta')) {
      return 'assets/commodities/wheat.png';
    }
    if (lower.contains('cotton') || lower.contains('kapas') || lower.contains('rui')) {
      return 'assets/commodities/cotton.png';
    }
    if (lower.contains('soybean') || lower.contains('soya')) {
      return 'assets/commodities/soybean.png';
    }
    if (lower.contains('sugarcane') || lower.contains('ganna')) {
      return 'assets/commodities/sugarcane.png';
    }
    if (lower.contains('chilli') || lower.contains('chili') || lower.contains('mirchi')) {
      return 'assets/commodities/chilli.png';
    }
    if (lower.contains('garlic') || lower.contains('lahsun')) {
      return 'assets/commodities/garlic.png';
    }
    if (lower.contains('ginger') || lower.contains('adrak')) {
      return 'assets/commodities/ginger.png';
    }
    if (lower.contains('maize') || lower.contains('corn') || lower.contains('makka')) {
      return 'assets/commodities/maize.png';
    }
    if (lower.contains('pomegranate') || lower.contains('anar')) {
      return 'assets/commodities/pomegranate.png';
    }
    if (lower.contains('sponge gourd') || lower.contains('gourd') || lower.contains('turai') || lower.contains('ghosale')) {
      return 'assets/commodities/sponge_gourd.png';
    }
    if (lower.contains('apple') || lower.contains('seb')) {
      return 'assets/commodities/apple.png';
    }
    if (lower.contains('mango') || lower.contains('aam')) {
      return 'assets/commodities/mango.png';
    }

    return 'assets/commodities/default.png';
  }

  /// Returns an emoji representation of the commodity
  static String getEmoji(String rawName) {
    final lower = rawName.toLowerCase().trim();
    if (lower == 'all' || lower.contains('all crop')) return '🧺';
    if (lower.contains('onion') || lower.contains('pyaz') || lower.contains('kanda')) return '🧅';
    if (lower.contains('potato') || lower.contains('alu') || lower.contains('batata')) return '🥔';
    if (lower.contains('tomato') || lower.contains('tamatar')) return '🍅';
    if (lower.contains('banana') || lower.contains('kela')) return '🍌';
    if (lower.contains('guava') || lower.contains('amrood') || lower.contains('peru')) return '🍈';
    if (lower.contains('orange') || lower.contains('santre') || lower.contains('mosambi') || lower.contains('mandarin')) return '🍊';
    if (lower.contains('carrot') || lower.contains('gajar')) return '🥕';
    if (lower.contains('cucumber') || lower.contains('kheera') || lower.contains('kakdi')) return '🥒';
    if (lower.contains('brinjal') || lower.contains('eggplant') || lower.contains('baingan')) return '🍆';
    if (lower.contains('paddy') || lower.contains('rice') || lower.contains('dhan')) return '🌾';
    if (lower.contains('wheat') || lower.contains('gehun')) return '🌾';
    if (lower.contains('cotton') || lower.contains('kapas')) return '☁️';
    if (lower.contains('soybean') || lower.contains('soya')) return '🌱';
    if (lower.contains('sugarcane') || lower.contains('ganna')) return '🎋';
    if (lower.contains('chilli') || lower.contains('chili') || lower.contains('mirchi')) return '🌶️';
    if (lower.contains('garlic') || lower.contains('lahsun')) return '🧄';
    if (lower.contains('ginger') || lower.contains('adrak')) return '🫚';
    if (lower.contains('maize') || lower.contains('corn') || lower.contains('makka')) return '🌽';
    if (lower.contains('apple') || lower.contains('seb')) return '🍎';
    if (lower.contains('mango') || lower.contains('aam')) return '🥭';
    if (lower.contains('pomegranate') || lower.contains('anar')) return '🍎';
    if (lower.contains('gourd')) return '🥒';
    if (lower.contains('gram') || lower.contains('chana') || lower.contains('dal') || lower.contains('pulse')) return '🫘';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = getAssetPath(commodity);

    Widget imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if asset fails to load
        return Image.asset(
          'assets/commodities/default.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.eco,
            size: size,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );

    if (showBackground) {
      return Container(
        width: size + 12,
        height: size + 12,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0x0A000000),
          borderRadius: borderRadius ?? BorderRadius.circular(size * 0.35),
        ),
        child: Center(child: imageWidget),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: imageWidget,
    );
  }
}

/// Alias for [CommodityIcon]
typedef CommodityImage = CommodityIcon;

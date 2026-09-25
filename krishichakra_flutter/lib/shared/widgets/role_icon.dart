import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Standardized, reusable role icon for KrishiChakra roles:
/// - Farmer / FPO Member: [Icons.agriculture_rounded]
/// - Institutional Buyer / Trader: [Icons.storefront_rounded]
/// - Transporter / Driver: [Icons.local_shipping_rounded]
class RoleIcon extends StatelessWidget {
  const RoleIcon({
    super.key,
    required this.role,
    this.size = 24.0,
    this.isSelected = false,
  });

  final String role;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final lower = role.toLowerCase().trim();
    final IconData icon;
    final Color color;
    final Color bgColor;

    if (lower.contains('buyer') || lower.contains('trader')) {
      icon = Icons.storefront_rounded;
      color = isSelected ? AppColors.primary : AppColors.secondary;
      bgColor = (isSelected ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.12);
    } else if (lower.contains('transport') || lower.contains('driver')) {
      icon = Icons.local_shipping_rounded;
      color = isSelected ? AppColors.primary : const Color(0xFF1E88E5);
      bgColor = (isSelected ? AppColors.primary : const Color(0xFF1E88E5)).withValues(alpha: 0.12);
    } else {
      // Farmer / FPO default
      icon = Icons.agriculture_rounded;
      color = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.12);
    }

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

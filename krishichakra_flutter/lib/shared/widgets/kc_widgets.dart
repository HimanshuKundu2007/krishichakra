import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
export 'commodity_icon.dart';
export 'role_icon.dart';

/// Shows whether price data comes from the government API or demo seed.
/// Non-negotiable per backend README: never label DEMO_SEED as live data.
/// Strictly displays "Showing last available government data" when offline or sync failed,
/// and never displays "LIVE" unless verified live from the government source.
class DataSourceTag extends StatelessWidget {
  const DataSourceTag({
    super.key,
    required this.source,
    this.arrivalDate,
    this.ingestedAt,
    this.lastUpdated,
    this.latestDataDate,
    this.lastSuccessfulSync,
    this.isLive = false,
    this.isLastAvailable = false,
    this.isStale = false,
    this.hasEverSynced = true,
    this.compact = false,
  });

  factory DataSourceTag.fromStatus({
    Key? key,
    required MandiStatus status,
    bool compact = false,
  }) {
    return DataSourceTag(
      key: key,
      source: status.source,
      latestDataDate: status.latestDataDate,
      lastSuccessfulSync: status.lastSuccessfulSync,
      isLive: status.isLive,
      isLastAvailable: status.isStale || (!status.isLive && status.hasGovernmentRecords),
      isStale: status.isStale,
      hasEverSynced: status.hasEverSynced,
      compact: compact,
    );
  }

  final String source;
  final String? arrivalDate;
  final String? ingestedAt;
  final String? lastUpdated;
  final String? latestDataDate;
  final String? lastSuccessfulSync;
  final bool isLive;
  final bool isLastAvailable;
  final bool isStale;
  final bool hasEverSynced;
  final bool compact;

  bool get _isDemo => source == 'DEMO_SEED';

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactTag(
        isLive: isLive,
        isDemo: _isDemo,
        isLastAvailable: isLastAvailable || isStale,
        hasEverSynced: hasEverSynced,
        source: source,
        arrivalDate: arrivalDate,
        latestDataDate: latestDataDate,
        lastUpdated: lastUpdated,
        lastSuccessfulSync: lastSuccessfulSync,
      );
    }
    return _FullTag(
      isLive: isLive,
      isDemo: _isDemo,
      isLastAvailable: isLastAvailable || isStale,
      hasEverSynced: hasEverSynced,
      source: source,
      arrivalDate: arrivalDate,
      latestDataDate: latestDataDate,
      ingestedAt: ingestedAt,
      lastUpdated: lastUpdated,
      lastSuccessfulSync: lastSuccessfulSync,
    );
  }
}

class _CompactTag extends StatelessWidget {
  const _CompactTag({
    required this.isLive,
    required this.isDemo,
    required this.isLastAvailable,
    required this.hasEverSynced,
    required this.source,
    this.arrivalDate,
    this.latestDataDate,
    this.lastUpdated,
    this.lastSuccessfulSync,
  });

  final bool isLive;
  final bool isDemo;
  final bool isLastAvailable;
  final bool hasEverSynced;
  final String source;
  final String? arrivalDate;
  final String? latestDataDate;
  final String? lastUpdated;
  final String? lastSuccessfulSync;

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      if (raw.length >= 10) return raw.substring(0, 10);
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDemo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Demo Data',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    final String cleanSource = source.isNotEmpty ? source : 'Government Market Data';
    final String titleText;
    if (!hasEverSynced) {
      titleText = 'No government market data is currently available.';
    } else if (isLastAvailable) {
      titleText = latestDataDate != null && latestDataDate!.isNotEmpty
          ? 'Showing last available $cleanSource ($latestDataDate)'
          : 'Showing last available $cleanSource';
    } else if (isLive) {
      titleText = 'Source: $cleanSource (LIVE)';
    } else {
      titleText = 'Source: $cleanSource';
    }

    final effectiveDate = !hasEverSynced
        ? 'Awaiting official Agmarknet synchronization'
        : (lastSuccessfulSync != null && lastSuccessfulSync!.isNotEmpty
            ? 'Last sync: ${_formatTimestamp(lastSuccessfulSync)}'
            : (lastUpdated != null && lastUpdated!.isNotEmpty
                ? 'Last updated: ${_formatTimestamp(lastUpdated)}'
                : (arrivalDate != null && arrivalDate!.isNotEmpty
                    ? 'Arrival Date: $arrivalDate'
                    : null)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: !hasEverSynced
            ? AppColors.errorContainer.withOpacity(0.2)
            : (isLastAvailable
                ? AppColors.tertiaryContainer.withOpacity(0.4)
                : AppColors.secondaryContainer.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !hasEverSynced
              ? AppColors.error.withOpacity(0.3)
              : (isLastAvailable
                  ? AppColors.tertiary.withOpacity(0.3)
                  : (isLive
                      ? AppColors.secondary.withOpacity(0.3)
                      : AppColors.outlineVariant)),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: !hasEverSynced
                  ? AppColors.error
                  : (isLastAvailable
                      ? AppColors.tertiary
                      : (isLive ? AppColors.secondary : AppColors.outline)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: !hasEverSynced
                        ? AppColors.error
                        : (isLastAvailable
                            ? AppColors.tertiary
                            : (isLive
                                ? AppColors.secondary
                                : AppColors.onSurface)),
                  ),
                ),
                if (effectiveDate != null)
                  Text(
                    effectiveDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
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

class _FullTag extends StatelessWidget {
  const _FullTag({
    required this.isLive,
    required this.isDemo,
    required this.isLastAvailable,
    required this.hasEverSynced,
    required this.source,
    this.arrivalDate,
    this.latestDataDate,
    this.ingestedAt,
    this.lastUpdated,
    this.lastSuccessfulSync,
  });

  final bool isLive;
  final bool isDemo;
  final bool isLastAvailable;
  final bool hasEverSynced;
  final String source;
  final String? arrivalDate;
  final String? latestDataDate;
  final String? ingestedAt;
  final String? lastUpdated;
  final String? lastSuccessfulSync;

  @override
  Widget build(BuildContext context) {
    if (isDemo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Development Demo Data',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  'Not official government figures',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    String formatTs(String? raw) {
      if (raw == null || raw.isEmpty) return '';
      try {
        final dt = DateTime.parse(raw);
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        if (raw.length >= 10) return raw.substring(0, 10);
        return raw;
      }
    }

    final String titleText;
    if (!hasEverSynced) {
      titleText = 'No government market data is currently available.';
    } else if (isLastAvailable) {
      titleText = latestDataDate != null && latestDataDate!.isNotEmpty
          ? 'Showing last available government data ($latestDataDate)'
          : 'Showing last available government data';
    } else if (isLive) {
      titleText = 'Source: Government Market Data (LIVE)';
    } else {
      titleText = 'Source: Government Market Data';
    }

    final effectiveDate = !hasEverSynced
        ? 'Awaiting official Agmarknet synchronization'
        : (lastSuccessfulSync != null && lastSuccessfulSync!.isNotEmpty
            ? 'Last sync: ${formatTs(lastSuccessfulSync)}'
            : (lastUpdated != null && lastUpdated!.isNotEmpty
                ? 'Last updated: ${formatTs(lastUpdated)}'
                : (arrivalDate != null && arrivalDate!.isNotEmpty
                    ? 'Arrival Date: $arrivalDate'
                    : (ingestedAt != null && ingestedAt!.isNotEmpty
                        ? 'Last sync: ${formatTs(ingestedAt)}'
                        : null))));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: !hasEverSynced
            ? AppColors.errorContainer.withOpacity(0.2)
            : (isLastAvailable
                ? AppColors.tertiaryContainer.withOpacity(0.3)
                : AppColors.secondaryContainer.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !hasEverSynced
              ? AppColors.error.withOpacity(0.3)
              : (isLastAvailable
                  ? AppColors.tertiary.withOpacity(0.4)
                  : (isLive
                      ? AppColors.secondary.withOpacity(0.4)
                      : AppColors.outlineVariant)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !hasEverSynced
                ? Icons.cloud_off_outlined
                : (isLastAvailable
                    ? Icons.history_rounded
                    : (isLive ? Icons.verified : Icons.account_balance_outlined)),
            size: 14,
            color: !hasEverSynced
                ? AppColors.error
                : (isLastAvailable
                    ? AppColors.tertiary
                    : (isLive ? AppColors.secondary : AppColors.onSurfaceVariant)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: !hasEverSynced
                        ? AppColors.error
                        : (isLastAvailable
                            ? AppColors.tertiary
                            : (isLive ? AppColors.secondary : AppColors.onSurface)),
                  ),
                ),
                if (effectiveDate != null)
                  Text(
                    effectiveDate,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
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

/// Animated pulsing dot for live/active states.
class LivePulsingDot extends StatefulWidget {
  const LivePulsingDot({super.key, this.color, this.size = 8});
  final Color? color;
  final double size;

  @override
  State<LivePulsingDot> createState() => _LivePulsingDotState();
}

class _LivePulsingDotState extends State<LivePulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.secondary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.3 + 0.7 * _ctrl.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Standard price change badge (green up / red down / neutral dash).
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({super.key, this.changePercent});
  final double? changePercent;

  @override
  Widget build(BuildContext context) {
    if (changePercent == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    final isUp = changePercent! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUp
            ? AppColors.secondaryContainer.withOpacity(0.5)
            : AppColors.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: isUp ? AppColors.secondary : AppColors.error,
          ),
          const SizedBox(width: 2),
          Text(
            '${isUp ? '+' : ''}${changePercent!.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isUp ? AppColors.secondary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder card.
class KcShimmerCard extends StatefulWidget {
  const KcShimmerCard({super.key, this.height = 120, this.borderRadius = 12});
  final double height;
  final double borderRadius;

  @override
  State<KcShimmerCard> createState() => _KcShimmerCardState();
}

class _KcShimmerCardState extends State<KcShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: [
                AppColors.surfaceContainerHigh,
                AppColors.surfaceContainer,
                AppColors.surfaceContainerHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Error state widget with retry.
class KcErrorState extends StatelessWidget {
  const KcErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget.
class KcEmptyState extends StatelessWidget {
  const KcEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.outlineVariant),
            if (title != null) ...[
              const SizedBox(height: 12),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-card or full-screen backend unavailable state with retry.
class KcBackendUnavailableState extends StatelessWidget {
  const KcBackendUnavailableState({
    super.key,
    this.title = 'Server Unavailable',
    this.message =
        'Unable to connect to KrishiChakra server. Please ensure the backend is running.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(160, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized loading indicator with contextual message.
class KcLoadingIndicator extends StatelessWidget {
  const KcLoadingIndicator({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Voice/mic search bar matching Stitch "Bolie" bar.
class VoiceSearchBar extends StatelessWidget {
  const VoiceSearchBar({
    super.key,
    required this.hint,
    this.onMicTap,
    this.controller,
    this.onSubmitted,
    this.isListening = false,
  });

  final String hint;
  final VoidCallback? onMicTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          _MicButton(onTap: onMicTap, isListening: isListening),
        ],
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({this.onTap, required this.isListening});
  final VoidCallback? onTap;
  final bool isListening;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isListening) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isListening) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Container(
              width: 32 + (widget.isListening ? 6 * _ctrl.value : 0),
              height: 32 + (widget.isListening ? 6 * _ctrl.value : 0),
              decoration: BoxDecoration(
                color: widget.isListening
                    ? AppColors.secondary.withOpacity(0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                size: 22,
                color: widget.isListening
                    ? AppColors.secondary
                    : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// INR currency formatter.
String formatInr(double amount, {bool showPaise = false}) {
  final formatted = amount.abs().toStringAsFixed(showPaise ? 2 : 0);
  final parts = formatted.split('.');
  final intPart = parts[0];

  // Indian comma system: xx,xx,xxx
  String result = '';
  if (intPart.length <= 3) {
    result = intPart;
  } else {
    result = intPart.substring(intPart.length - 3);
    String rest = intPart.substring(0, intPart.length - 3);
    while (rest.length > 2) {
      result = '${rest.substring(rest.length - 2)},$result';
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) result = '$rest,$result';
  }

  if (showPaise && parts.length > 1) result = '$result.${parts[1]}';
  return '₹${amount < 0 ? '-' : ''}$result';
}

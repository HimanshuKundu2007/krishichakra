import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/chatbot_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kc_widgets.dart';

/// Screen — Krishi Assistant Chatbot
/// Faithfully reproduces Stitch's chatbot screen:
///   - Message bubbles with bot and user styling
///   - Voice mic toggle and speech state
///   - Language indicator (EN, हि, म)
///   - Quick suggestion chips carousel
///   - Explicit "Rule-Based Prototype" transparency badge (LLM-ready architecture)
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isListening = false;
  bool _audioToggled = false;

  final _defaultSuggestions = const [
    '🧅 Onion Price Nashik',
    '📊 Compare Vashi vs Pune',
    '🏢 Verified Buyers',
    '🚚 Book Return Truck',
    '💰 NWR Loan Status',
    '🔍 Grade A Quality Check',
    '💡 Best Time to Sell',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();
    ref.read(chatStateProvider.notifier).send(trimmed);
    _scrollToBottom();
  }

  void _showPrototypeInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text('Prototype Architecture', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: const Text(
          'Krishi Assistant is operating in Rule-Based Prototype mode.\n\n'
          '• Answers are generated via deterministic agricultural domain logic grounded in government mandi databases, buyer records, and logistics models.\n'
          '• It is NOT an ungrounded LLM. The system architecture is decoupled and prepared for future LLM / SLM provider activation.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateProvider);
    final currentLang = ref.watch(chatLanguageProvider);

    // Auto-scroll on new messages or loading
    ref.listen(chatStateProvider, (_, next) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── 1. Stitch Header with Prototype Transparency ────────────────────
          _buildHeader(context),

          // ── 2. Language Strip (EN / हि / म) ──────────────────────────────────
          _buildLanguageStrip(currentLang),

          // ── 3. Rule-Based Prototype Callout Banner ──────────────────────────
          _buildPrototypeBanner(),

          // ── 4. Chat Messages List ───────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == chatState.messages.length && chatState.isLoading) {
                  return const _TypingIndicatorBubble();
                }
                final msg = chatState.messages[i];
                return _MessageBubble(
                  msg: msg,
                  onSelectSuggestion: _sendMessage,
                );
              },
            ),
          ),

          // ── 5. Listening Voice Notification (when mic active) ───────────────
          if (_isListening) _buildVoiceListeningBanner(),

          // ── 6. Horizontal Quick Suggestion Chips Carousel ────────────────────
          _buildSuggestionsBar(),

          const SizedBox(height: 6),

          // ── 7. Input Bar ─────────────────────────────────────────────────────
          _buildInputBar(currentLang),
        ],
      ),
    );
  }

  // ── Header Widget ───────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Krishi Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Rule-Based Assistant (Prototype)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFC8F5C4),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showPrototypeInfoDialog,
            icon: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
            tooltip: 'Prototype Info',
          ),
          IconButton(
            onPressed: () {
              setState(() => _audioToggled = !_audioToggled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _audioToggled
                        ? 'Audio voice readout enabled.'
                        : 'Audio voice readout muted.',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(
              _audioToggled ? Icons.volume_up : Icons.volume_mute,
              color: Colors.white70,
              size: 22,
            ),
            tooltip: 'Audio Output',
          ),
        ],
      ),
    );
  }

  // ── Language Strip ──────────────────────────────────────────────────────────

  Widget _buildLanguageStrip(String currentLang) {
    return Container(
      height: 38,
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Language: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          _buildLangChip('EN', 'en', currentLang),
          const SizedBox(width: 8),
          _buildLangChip('हि', 'hi', currentLang),
          const SizedBox(width: 8),
          _buildLangChip('म', 'mr', currentLang),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String code, String currentLang) {
    final isSelected = currentLang == code;
    return GestureDetector(
      onTap: () =>
          ref.read(chatLanguageProvider.notifier).setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  // ── Rule-Based Prototype Banner ─────────────────────────────────────────────

  Widget _buildPrototypeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF1F8E9),
      child: Row(
        children: const [
          Icon(Icons.rule, size: 14, color: Color(0xFF33691E)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Rule-based prototype • Verified APMC data • LLM-ready architecture',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF33691E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Voice Listening Banner ──────────────────────────────────────────────────

  Widget _buildVoiceListeningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Listening... (Tap mic again or send "Vashi onion price today?")',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _isListening = false);
              _sendMessage('Vashi onion price today?');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Demo Query',
                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions Carousel ────────────────────────────────────────────────────

  Widget _buildSuggestionsBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _defaultSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _defaultSuggestions[i];
          return GestureDetector(
            onTap: () => _sendMessage(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Center(
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Input Bar ───────────────────────────────────────────────────────────────

  Widget _buildInputBar(String currentLang) {
    String hintText;
    switch (currentLang) {
      case 'hi':
        hintText = 'मंडी भाव, खरीदार, ट्रक या कोल्ड स्टोरेज पूछें...';
        break;
      case 'mr':
        hintText = 'बाजारभाव, खरेदीदार किंवा वाहतुकीबद्दल विचारा...';
        break;
      default:
        hintText = 'Ask about mandi prices, buyers, transport, or storage...';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _sendMessage,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: hintText,
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isListening = !_isListening),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? AppColors.secondary
                            : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble Component ──────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.msg,
    required this.onSelectSuggestion,
  });

  final ChatMessage msg;
  final ValueChanged<String> onSelectSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.isBot) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isBot
                        ? AppColors.surfaceContainerLowest
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: msg.isBot ? Radius.zero : const Radius.circular(16),
                      bottomRight: msg.isBot ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: msg.isBot
                        ? Border.all(
                            color: AppColors.outlineVariant.withValues(alpha: 0.4))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bot disclaimer pill
                      if (msg.isBot) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Rule-based prototype',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: msg.isBot ? AppColors.onSurface : Colors.white,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                // Inline follow-up suggestions from bot
                if (msg.isBot && msg.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: msg.suggestions.map((suggestion) {
                      return GestureDetector(
                        onTap: () => onSelectSuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (!msg.isBot) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Typing Indicator Bubble ───────────────────────────────────────────────────

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: Radius.zero,
              ),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Consulting market rules...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
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

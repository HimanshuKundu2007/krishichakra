import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/models.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository(apiClient: ref.watch(apiClientProvider));
});

class ChatLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'en';

  void setLanguage(String lang) => state = lang;
}

final chatLanguageProvider =
    NotifierProvider<ChatLanguageNotifier, String>(ChatLanguageNotifier.new);

// ─── Chat State ───────────────────────────────────────────────────────────────

class ChatState {
  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Chat Notifier ────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(
      messages: [
        ChatMessage(
          text:
              'नमस्ते Rajesh Ji! 🌾 I am KrishiBot, your agricultural trade advisor.\n\n'
              '⚠️ Note: Running in Rule-Based Prototype mode. LLM architecture ready.\n\n'
              'Ask me about mandi prices, market comparison, verified buyers, transport, cold storage, quality grading, or selling strategy.',
          isBot: true,
          timestamp: DateTime.now(),
          mode: 'rule_based_prototype',
          isLlm: false,
          suggestions: const [
            '🧅 Onion Price Nashik',
            '📊 Compare Vashi vs Pune',
            '🏢 Verified Buyers',
            '🚚 Book Return Truck',
            '💰 NWR Loan Status',
            '💡 Best Time to Sell',
          ],
          disclaimer:
              'Krishi Assistant is running in Rule-Based Prototype mode. LLM integration architecture ready.',
        ),
      ],
    );
  }

  Future<void> send(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage.user(trimmed);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final repo = ref.read(chatbotRepositoryProvider);
      final lang = ref.read(chatLanguageProvider);
      final response = await repo.sendMessage(
        message: trimmed,
        language: lang,
      );

      final botMsg = ChatMessage.fromResponse(response);
      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isLoading: false,
      );
    } catch (e) {
      final fallbackMsg = ChatMessage(
        text:
            'Unable to reach live advisory backend ($e).\n\n'
            'Rule-Based Prototype offline fallback:\n'
            '• Mandi benchmark: Vashi Onion ₹2,800/Q, Pune ₹2,550/Q.\n'
            '• Net Realization = Gross − Transport − Storage.',
        isBot: true,
        timestamp: DateTime.now(),
        mode: 'rule_based_prototype',
        isLlm: false,
        suggestions: const [
          '🧅 Onion Price Nashik',
          '📊 Compare Vashi vs Pune',
          '🏢 Verified Buyers',
        ],
      );
      state = state.copyWith(
        messages: [...state.messages, fallbackMsg],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    state = ChatState(
      messages: [
        ChatMessage(
          text:
              'Chat cleared. Ask me about mandi prices, buyers, transport, cold storage, or harvest selling strategy.',
          isBot: true,
          timestamp: DateTime.now(),
          mode: 'rule_based_prototype',
          isLlm: false,
          suggestions: const [
            '🧅 Onion Price Nashik',
            '📊 Compare Vashi vs Pune',
            '🏢 Verified Buyers',
            '🚚 Book Return Truck',
          ],
        ),
      ],
    );
  }
}

final chatStateProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

// ─── Repository ───────────────────────────────────────────────────────────────

class ChatbotRepository {
  const ChatbotRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<ChatResponseModel> sendMessage({
    required String message,
    String language = 'en',
    int? farmerId,
  }) async {
    final body = {
      'message': message,
      'language': language,
      if (farmerId != null) 'farmer_id': farmerId,
    };

    final response = await apiClient.post(ApiEndpoints.chat, data: body);
    return ChatResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
}

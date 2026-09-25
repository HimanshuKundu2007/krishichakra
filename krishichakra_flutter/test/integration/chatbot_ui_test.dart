import 'package:krishichakra/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/api/api_client.dart';
import 'package:krishichakra/core/models/models.dart';
import 'package:krishichakra/core/repositories/chatbot_repository.dart';
import 'package:krishichakra/features/chatbot/screens/chatbot_screen.dart';

class FakeChatbotRepository implements ChatbotRepository {
  FakeChatbotRepository({this.mockReply});

  final String? mockReply;

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<ChatResponseModel> sendMessage({
    required String message,
    String language = 'en',
    int? farmerId,
  }) async {
    return ChatResponseModel(
      reply: mockReply ?? 'Mocked answer for "$message": Vashi Modal Price is ₹2,800/Q.',
      mode: 'rule_based_prototype',
      isLlm: false,
      intent: 'mandi_prices',
      suggestions: const ['📊 Compare Vashi vs Pune', '🚚 Check Return Truck'],
      disclaimer:
          'Krishi Assistant is running in Rule-Based Prototype mode. LLM integration architecture ready.',
    );
  }
}

void main() {
  group('Chatbot Model Tests', () {
    test('ChatResponseModel parses JSON with rule-based prototype flags', () {
      final json = {
        'reply': 'Vashi APMC Modal Price: ₹2,800/Q',
        'mode': 'rule_based_prototype',
        'is_llm': false,
        'intent': 'mandi_prices',
        'suggestions': ['Compare Vashi vs Pune', 'Check Freight'],
        'disclaimer': 'Rule-Based Prototype',
      };

      final model = ChatResponseModel.fromJson(json);
      expect(model.reply, 'Vashi APMC Modal Price: ₹2,800/Q');
      expect(model.mode, 'rule_based_prototype');
      expect(model.isLlm, false);
      expect(model.intent, 'mandi_prices');
      expect(model.suggestions.length, 2);
    });

    test('ChatMessage formats user and bot messages appropriately', () {
      final userMsg = ChatMessage.user('Show onion rates');
      expect(userMsg.isBot, false);
      expect(userMsg.text, 'Show onion rates');

      final botMsg = ChatMessage.fromResponse(
        const ChatResponseModel(
          reply: 'Onion rate is ₹2,400/Q',
          mode: 'rule_based_prototype',
          isLlm: false,
          intent: 'mandi_prices',
          suggestions: ['Transport cost'],
        ),
      );
      expect(botMsg.isBot, true);
      expect(botMsg.isLlm, false);
      expect(botMsg.mode, 'rule_based_prototype');
      expect(botMsg.suggestions.first, 'Transport cost');
    });
  });

  group('ChatbotScreen UI Widget Tests (Stitch Design)', () {
    testWidgets('renders all Stitch header, language, and prototype elements',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRepo = FakeChatbotRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: ChatbotScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Krishi Assistant'), findsOneWidget);
      expect(find.text('Rule-Based Assistant (Prototype)'), findsOneWidget);

      // Language Strip
      expect(find.text('Language: '), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('हि'), findsOneWidget);
      expect(find.text('म'), findsOneWidget);

      // Rule-Based Prototype Banner
      expect(
        find.text(
            'Rule-based prototype • Verified APMC data • LLM-ready architecture'),
        findsOneWidget,
      );

      // Default initial bot greeting with rule-based note
      expect(find.textContaining('Rule-Based Prototype'), findsWidgets);

      // Quick Suggestions Bar & Welcome bubble
      expect(find.text('🧅 Onion Price Nashik'), findsWidgets);
      expect(find.text('📊 Compare Vashi vs Pune'), findsWidgets);
      expect(find.text('🏢 Verified Buyers'), findsWidgets);
      expect(find.text('🚚 Book Return Truck'), findsWidgets);

      // Input bar
      expect(
        find.text('Ask about mandi prices, buyers, transport, or storage...'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('sends query and displays rule-based response with suggestions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRepo = FakeChatbotRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: ChatbotScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter query
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'Vashi onion price today?');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(); // Start request
      await tester.pumpAndSettle(); // Finish request

      // Verify user message is rendered
      expect(find.text('Vashi onion price today?'), findsOneWidget);

      // Verify bot reply is rendered
      expect(
        find.textContaining('Mocked answer for "Vashi onion price today?"'),
        findsOneWidget,
      );

      // Verify rule-based prototype pill tag
      expect(find.text('Rule-based prototype'), findsWidgets);
    });

    testWidgets('tapping suggestion chip sends message to backend',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRepo = FakeChatbotRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: ChatbotScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap suggestion chip
      await tester.tap(find.text('🧅 Onion Price Nashik').first);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify query sent
      expect(find.text('🧅 Onion Price Nashik'), findsWidgets);
      expect(
        find.textContaining('Mocked answer for "🧅 Onion Price Nashik"'),
        findsOneWidget,
      );
    });

    testWidgets('tapping info icon opens Prototype Architecture dialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRepo = FakeChatbotRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: ChatbotScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap info icon in header
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Prototype Architecture'), findsOneWidget);
      expect(
        find.textContaining('deterministic agricultural domain logic'),
        findsOneWidget,
      );
      expect(find.text('Understood'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Prototype Architecture'), findsNothing);
    });

    testWidgets('switching language updates input hint text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRepo = FakeChatbotRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: ChatbotScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Hindi chip
      await tester.tap(find.text('हि'));
      await tester.pumpAndSettle();

      expect(
        find.text('मंडी भाव, खरीदार, ट्रक या कोल्ड स्टोरेज पूछें...'),
        findsOneWidget,
      );

      // Tap Marathi chip
      await tester.tap(find.text('म'));
      await tester.pumpAndSettle();

      expect(
        find.text('बाजारभाव, खरेदीदार किंवा वाहतुकीबद्दल विचारा...'),
        findsOneWidget,
      );
    });
  });
}

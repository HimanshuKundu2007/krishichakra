import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/dashboard/screens/farmer_home_screen.dart';
import '../features/mandi/screens/live_mandi_rates_screen.dart';
import '../features/mandi/screens/mandi_detail_screen.dart';
import '../features/calculator/screens/net_realization_calculator_screen.dart';
import '../features/produce/screens/produce_listing_screen.dart';
import '../features/produce/screens/my_lots_screen.dart';
import '../features/buyers/screens/buyer_matches_screen.dart';
import '../features/fpo/screens/fpo_batch_aggregation_screen.dart';
import '../features/logistics/screens/logistics_booking_screen.dart';
import '../features/logistics/screens/storage_booking_screen.dart';
import '../features/transactions/screens/transaction_detail_screen.dart';
import '../features/transactions/screens/consignment_settlement_screen.dart';
import '../features/disputes/screens/dispute_screen.dart';
import '../features/chatbot/screens/chatbot_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../shared/shell/main_shell.dart';

// ─── Route paths ─────────────────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  // Shell
  static const home = '/home';
  static const markets = '/markets';
  static const myLots = '/my-lots';
  static const profileTab = '/profile-tab';
  // Nested
  static const mandiDetail = '/markets/detail';
  static const netRealization = '/calculator';
  static const produceListing = '/produce/new';
  static const buyerMatches = '/produce/buyers';
  static const fpoAggregation = '/fpo/batch';
  static const logisticsBooking = '/logistics/book';
  static const storageBooking = '/storage/book';
  static const transactionDetail = '/transactions/:id';
  static const consignmentSettlement = '/transactions/:id/settlement';
  static const dispute = '/transactions/:id/dispute';
  static const chatbot = '/chatbot';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    debugLogDiagnostics: true,
    routes: [
      // ── Auth (no shell) ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.auth,
        builder: (ctx, state) => const AuthScreen(),
      ),

      // ── Main shell with bottom nav ───────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) => MainShell(shell: shell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (ctx, state) => const FarmerHomeScreen(),
              ),
            ],
          ),
          // Branch 1: Markets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.markets,
                builder: (ctx, state) => LiveMandiRatesScreen(
                  initialCommodity: state.uri.queryParameters['commodity'],
                ),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (ctx, state) {
                      final market = state.uri.queryParameters['market'] ?? '';
                      final commodity =
                          state.uri.queryParameters['commodity'] ?? '';
                      return MandiDetailScreen(
                          market: market, commodity: commodity);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: My Lots
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myLots,
                builder: (ctx, state) => const MyLotsScreen(),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profileTab,
                builder: (ctx, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Standalone routes (outside shell) ───────────────────────────────
      GoRoute(
        path: AppRoutes.netRealization,
        builder: (ctx, state) => NetRealizationCalculatorScreen(
          commodity: state.uri.queryParameters['commodity'],
          market: state.uri.queryParameters['market'],
          quantityQ: int.tryParse(
              state.uri.queryParameters['qty'] ?? '20'),
        ),
      ),
      GoRoute(
        path: AppRoutes.produceListing,
        builder: (ctx, state) => const ProduceListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerMatches,
        builder: (ctx, state) => BuyerMatchesScreen(
          lotId: int.tryParse(state.uri.queryParameters['lot_id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.fpoAggregation,
        builder: (ctx, state) => const FpoBatchAggregationScreen(),
      ),
      GoRoute(
        path: AppRoutes.logisticsBooking,
        builder: (ctx, state) => const LogisticsBookingScreen(),
      ),
      GoRoute(
        path: AppRoutes.storageBooking,
        builder: (ctx, state) => const StorageBookingScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (ctx, state) => TransactionDetailScreen(
          transactionId: int.tryParse(state.pathParameters['id'] ?? '0') ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'settlement',
            builder: (ctx, state) => ConsignmentSettlementScreen(
              transactionId:
                  int.tryParse(state.pathParameters['id'] ?? '0') ?? 0,
            ),
          ),
          GoRoute(
            path: 'dispute',
            builder: (ctx, state) => DisputeScreen(
              transactionId:
                  int.tryParse(state.pathParameters['id'] ?? '0') ?? 0,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        builder: (ctx, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (ctx, state) => const ProfileScreen(),
      ),
    ],
  );
});

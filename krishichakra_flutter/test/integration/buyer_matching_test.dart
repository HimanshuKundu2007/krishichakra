/// Flutter model unit tests for the buyer matching workflow.
///
/// These tests verify:
/// - BuyerMatch.fromJson deserialises all 9 required fields
/// - BuyerMatchScoreBreakdown.fromJson deserialises 4 component fields
/// - isTopBid reflects matchScore >= 70
/// - Offer.fromJson deserialises all 5 required fields
/// - Missing/null optional fields degrade gracefully
/// - The score breakdown component values match the response
///
/// NO network calls — pure model unit tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:krishichakra/core/models/models.dart';

void main() {
  group('BuyerMatchScoreBreakdown', () {
    test('fromJson deserialises all 4 components', () {
      final json = {
        'quantity_fit': 100.0,
        'quality_fit': 80.0,
        'verified_score': 100.0,
        'payment_score': 92.0,
      };
      final breakdown = BuyerMatchScoreBreakdown.fromJson(json);
      expect(breakdown.quantityFit, 100.0);
      expect(breakdown.qualityFit, 80.0);
      expect(breakdown.verifiedScore, 100.0);
      expect(breakdown.paymentScore, 92.0);
    });

    test('gracefully handles missing fields with 0 default', () {
      final breakdown = BuyerMatchScoreBreakdown.fromJson({});
      expect(breakdown.quantityFit, 0.0);
      expect(breakdown.qualityFit, 0.0);
      expect(breakdown.verifiedScore, 0.0);
      expect(breakdown.paymentScore, 0.0);
    });
  });

  group('BuyerMatch', () {
    Map<String, dynamic> _fullJson({
      double matchScore = 87.5,
      bool verified = true,
      double? offeredPrice = 2800.0,
    }) =>
        {
          'buyer_id': 42,
          'buyer': 'FreshMart Wholesale',
          'buyer_type': 'Institutional Buyer',
          'verified': verified,
          'payment_reliability': 92.0,
          'offered_price': offeredPrice,
          'match_score': matchScore,
          'reason': 'Score 87.5/100 — Transparent match: lot quantity is within range; '
              'buyer is verified; payment reliability is excellent (92%). '
              'Formula: 30% quantity fit + 25% quality fit + 25% verified + 20% payment.',
          'score_breakdown': {
            'quantity_fit': 100.0,
            'quality_fit': 80.0,
            'verified_score': 100.0,
            'payment_score': 92.0,
          },
        };

    test('fromJson deserialises all required fields', () {
      final match = BuyerMatch.fromJson(_fullJson());
      expect(match.buyerId, 42);
      expect(match.buyer, 'FreshMart Wholesale');
      expect(match.buyerType, 'Institutional Buyer');
      expect(match.verified, true);
      expect(match.paymentReliability, 92.0);
      expect(match.offeredPrice, 2800.0);
      expect(match.matchScore, 87.5);
      expect(match.reason, isNotEmpty);
      expect(match.scoreBreakdown.quantityFit, 100.0);
    });

    test('isTopBid is true when matchScore >= 70', () {
      expect(BuyerMatch.fromJson(_fullJson(matchScore: 70.0)).isTopBid, isTrue);
      expect(BuyerMatch.fromJson(_fullJson(matchScore: 87.5)).isTopBid, isTrue);
    });

    test('isTopBid is false when matchScore < 70', () {
      expect(BuyerMatch.fromJson(_fullJson(matchScore: 69.9)).isTopBid, isFalse);
      expect(BuyerMatch.fromJson(_fullJson(matchScore: 0.0)).isTopBid, isFalse);
    });

    test('null offered_price degrades gracefully', () {
      final match = BuyerMatch.fromJson(_fullJson(offeredPrice: null));
      expect(match.offeredPrice, isNull);
    });

    test('unverified buyer has verified=false', () {
      final match = BuyerMatch.fromJson(_fullJson(verified: false));
      expect(match.verified, false);
    });

    test('reason string contains score formula reference', () {
      final match = BuyerMatch.fromJson(_fullJson());
      expect(match.reason.contains('%'), isTrue);
    });

    test('score_breakdown components are individually within 0–100', () {
      final match = BuyerMatch.fromJson(_fullJson());
      final bd = match.scoreBreakdown;
      for (final v in [
        bd.quantityFit,
        bd.qualityFit,
        bd.verifiedScore,
        bd.paymentScore
      ]) {
        expect(v, inInclusiveRange(0.0, 100.0));
      }
    });
  });

  group('Offer', () {
    test('fromJson deserialises all 5 required fields', () {
      final json = {
        'id': 7,
        'lot_id': 3,
        'buyer_id': 42,
        'offered_price': 2800.0,
        'quantity_quintal': 20.0,
      };
      final offer = Offer.fromJson(json);
      expect(offer.id, 7);
      expect(offer.lotId, 3);
      expect(offer.buyerId, 42);
      expect(offer.offeredPrice, 2800.0);
      expect(offer.quantityQuintal, 20.0);
    });
  });
}

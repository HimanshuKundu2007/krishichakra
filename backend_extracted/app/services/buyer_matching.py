"""
Buyer matching service for KrishiChakra.

Match score formula (transparent — mirrored verbatim in the Flutter UI):
  match_score = 0.30 * quantity_fit
              + 0.25 * quality_fit
              + 0.25 * verified_score
              + 0.20 * payment_score

All component weights are exposed in the score_breakdown field so that farmers
can see exactly why a buyer ranked where they did.
"""
from sqlalchemy.orm import Session
from ..models import Buyer, ProduceLot


def _quantity_fit(buyer: Buyer, lot: ProduceLot) -> float:
    """1.0 if lot quantity falls within buyer's demand range, else 0.2."""
    if buyer.min_quantity <= lot.quantity_quintal <= buyer.max_quantity:
        return 1.0
    # Partial credit if within 50% of range limits
    low_ratio = lot.quantity_quintal / max(buyer.min_quantity, 0.1)
    high_ratio = buyer.max_quantity / max(lot.quantity_quintal, 0.1)
    return round(min(low_ratio, high_ratio, 1.0) * 0.6, 4)


def _quality_fit(buyer: Buyer, lot: ProduceLot) -> float:
    """1.0 if no buyer quality requirement or lot has no grade; 0.8 otherwise."""
    if not buyer.quality_requirements or not lot.grade:
        return 1.0
    # Future: parse grade letters and compare; for now give 0.8
    return 0.8


def _verified_score(buyer: Buyer) -> float:
    return 1.0 if buyer.verified else 0.0


def _payment_score(buyer: Buyer) -> float:
    return round(max(0.0, min(1.0, buyer.payment_reliability or 0.0)), 4)


def _build_reason(
    buyer_name: str,
    quantity_fit: float,
    quality_fit: float,
    verified: bool,
    payment: float,
    score: float,
) -> str:
    parts = []
    if quantity_fit >= 1.0:
        parts.append("lot quantity is within buyer's demand range")
    elif quantity_fit > 0.4:
        parts.append("lot quantity is close to buyer's demand range")
    else:
        parts.append("lot quantity is outside buyer's typical range")

    if verified:
        parts.append("buyer is KrishiChakra-verified")
    else:
        parts.append("buyer is not yet verified")

    if payment >= 0.9:
        parts.append(f"payment reliability is excellent ({round(payment * 100)}%)")
    elif payment >= 0.7:
        parts.append(f"payment reliability is good ({round(payment * 100)}%)")
    else:
        parts.append(f"payment reliability is moderate ({round(payment * 100)}%)")

    combined = "; ".join(parts)
    return (
        f"Score {score}/100 — Transparent match: {combined}. "
        "Formula: 30% quantity fit + 25% quality fit + 25% verified status + 20% payment reliability."
    )


def match_buyers(db: Session, lot: ProduceLot) -> list[dict]:
    """
    Return buyers matched to the given produce lot, sorted by descending match_score.
    All scoring is transparent and deterministic — no ML inference.
    """
    buyers = db.query(Buyer).filter(
        Buyer.demand_commodity.ilike(lot.commodity)
    ).all()

    out = []
    for b in buyers:
        qty_fit = _quantity_fit(b, lot)
        qual_fit = _quality_fit(b, lot)
        ver_score = _verified_score(b)
        pay_score = _payment_score(b)

        raw_score = (
            0.30 * qty_fit
            + 0.25 * qual_fit
            + 0.25 * ver_score
            + 0.20 * pay_score
        )
        score = round(raw_score * 100, 1)

        out.append({
            "buyer_id": b.id,
            "buyer": b.name,
            "buyer_type": b.buyer_type,
            "verified": b.verified,
            "payment_reliability": round((b.payment_reliability or 0.0) * 100, 1),
            "offered_price": b.offered_price,
            "match_score": score,
            "reason": _build_reason(
                b.name, qty_fit, qual_fit, b.verified, b.payment_reliability or 0.0, score
            ),
            "score_breakdown": {
                "quantity_fit": round(qty_fit * 100, 1),
                "quality_fit": round(qual_fit * 100, 1),
                "verified_score": round(ver_score * 100, 1),
                "payment_score": round(pay_score * 100, 1),
            },
        })

    return sorted(out, key=lambda x: x["match_score"], reverse=True)

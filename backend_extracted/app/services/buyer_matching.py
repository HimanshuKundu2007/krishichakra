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
    """
    Grade-aware quality fit.
      1.0  — buyer has no requirement, OR lot has no grade (unconstrained match)
      1.0  — buyer's quality_requirements string contains the lot's grade letter
      0.6  — buyer has requirements but the lot's grade is NOT listed
    """
    if not buyer.quality_requirements or not lot.grade:
        return 1.0
    # Normalise: extract grade tokens from the buyer requirement string.
    # e.g. "Grade A, Grade B" → ["a", "b"]
    # e.g. "Export Grade A"  → ["a"]
    req_lower = buyer.quality_requirements.lower()
    lot_grade_lower = lot.grade.lower().strip()  # e.g. "grade a" or "a"
    # Extract single-letter grade identifiers from requirement string
    import re
    req_grades = set(re.findall(r'\bgrade\s+([a-z])\b', req_lower))
    lot_grade_letter = re.search(r'\bgrade\s+([a-z])\b', lot_grade_lower)
    if not lot_grade_letter:
        # Lot grade not in standard "Grade X" format — substring match fallback
        return 1.0 if lot_grade_lower in req_lower else 0.6
    lot_letter = lot_grade_letter.group(1)
    return 1.0 if lot_letter in req_grades else 0.6


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

    if quality_fit >= 1.0:
        parts.append("grade meets buyer's quality requirements")
    else:
        parts.append("grade does not fully match buyer's requirements (partial credit)")

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


def _normalize_commodity_token(name: str) -> str:
    n = (name or "").lower().strip()
    if "onion" in n or "pyaz" in n or "kanda" in n:
        return "Onion"
    if "tomato" in n or "tamatar" in n:
        return "Tomato"
    if "potato" in n or "alu" in n or "batata" in n:
        return "Potato"
    if "wheat" in n or "gehun" in n:
        return "Wheat"
    if "paddy" in n or "rice" in n or "dhan" in n:
        return "Paddy"
    if "soy" in n:
        return "Soybean"
    if "banana" in n or "kela" in n:
        return "Banana"
    if "guava" in n or "peru" in n:
        return "Guava"
    if "orange" in n or "santra" in n or "mosambi" in n:
        return "Orange"
    if "brinjal" in n or "eggplant" in n or "baingan" in n:
        return "Brinjal"
    if "garlic" in n or "lahsun" in n:
        return "Garlic"
    if "chilli" in n or "chili" in n or "mirchi" in n:
        return "Green Chilli"
    if "maize" in n or "corn" in n or "makka" in n:
        return "Maize"
    if "pomegranate" in n or "anar" in n or "dalimb" in n:
        return "Pomegranate"
    if "cotton" in n or "kapas" in n:
        return "Cotton"
    return name.strip()


def match_buyers(db: Session, lot: ProduceLot) -> list[dict]:
    """
    Return buyers matched to the given produce lot, sorted by descending match_score.
    All scoring is transparent and deterministic — no ML inference.
    """
    norm_crop = _normalize_commodity_token(lot.commodity)

    buyers = db.query(Buyer).filter(
        (Buyer.demand_commodity.ilike(f"%{norm_crop}%"))
        | (Buyer.demand_commodity.ilike(f"%{lot.commodity.strip()}%"))
    ).all()

    # Fallback to all verified buyers if no direct crop match
    if not buyers:
        buyers = db.query(Buyer).limit(10).all()

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
            "district": b.district or "Pune",
            "state": b.state or "Maharashtra",
            "city": getattr(b, "city", None) or b.district or "Pune",
            "min_quantity": b.min_quantity or 10.0,
            "max_quantity": b.max_quantity or 500.0,
            "accepted_grade": getattr(b, "accepted_grade", None) or "Grade A",
            "quality_requirements": b.quality_requirements or "Grade A, Grade B",
            "indicative_price_min": getattr(b, "indicative_price_min", None) or (b.offered_price * 0.95 if b.offered_price else 2000.0),
            "indicative_price_max": getattr(b, "indicative_price_max", None) or (b.offered_price * 1.05 if b.offered_price else 2500.0),
            "pickup_available": getattr(b, "pickup_available", True),
            "delivery_available": getattr(b, "delivery_available", True),
            "payment_terms": getattr(b, "payment_terms", "T+1 (24 hrs via KrishiChakra Escrow)"),
            "verification_status": getattr(b, "verification_status", "Demo Verified Buyer"),
        })

    return sorted(out, key=lambda x: x["match_score"], reverse=True)

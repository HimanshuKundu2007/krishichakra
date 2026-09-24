"""
Backend aggregation service for FPO batch workflows.

All aggregation, quality gatekeeper routing, and financial realization
calculations are performed strictly on the backend, not in Flutter widgets.
"""
from typing import Any
from ..models import FPO, FPOBatch, FPOBatchLot


def evaluate_gatekeeper_quality(target_grade: str, lot_grade: str) -> tuple[str, str | None, str | None]:
    """
    Gatekeeper quality audit rule:
    If lot grade matches the master batch target grade, it is staged at the hub.
    Otherwise, it is automatically diverted to the local APMC spot auction
    to safeguard the FPO grade purity bonus.
    """
    clean_target = (target_grade or "Grade A").strip().lower()
    clean_lot = (lot_grade or "Grade A").strip().lower()

    if clean_target in clean_lot or clean_lot in clean_target:
        return ("staged", None, None)
    
    # Sub-grade: Divert to APMC spot auction
    diversion_route = "Junnar APMC Yard • Spot Auction Slip #92"
    gatekeeper_note = (
        f"Not eligible for {target_grade} bulk processing contract. "
        "Auto-rerouted to local mandi spot auction to safeguard FPO grade purity bonus."
    )
    return ("diverted", diversion_route, gatekeeper_note)


def calculate_batch_aggregation(
    batch: FPOBatch,
    lots: list[FPOBatchLot],
    fpo: FPO | None = None
) -> dict[str, Any]:
    """
    Pure backend aggregation calculation for a master FPO batch.
    Computes:
      - staged vs diverted volumes
      - target volume & fill percentage
      - remaining tonnage & crate count to trigger seal
      - bulk institutional bonus comparison
      - financial realization ledger (commercial value, payout, FPO margin, freight)
    """
    staged_lots = [l for l in lots if l.status == "staged"]
    diverted_lots = [l for l in lots if l.status == "diverted"]

    staged_qty = round(sum(l.quantity_quintal for l in staged_lots), 2)
    diverted_qty = round(sum(l.quantity_quintal for l in diverted_lots), 2)
    target_qty = float(batch.target_quantity_quintal or 200.0)

    fill_pct = round(min((staged_qty / target_qty) * 100.0, 100.0), 1) if target_qty > 0 else 0.0
    remaining_qty = round(max(target_qty - staged_qty, 0.0), 2)
    # Standard agricultural crate conversion: 1 quintal = 2 crates (50kg per crate) -> 1 tonne (10 Q) = 20 crates
    remaining_crates = int(round(remaining_qty * 2))
    total_crates_checked = sum(l.crates_count for l in staged_lots)

    buyer_price = float(batch.buyer_contract_price or 2650.0)
    benchmark_price = float(batch.benchmark_mandi_price or 2470.0)
    premium = float(batch.institutional_premium_per_q or round(buyer_price - benchmark_price, 2))

    buyer_name = batch.buyer_name or "Sahyadri Processing"
    bonus_explanation = (
        f"Consolidated volume unlocks direct contract with {buyer_name} "
        f"at ₹{int(buyer_price):,}/Q flat vs ₹{int(benchmark_price):,}/Q spot market average."
    )

    # Financial Ledger Calculations (Escrow Protected)
    commercial_value = round(staged_qty * buyer_price, 2)
    # FPO operational handling margin: 2%
    fpo_margin = round(commercial_value * 0.02, 2)
    # Freight & toll surcharge: ~₹95.68 per quintal (calibrated to ~₹17,700 for 185 Q)
    freight_surcharge = round(staged_qty * 95.68, 2)
    # Direct Farmer Payout Realization
    farmer_payout = round(commercial_value - fpo_margin - freight_surcharge, 2)

    eway_bill = None
    if batch.status in ("sealed", "dispatched"):
        eway_bill = f"EWB-MH-{batch.id:04d}-{batch.batch_code.replace('#', '').replace('-', '')}"

    fpo_name = fpo.name if fpo else "Junnar Farmer Producer Co. Ltd."
    fpo_verified = fpo.verified if fpo else True
    fpo_reg = fpo.registration_number if fpo else "Reg #MH-JNR-092"
    fpo_hub = fpo.hub_name if fpo else "Junnar FPC Hub"
    total_farmers = fpo.total_members_count if fpo and fpo.total_members_count > 0 else 412

    return {
        "id": batch.id,
        "batch_code": batch.batch_code,
        "fpo_id": batch.fpo_id,
        "fpo_name": fpo_name,
        "fpo_verified": fpo_verified,
        "fpo_registration_number": fpo_reg,
        "fpo_hub_name": fpo_hub,
        "total_registered_farmers": total_farmers,
        "commodity": batch.commodity,
        "target_grade": batch.target_grade,
        "target_quantity_quintal": target_qty,
        "staged_quantity_quintal": staged_qty,
        "diverted_quantity_quintal": diverted_qty,
        "remaining_quantity_quintal": remaining_qty,
        "remaining_crates": remaining_crates,
        "fill_percentage": fill_pct,
        "status": batch.status,
        "buyer_name": buyer_name,
        "buyer_contract_price": buyer_price,
        "benchmark_mandi_price": benchmark_price,
        "institutional_premium_per_q": premium,
        "bonus_explanation": bonus_explanation,
        "staging_bay_info": batch.staging_bay_info or "Junnar Staging Bay: 70 Crates Checked • Live Camera Gate 2",
        "total_crates_checked": total_crates_checked,
        "dock_bay": batch.dock_bay or "Dock Bay #2",
        "transporter_vehicle": batch.transporter_vehicle or "10-Tonne Eicher Pro",
        "transporter_number": batch.transporter_number or "MH-14-AZ-8821",
        "transporter_driver": batch.transporter_driver or "Kailash Jadhav • Verified Ventilated Reefer",
        "destination": batch.destination or "Sahyadri Agro Processing Plant, Dindori",
        "lots": [
            {
                "id": l.id,
                "batch_id": l.batch_id,
                "farmer_id": l.farmer_id,
                "farmer_name": l.farmer_name,
                "member_code": l.member_code,
                "lot_id": l.lot_id,
                "quantity_quintal": l.quantity_quintal,
                "grade": l.grade,
                "bulb_spec": l.bulb_spec,
                "moisture_pct": l.moisture_pct,
                "foreign_rot_pct": l.foreign_rot_pct,
                "crates_count": l.crates_count,
                "qr_tag_range": l.qr_tag_range,
                "status": l.status,
                "diversion_route": l.diversion_route,
                "gatekeeper_note": l.gatekeeper_note,
            }
            for l in lots
        ],
        "ledger": {
            "commercial_value": commercial_value,
            "farmer_payout": farmer_payout,
            "fpo_margin": fpo_margin,
            "freight_surcharge": freight_surcharge,
            "currency": "INR",
        },
        "eway_bill_number": eway_bill,
    }

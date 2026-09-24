from sqlalchemy.orm import Session
from sqlalchemy import desc
from ..models import MandiPrice, ProduceLot, LogisticsOption, StorageOption

def recommend_sale(
    db: Session,
    lot: ProduceLot | None = None,
    transport: float = 0.0,
    storage: float = 0.0,
    holding_days: int = 0,
    commodity: str | None = None,
    quantity: float | None = None,
    transport_cost_per_quintal: float | None = None,
    storage_cost_per_quintal: float | None = None,
    explicit_transport_cost: float | None = None,
    explicit_storage_cost: float | None = None,
):
    """
    Calculate sale recommendations using actual government mandi prices from the database.
    Formula:
        Gross Realization = modal_price * quantity
        Transport Cost = transport_cost_per_quintal * quantity (or explicit_transport_cost)
        Storage Cost = storage_cost_per_quintal * holding_days * quantity (or explicit_storage_cost)
        Estimated Net Realization = Gross Realization - Transport Cost - Storage Cost

    Calculated values are estimates, not guaranteed future prices.
    Connects with available Logistics and Storage database options when fallback rates are needed.
    """
    if lot is not None:
        target_commodity = commodity or lot.commodity
        target_quantity = quantity if quantity is not None else lot.quantity_quintal
    else:
        target_commodity = commodity or "Onion"
        target_quantity = quantity if quantity is not None else 20.0

    target_transport_per_q = (
        transport_cost_per_quintal if transport_cost_per_quintal is not None else transport
    )
    target_storage_per_q = (
        storage_cost_per_quintal if storage_cost_per_quintal is not None else storage
    )

    # If transport cost is not provided, query lowest available logistics option as baseline benchmark
    if target_transport_per_q == 0.0 and explicit_transport_cost is None:
        cheapest_transport = (
            db.query(LogisticsOption)
            .filter(LogisticsOption.available == True)
            .order_by(LogisticsOption.cost_per_quintal.asc())
            .first()
        )
        if cheapest_transport:
            target_transport_per_q = cheapest_transport.cost_per_quintal

    # If storage cost is not provided and holding days > 0, query lowest available storage rate
    if target_storage_per_q == 0.0 and explicit_storage_cost is None and holding_days > 0:
        cheapest_storage = (
            db.query(StorageOption)
            .filter(StorageOption.available == True)
            .order_by(StorageOption.cost_per_quintal_day.asc())
            .first()
        )
        if cheapest_storage:
            target_storage_per_q = cheapest_storage.cost_per_quintal_day

    # Pre-fetch available logistics options to match market destinations
    logistics_cache = (
        db.query(LogisticsOption)
        .filter(LogisticsOption.available == True)
        .all()
    )

    # 1. Query real government prices from mandi_prices
    cleaned_commodity = target_commodity.strip()
    rows = (
        db.query(MandiPrice)
        .filter(MandiPrice.commodity.ilike(f"%{cleaned_commodity}%"))
        .order_by(desc(MandiPrice.arrival_date), desc(MandiPrice.modal_price))
        .limit(50)
        .all()
    )

    # 2. If no exact/substring match, try matching core tokens
    if not rows:
        tokens = (
            cleaned_commodity.replace("(", " ")
            .replace(")", " ")
            .replace("-", " ")
            .split()
        )
        for token in tokens:
            if len(token) >= 4 and token.lower() not in {"grade", "fresh", "local", "best"}:
                matched = (
                    db.query(MandiPrice)
                    .filter(MandiPrice.commodity.ilike(f"%{token}%"))
                    .order_by(desc(MandiPrice.arrival_date), desc(MandiPrice.modal_price))
                    .limit(50)
                    .all()
                )
                if matched:
                    rows = matched
                    break

    # 3. Fallback to latest records if still empty
    if not rows:
        rows = (
            db.query(MandiPrice)
            .order_by(desc(MandiPrice.arrival_date), desc(MandiPrice.modal_price))
            .limit(50)
            .all()
        )

    options = []
    seen_markets = set()

    for row in rows:
        if row.modal_price is None or row.modal_price <= 0:
            continue

        market_key = (row.market.strip().lower(), (row.state or "").strip().lower())
        if market_key in seen_markets:
            continue
        seen_markets.add(market_key)

        modal_price = float(row.modal_price)
        gross = modal_price * target_quantity

        if explicit_transport_cost is not None:
            t_cost = float(explicit_transport_cost)
        else:
            market_name = (row.market or "").strip().lower()
            matching_logistics = next(
                (opt for opt in logistics_cache if opt.destination and (market_name in opt.destination.lower() or opt.destination.lower() in market_name)),
                None
            )
            per_q = matching_logistics.cost_per_quintal if matching_logistics else target_transport_per_q
            t_cost = per_q * target_quantity

        if explicit_storage_cost is not None:
            s_cost = float(explicit_storage_cost)
        else:
            s_cost = target_storage_per_q * holding_days * target_quantity

        # Estimated Net Realization = Gross Realization - Transport Cost - Storage Cost
        net = gross - t_cost - s_cost

        options.append({
            "market": row.market,
            "district": row.district,
            "state": row.state,
            "modal_price": round(modal_price, 2),
            "quantity": round(target_quantity, 2),
            "gross_realization": round(gross, 2),
            "transport_cost": round(t_cost, 2),
            "storage_cost": round(s_cost, 2),
            "estimated_net_realization": round(net, 2),
            "government_data_date": str(row.arrival_date) if row.arrival_date else "",
            "arrival_date": str(row.arrival_date) if row.arrival_date else "",
            "source": row.source or "Government Market Data (AGMARKNET / data.gov.in)",
            "is_live_gov_data": (row.source != "DEMO_SEED"),
            "variety": row.variety,
            "min_price": round(row.min_price, 2) if row.min_price is not None else None,
            "max_price": round(row.max_price, 2) if row.max_price is not None else None,
        })

    options.sort(key=lambda x: x["estimated_net_realization"], reverse=True)

    disclaimer_text = (
        "Calculated values are KrishiChakra estimates based on government-reported mandi prices "
        "and logistics assumptions. They are not guaranteed future prices."
    )

    return {
        "commodity": target_commodity,
        "quantity": round(target_quantity, 2),
        "quantity_quintal": round(target_quantity, 2),
        "options": options[:10],
        "disclaimer": disclaimer_text,
        "note": disclaimer_text,
    }

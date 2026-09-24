import json
from datetime import datetime
from typing import Any
import httpx
from ..config import settings

FIELD_ALIASES = {
    "commodity": ["commodity", "commodity_name", "commodityname"],
    "variety": ["variety", "variety_name", "varietyname"],
    "state": ["state", "state_name"],
    "district": ["district", "district_name"],
    "market": ["market", "market_name", "marketname"],
    "arrival_date": ["arrival_date", "arrival date", "arrivals_date", "date"],
    "min_price": ["min_price", "min price", "min_price_rs_quintal", "min"],
    "max_price": ["max_price", "max price", "max_price_rs_quintal", "max"],
    "modal_price": ["modal_price", "modal price", "modal_price_rs_quintal", "modal"],
    "unit": ["unit", "price_unit"],
    "arrival_quantity": ["arrival_quantity", "arrival quantity", "arrivals", "arrival"],
    "source_record_id": ["id", "_id", "record_id", "source_record_id"],
    "source_updated_at": ["updated_at", "last_updated", "timestamp"],
}

def _find(record: dict, aliases: list[str]):
    lowered = {str(k).strip().lower(): v for k, v in record.items()}
    for a in aliases:
        if a in lowered:
            return lowered[a]
    return None

def _num(value):
    if value in (None, "", "-", "NA", "N/A"):
        return None
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return None

def _date(value):
    if not value:
        return None
    if isinstance(value, datetime):
        return value.date()
    text = str(value).strip()
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y", "%Y/%m/%d"):
        try:
            return datetime.strptime(text[:10], fmt).date()
        except ValueError:
            pass
    return None

def _datetime(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).replace(tzinfo=None)
    except ValueError:
        return None

class GovernmentPriceSource:
    async def fetch_records(self) -> list[dict[str, Any]]:
        if not settings.gov_price_api_url:
            raise RuntimeError(
                "GOV_PRICE_API_URL is not configured. Configure the verified official "
                "data.gov.in/AGMARKNET machine-readable endpoint in .env; no fake live data will be used."
            )
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "application/json, text/plain, */*",
        }
        base_params = json.loads(settings.gov_price_request_params_json or "{}")
        if settings.gov_price_api_key:
            if settings.gov_price_auth_mode == "header":
                headers[settings.gov_price_api_key_header] = settings.gov_price_api_key
            else:
                base_params["api-key"] = settings.gov_price_api_key

        target_limit = int(base_params.get("limit", 100))
        all_records: list[dict[str, Any]] = []
        batch_size = 10
        max_batches = min(max(target_limit // batch_size, 1), 20)

        async with httpx.AsyncClient(timeout=45) as client:
            for batch_idx in range(max_batches):
                params = dict(base_params)
                params["offset"] = batch_idx * batch_size
                params["limit"] = batch_size
                response = await client.request(
                    settings.gov_price_http_method,
                    settings.gov_price_api_url,
                    headers=headers,
                    params=params
                )
                response.raise_for_status()
                content_type = response.headers.get("content-type", "")
                if "json" in content_type or response.text.lstrip().startswith(("{", "[")):
                    payload = response.json()
                    records = payload
                    for part in settings.gov_price_records_path.split("."):
                        if part:
                            if not isinstance(records, dict) or part not in records:
                                raise RuntimeError(f"Configured records path '{settings.gov_price_records_path}' was not found.")
                            records = records[part]
                    if not isinstance(records, list):
                        raise RuntimeError("Government endpoint did not return a list of records.")
                    if not records:
                        break
                    all_records.extend(records)
                    # If returned fewer than batch_size or not data.gov.in, stop pagination
                    if len(records) < batch_size or "data.gov.in" not in str(settings.gov_price_api_url):
                        break
                else:
                    raise RuntimeError(
                        "Government endpoint returned a non-JSON response. Add a dedicated verified CSV parser "
                        "for the exact official resource instead of silently scraping HTML."
                    )
        return all_records

    def normalize(self, raw: dict[str, Any]) -> dict[str, Any]:
        result = {k: _find(raw, aliases) for k, aliases in FIELD_ALIASES.items()}
        result["commodity"] = str(result["commodity"] or "").strip()
        result["market"] = str(result["market"] or "").strip()
        result["variety"] = str(result["variety"]).strip() if result["variety"] is not None else None
        result["state"] = str(result["state"]).strip() if result["state"] is not None else None
        result["district"] = str(result["district"]).strip() if result["district"] is not None else None
        result["arrival_date"] = _date(result["arrival_date"])
        for k in ("min_price", "max_price", "modal_price", "arrival_quantity"):
            result[k] = _num(result[k])
        result["unit"] = str(result["unit"] or "Quintal")
        result["source_record_id"] = str(result["source_record_id"]) if result["source_record_id"] is not None else None
        result["source_updated_at"] = _datetime(result["source_updated_at"])
        result["raw_record"] = raw
        return result

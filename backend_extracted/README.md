# KrishiChakra Backend v2

Backend foundation for SIH Problem Statement 132: Strengthening market linkages and price discovery for farmers.

## What is included

- FastAPI backend
- SQLite by default; PostgreSQL via `DATABASE_URL`
- Real government mandi-price ingestion adapter architecture
- data.gov.in / AGMARKNET configuration through environment variables
- Daily sync scheduler
- Manual `POST /api/mandi/sync`
- Latest/historical mandi APIs
- Farmer profiles
- Produce lots
- AI grading demo hook with a clear replacement boundary for a real CV model
- Buyer profiles and transparent matching
- Offers
- Orders / transaction records
- Logistics requests
- Storage options
- FPOs and FPO membership
- Payment tracking
- Disputes / grievances
- Market intelligence / net realization
- Rule-based Krishi Assistant with optional LLM adapter boundary
- Health/status endpoints
- Demo seed script

## Real government data

The backend does NOT invent an API URL. Configure the official machine-readable government resource in `.env`.

Supported configuration:
- `GOV_PRICE_API_URL`
- `GOV_PRICE_API_KEY`
- `GOV_PRICE_API_KEY_HEADER`
- `GOV_PRICE_AUTH_MODE`
- `GOV_PRICE_SOURCE_NAME`
- `GOV_PRICE_HTTP_METHOD`
- `GOV_PRICE_REQUEST_PARAMS_JSON`
- `GOV_PRICE_RECORDS_PATH`

If the official resource is a downloadable JSON/CSV endpoint, point the adapter at that endpoint and set the parser configuration appropriately. The adapter intentionally fails clearly when it cannot identify a valid endpoint instead of silently creating fake "live" prices.

## Run

```bash
python -m venv .venv
# Windows:
.venv\Scripts\activate
pip install -r requirements.txt

copy .env.example .env
python pipelines/seed_demo.py
uvicorn app.main:app --reload
```

Open:
- `/docs`
- `/health`
- `/api/mandi/status`

For PostgreSQL set `DATABASE_URL` in `.env`.

## Scheduler

The daily scheduler uses APScheduler. Configure:
- `PRICE_SYNC_HOUR` (default 6)
- `PRICE_SYNC_MINUTE` (default 30)
- `PRICE_SYNC_TIMEZONE` (default Asia/Kolkata)

Manual sync:
`POST /api/mandi/sync`

## Important

The seed data is only development/demo fallback data. The Flutter production/demo flow must prefer successfully synchronized government data and show its source/date. It must never label seeded data as live government data.

The AI grading endpoint is intentionally a model boundary, not a claim of a trained production model. Replace `app/services/ai_service.py` with YOLO/PyTorch/OpenCV inference when the actual model is available.

# Antigravity implementation sequence

Give these prompts one at a time. Keep the Stitch ZIP, this backend ZIP, and PS 132 available in the workspace.

## 0 — Inspect only
I am providing:
1. Stitch KrishiChakra UI — primary visual reference.
2. KrishiChakra backend v2 — backend foundation.
3. SIH PS 132 — functional requirements.

Inspect all three. Do NOT code yet. Map every Stitch screen to backend endpoints, models and PS requirements. Do not redesign the Stitch UI. Return a concise implementation plan and wait.

## 1 — Flutter foundation
Create/continue the Flutter app using the Stitch UI as the primary visual reference. Recreate the screens faithfully. Use feature-based architecture, repositories/services for API calls, models for backend JSON, and reusable widgets. Mobile-first but responsive for future Flutter Web. Do not redesign.

## 2 — Backend connection
Connect Flutter to the FastAPI backend. Create one API client/repository layer. Add environment-based API base URL. Connect health check first, then farmer profile and produce lot APIs. Handle loading/error/empty states.

## 3 — Real government mandi prices
Connect the Stitch Mandi screens to:
GET /api/mandi/latest
GET /api/mandi/prices
GET /api/mandi/history
GET /api/mandi/status

Show source and last updated date. Never call a static JSON file from Flutter. Never label seed data as live.

## 4 — Mandi filters and charts
Implement commodity/state/district/market filters from the backend. Use history endpoint for price charts. Preserve Stitch visual design.

## 5 — Market intelligence
Connect:
POST /api/intelligence/recommend-sale

Show gross realization, transport cost, storage cost, estimated net realization and market comparison. Clearly label calculations as estimates.

## 6 — Produce lot and AI grading
Connect:
POST /api/produce/lots
POST /api/produce/grade

Build the image-upload/camera UI shown by Stitch. Treat the current grading response as a model boundary unless a real trained model is installed. Never claim a demo response is a trained AI result.

## 7 — Buyer matching
Connect:
GET /api/buyers/matches/{lot_id}
POST /api/buyers/offers

Show verified status, payment reliability, offered price and transparent match explanation.

## 8 — FPO aggregation
Connect FPO endpoints. Implement member/aggregation views according to the Stitch screens. Keep UI faithful.

## 9 — Logistics and storage
Connect:
GET /api/logistics/options
GET /api/logistics/storage

Use these costs in market intelligence where appropriate. Preserve the Stitch transport/storage design.

## 10 — Transactions, payment and disputes
Connect:
POST /api/transactions
GET /api/transactions/{transaction_id}
PATCH /api/transactions/{transaction_id}/payment
POST /api/transactions/disputes

Build the consignment settlement, payment tracking, audit/transaction and dispute flows present in Stitch.

## 11 — Krishi Assistant
Connect POST /api/chatbot/chat. Keep the chatbot UI from Stitch. Display that the prototype assistant is rule-based unless an actual LLM provider is connected.

## 12 — Real-data reliability
Add:
- retry for transient backend errors
- clear stale-data state
- pull-to-refresh
- last successful sync display
- empty-state handling
- network timeout handling

Never substitute fake prices when government synchronization fails.

## 13 — Final integration
Run the backend tests and Flutter analyzer/build. Check every Stitch screen. Check all navigation paths. Check API error states. Confirm that all government price labels show source/date and that seeded demo prices cannot be mistaken for government data.

IMPORTANT:
Do not redesign the Stitch UI.
Do not rewrite the backend unnecessarily.
Do not invent government endpoints or API keys.
Do not claim AI is real until a real model is actually connected.

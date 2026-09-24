# 🌾 KrishiChakra (कृषिचक्र)

> **Strengthening Market Linkages and Transparent Price Discovery for Farmers**  
> *Smart India Hackathon (SIH) — Problem Statement ID: 26132*

---

## 📌 Overview

**KrishiChakra** is an end-to-end market intelligence and transaction enablement platform designed to empower smallholder farmers, Farmer Producer Organizations (FPOs), and institutional buyers. It eliminates intermediaries and informational asymmetry by aggregating live mandi rates, providing AI-assisted crop grading, net realization calculators, smart buyer matching, logistics/storage coordination, transparent digital settlement, and grievance handling.

---

## 🏗️ Repository Architecture

The project consists of three core layers:

```
KrishiChakra/
├── backend_extracted/        # FastAPI Python Backend Service
│   ├── app/                 # Routes, Schemas, Services, & Database Models
│   ├── pipelines/           # Data pipelines & Demo Seed scripts
│   ├── tests/               # Backend endpoint & reliability test suites
│   ├── requirements.txt     # Python dependencies
│   └── README.md            # Backend specific documentation
├── krishichakra_flutter/     # Cross-platform Mobile Application (Flutter)
│   ├── lib/                 # Feature-first stateful screens & repositories
│   │   ├── core/            # API client, models, themes, config
│   │   ├── features/        # Mandi, Produce, Buyers, FPO, Logistics, Settlement
│   │   └── shared/          # Reusable design components & widgets
│   ├── test/                # Unit, widget, and integration tests
│   └── pubspec.yaml         # Flutter dependencies
├── stitch_extracted/         # High-fidelity Stitch UI Prototypes & Screens
│   └── stitch_krishichakra_mobile_authentication_screen/
├── PS 132.txt               # SIH Problem Statement details
└── README.md                # Project Root Documentation
```

---

## 🌟 Key Features

1. **Live Mandi Price Discovery & Intelligence**
   - Real government mandi price ingestion adapter (data.gov.in / AGMARKNET).
   - Localised price trends, arrival volumes, and harvest-sale window recommendations.
   - Net Realization Calculator (accounting for transport, mandi cess, and quality variance).

2. **Produce Listing & AI Quality Grading**
   - Digital produce lot creation at farm gate.
   - Computer-vision-ready grading pipeline (Grade A/B/C defect & quality scoring).

3. **Smart Buyer Matching & FPO Aggregation**
   - Matching farmers and FPOs directly with verified institutional buyers and processors.
   - Aggregated bulk batching for smallholders to gain collective bargaining power.

4. **Farm-to-Mandi Transport & Storage Coordination**
   - On-demand booking for local logistics and nearby cold/dry warehousing to prevent distress selling.

5. **Transparent Transaction Settlements & Grievances**
   - Digital contract notes, milestone payment tracking, and audit-ready dispute resolution.

6. **Krishi Assistant (Multilingual AI Chatbot)**
   - Context-aware advisory answering queries regarding market arrivals, best prices, and scheme info.

---

## 🚀 Getting Started

### 1. Backend Setup (FastAPI)

```bash
cd backend_extracted

# Create and activate virtual environment
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
copy .env.example .env

# Seed initial database
python pipelines/seed_demo.py

# Run development server
uvicorn app.main:app --reload --port 8000
```
- Swagger Documentation: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`

### 2. Mobile App Setup (Flutter)

```bash
cd krishichakra_flutter

# Fetch Flutter packages
flutter pub get

# Run tests
flutter test

# Launch on connected device / emulator
flutter run
```

---

## 🛡️ License

This project is developed for the Smart India Hackathon.

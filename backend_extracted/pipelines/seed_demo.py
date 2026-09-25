"""
KrishiChakra — Demo Seed Script
================================
Populates the database with:
  * 1 Demo Farmer (if absent)
  * 30 DEMO buyer profiles (Maharashtra-focused, clearly synthetic)
  * 4 Logistics options
  * 4 Storage options

WARNING: These are DEMO / PROTOTYPE records only.
   They are NOT real companies or verified real buyers.
   All names use the "Demo ..." prefix to make this explicit.
"""

from app.database import Base, engine, SessionLocal
from app.models import Farmer, Buyer, LogisticsOption, StorageOption

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# ---- Farmer ------------------------------------------------------------------

if not db.query(Farmer).count():
    db.add(Farmer(
        name="Demo Farmer - Nashik",
        phone="9999999999",
        village="Demo Village",
        district="Nashik",
        state="Maharashtra",
        land_acres=5.5,
        vulnerability_score=0.40,
        liquidity_need=0.65,
    ))
    print("Demo Farmer seeded.")

# ---- DEMO BUYERS -------------------------------------------------------------
# All names use "Demo ..." prefix — clearly synthetic, never real companies.

DEMO_BUYERS = [
    # ONION
    dict(name="Demo Onion Processor - Nashik", buyer_type="Processor",
         district="Nashik", state="Maharashtra", verified=True,
         payment_reliability=0.92, demand_commodity="Onion",
         min_quantity=50, max_quantity=800,
         quality_requirements="Grade A, Grade B", offered_price=1850),
    dict(name="Demo Onion Export Aggregator - Lasalgaon", buyer_type="Exporter",
         district="Nashik", state="Maharashtra", verified=True,
         payment_reliability=0.95, demand_commodity="Onion",
         min_quantity=100, max_quantity=2000,
         quality_requirements="Export Grade A", offered_price=2100),
    dict(name="Demo Onion Wholesaler - Pune", buyer_type="Wholesaler",
         district="Pune", state="Maharashtra", verified=False,
         payment_reliability=0.70, demand_commodity="Onion",
         min_quantity=20, max_quantity=400,
         quality_requirements="Grade A, Grade B, Grade C", offered_price=1650),
    dict(name="Demo Dehydration Unit - Ahmednagar", buyer_type="Processor",
         district="Ahmednagar", state="Maharashtra", verified=True,
         payment_reliability=0.88, demand_commodity="Onion",
         min_quantity=30, max_quantity=600,
         quality_requirements="Grade B, Grade C", offered_price=1500),
    dict(name="Demo Institutional Buyer - Mumbai (Onion)", buyer_type="Institutional",
         district="Mumbai", state="Maharashtra", verified=True,
         payment_reliability=0.97, demand_commodity="Onion",
         min_quantity=10, max_quantity=300,
         quality_requirements="Grade A", offered_price=2000),

    # TOMATO
    dict(name="Demo Tomato Processor - Pune", buyer_type="Processor",
         district="Pune", state="Maharashtra", verified=True,
         payment_reliability=0.90, demand_commodity="Tomato",
         min_quantity=25, max_quantity=500,
         quality_requirements="Grade A, Grade B", offered_price=3200),
    dict(name="Demo Fresh Produce Aggregator - Nashik", buyer_type="Aggregator",
         district="Nashik", state="Maharashtra", verified=True,
         payment_reliability=0.85, demand_commodity="Tomato",
         min_quantity=15, max_quantity=350,
         quality_requirements="Grade A", offered_price=3500),
    dict(name="Demo Institutional Buyer - Aurangabad (Tomato)", buyer_type="Institutional",
         district="Aurangabad", state="Maharashtra", verified=True,
         payment_reliability=0.93, demand_commodity="Tomato",
         min_quantity=5, max_quantity=200,
         quality_requirements="Grade A", offered_price=3800),
    dict(name="Demo Ketchup Factory - Satara", buyer_type="Processor",
         district="Satara", state="Maharashtra", verified=False,
         payment_reliability=0.75, demand_commodity="Tomato",
         min_quantity=50, max_quantity=1000,
         quality_requirements="Grade B, Grade C", offered_price=2600),
    dict(name="Demo Vegetable Wholesaler - Solapur", buyer_type="Wholesaler",
         district="Solapur", state="Maharashtra", verified=False,
         payment_reliability=0.68, demand_commodity="Tomato",
         min_quantity=10, max_quantity=250,
         quality_requirements="Grade A, Grade B", offered_price=2900),

    # POTATO
    dict(name="Demo Potato Chip Manufacturer - Pune", buyer_type="Processor",
         district="Pune", state="Maharashtra", verified=True,
         payment_reliability=0.94, demand_commodity="Potato",
         min_quantity=100, max_quantity=2000,
         quality_requirements="Grade A, Dry starch variety", offered_price=1200),
    dict(name="Demo Cold-Chain Aggregator - Kolhapur", buyer_type="Aggregator",
         district="Kolhapur", state="Maharashtra", verified=True,
         payment_reliability=0.89, demand_commodity="Potato",
         min_quantity=40, max_quantity=800,
         quality_requirements="Grade A, Grade B", offered_price=1050),
    dict(name="Demo Institutional Buyer - Mumbai (Potato)", buyer_type="Institutional",
         district="Mumbai", state="Maharashtra", verified=True,
         payment_reliability=0.96, demand_commodity="Potato",
         min_quantity=10, max_quantity=400,
         quality_requirements="Grade A", offered_price=1350),
    dict(name="Demo Potato Wholesaler - Nagpur", buyer_type="Wholesaler",
         district="Nagpur", state="Maharashtra", verified=False,
         payment_reliability=0.72, demand_commodity="Potato",
         min_quantity=20, max_quantity=500,
         quality_requirements="Grade A, Grade B, Grade C", offered_price=900),
    dict(name="Demo Food Processing Buyer - Ahmednagar (Potato)", buyer_type="Processor",
         district="Ahmednagar", state="Maharashtra", verified=True,
         payment_reliability=0.87, demand_commodity="Potato",
         min_quantity=50, max_quantity=1200,
         quality_requirements="Grade B", offered_price=980),

    # GUAVA
    dict(name="Demo Fruit Aggregator - Nashik", buyer_type="Aggregator",
         district="Nashik", state="Maharashtra", verified=True,
         payment_reliability=0.88, demand_commodity="Guava",
         min_quantity=10, max_quantity=200,
         quality_requirements="Grade A", offered_price=4200),
    dict(name="Demo Fruit Juice Processor - Pune", buyer_type="Processor",
         district="Pune", state="Maharashtra", verified=True,
         payment_reliability=0.91, demand_commodity="Guava",
         min_quantity=20, max_quantity=400,
         quality_requirements="Grade A, Grade B", offered_price=3800),
    dict(name="Demo Retail Chain Sourcing - Thane", buyer_type="Retail",
         district="Thane", state="Maharashtra", verified=True,
         payment_reliability=0.96, demand_commodity="Guava",
         min_quantity=5, max_quantity=100,
         quality_requirements="Grade A (premium size)", offered_price=5000),

    # GRAPES
    dict(name="Demo Grape Export Aggregator - Sangli", buyer_type="Exporter",
         district="Sangli", state="Maharashtra", verified=True,
         payment_reliability=0.95, demand_commodity="Grapes",
         min_quantity=50, max_quantity=1000,
         quality_requirements="Export Grade A, EU certified", offered_price=9500),
    dict(name="Demo Raisin Processor - Solapur", buyer_type="Processor",
         district="Solapur", state="Maharashtra", verified=True,
         payment_reliability=0.90, demand_commodity="Grapes",
         min_quantity=30, max_quantity=600,
         quality_requirements="Grade A, Grade B (seedless)", offered_price=8200),

    # WHEAT
    dict(name="Demo Flour Mill - Aurangabad", buyer_type="Processor",
         district="Aurangabad", state="Maharashtra", verified=True,
         payment_reliability=0.93, demand_commodity="Wheat",
         min_quantity=200, max_quantity=5000,
         quality_requirements="Grade A, moisture < 12%", offered_price=2400),
    dict(name="Demo Grain Aggregator - Latur", buyer_type="Aggregator",
         district="Latur", state="Maharashtra", verified=False,
         payment_reliability=0.78, demand_commodity="Wheat",
         min_quantity=100, max_quantity=3000,
         quality_requirements="Grade A, Grade B", offered_price=2200),

    # SOYBEAN
    dict(name="Demo Soybean Oil Processor - Latur", buyer_type="Processor",
         district="Latur", state="Maharashtra", verified=True,
         payment_reliability=0.91, demand_commodity="Soybean",
         min_quantity=100, max_quantity=2000,
         quality_requirements="Grade A, moisture < 10%", offered_price=5100),
    dict(name="Demo Agro Commodity Trader - Osmanabad", buyer_type="Trader",
         district="Osmanabad", state="Maharashtra", verified=False,
         payment_reliability=0.73, demand_commodity="Soybean",
         min_quantity=50, max_quantity=1000,
         quality_requirements="Grade A, Grade B", offered_price=4800),

    # COTTON
    dict(name="Demo Cotton Ginning Factory - Akola", buyer_type="Processor",
         district="Akola", state="Maharashtra", verified=True,
         payment_reliability=0.90, demand_commodity="Cotton",
         min_quantity=50, max_quantity=1500,
         quality_requirements="Medium Staple, Shankar-6", offered_price=7200),
    dict(name="Demo Textile Mill Sourcing - Ichalkaranji", buyer_type="Industrial",
         district="Kolhapur", state="Maharashtra", verified=True,
         payment_reliability=0.94, demand_commodity="Cotton",
         min_quantity=100, max_quantity=3000,
         quality_requirements="Long Staple, Grade A", offered_price=8000),

    # POMEGRANATE
    dict(name="Demo Pomegranate Exporter - Solapur", buyer_type="Exporter",
         district="Solapur", state="Maharashtra", verified=True,
         payment_reliability=0.96, demand_commodity="Pomegranate",
         min_quantity=20, max_quantity=400,
         quality_requirements="Bhagwa Grade A, Export", offered_price=11500),
    dict(name="Demo Juice Processor - Ahmednagar (Pomegranate)", buyer_type="Processor",
         district="Ahmednagar", state="Maharashtra", verified=True,
         payment_reliability=0.88, demand_commodity="Pomegranate",
         min_quantity=10, max_quantity=200,
         quality_requirements="Grade A, Grade B", offered_price=9800),

    # BANANA
    dict(name="Demo Banana Aggregator - Jalgaon", buyer_type="Aggregator",
         district="Jalgaon", state="Maharashtra", verified=True,
         payment_reliability=0.89, demand_commodity="Banana",
         min_quantity=30, max_quantity=600,
         quality_requirements="Grand Naine Grade A", offered_price=1900),
    dict(name="Demo Retail Fruit Chain - Pune (Banana)", buyer_type="Retail",
         district="Pune", state="Maharashtra", verified=False,
         payment_reliability=0.76, demand_commodity="Banana",
         min_quantity=5, max_quantity=150,
         quality_requirements="Grade A", offered_price=2100),
]

if not db.query(Buyer).count():
    for b in DEMO_BUYERS:
        db.add(Buyer(**b))
    print(f"{len(DEMO_BUYERS)} DEMO buyer profiles seeded (synthetic, not real buyers).")
else:
    existing = db.query(Buyer).count()
    print(f"Buyers table already has {existing} records -- skipping buyer seed.")

# ---- Logistics ---------------------------------------------------------------

DEMO_LOGISTICS = [
    dict(provider_name="Demo Transporter - Nashik to Pune", vehicle_type="Mini Truck (4T)",
         vehicle_number="MH-15-DM-1001", driver_name="Demo Driver - Ravi Patil",
         driver_phone="9800000001", driver_rating=4.8, verified_trips=120,
         origin="Nashik", destination="Pune", cost_per_quintal=180,
         capacity_quintal=100, is_empty_return=False, discount_percentage=0.0,
         distance_km=213, transit_duration_minutes=270, ventilated=True,
         gps_active=True, departure_time="06:00 AM", available=True),
    dict(provider_name="Demo Transporter - Nashik to Mumbai", vehicle_type="Truck (8T)",
         vehicle_number="MH-15-DM-2002", driver_name="Demo Driver - Suresh Jadhav",
         driver_phone="9800000002", driver_rating=4.6, verified_trips=85,
         origin="Nashik", destination="Mumbai", cost_per_quintal=220,
         capacity_quintal=200, is_empty_return=True, discount_percentage=10.0,
         distance_km=167, transit_duration_minutes=210, ventilated=True,
         gps_active=True, departure_time="05:30 AM", available=True),
    dict(provider_name="Demo Transporter - Pune to Solapur", vehicle_type="Mini Truck (4T)",
         vehicle_number="MH-12-DM-3003", driver_name="Demo Driver - Anand More",
         driver_phone="9800000003", driver_rating=4.5, verified_trips=60,
         origin="Pune", destination="Solapur", cost_per_quintal=200,
         capacity_quintal=100, is_empty_return=False, discount_percentage=0.0,
         distance_km=243, transit_duration_minutes=300, ventilated=True,
         gps_active=True, departure_time="07:00 AM", available=True),
    dict(provider_name="Demo Refrigerated Van - Nashik to Aurangabad",
         vehicle_type="Refrigerated Van (3T)", vehicle_number="MH-15-DM-4004",
         driver_name="Demo Driver - Manoj Shinde", driver_phone="9800000004",
         driver_rating=4.9, verified_trips=200, origin="Nashik",
         destination="Aurangabad", cost_per_quintal=280, capacity_quintal=60,
         is_empty_return=False, discount_percentage=5.0, distance_km=186,
         transit_duration_minutes=240, ventilated=True, gps_active=True,
         departure_time="05:00 AM", available=True),
]

if not db.query(LogisticsOption).count():
    for lo in DEMO_LOGISTICS:
        db.add(LogisticsOption(**lo))
    print(f"{len(DEMO_LOGISTICS)} demo logistics options seeded.")
else:
    print("Logistics table already has records -- skipping.")

# ---- Storage -----------------------------------------------------------------

DEMO_STORAGE = [
    dict(provider_name="Demo Cold Storage - Nashik APMC", location="Nashik",
         district="Nashik", state="Maharashtra", capacity_quintal=5000,
         available_capacity_quintal=2800, cost_per_quintal_day=12,
         distance_km=3.5, storage_type="Cold Storage", is_certified=True,
         enwr_loan_eligible=True, loan_advance_pct=70.0, available=True),
    dict(provider_name="Demo Cold Storage - Pune Market", location="Pune",
         district="Pune", state="Maharashtra", capacity_quintal=3000,
         available_capacity_quintal=1500, cost_per_quintal_day=15,
         distance_km=5.0, storage_type="Cold Storage", is_certified=True,
         enwr_loan_eligible=True, loan_advance_pct=70.0, available=True),
    dict(provider_name="Demo Warehouse - Ahmednagar", location="Ahmednagar",
         district="Ahmednagar", state="Maharashtra", capacity_quintal=2000,
         available_capacity_quintal=1200, cost_per_quintal_day=8,
         distance_km=2.0, storage_type="Ambient Warehouse", is_certified=True,
         enwr_loan_eligible=True, loan_advance_pct=65.0, available=True),
    dict(provider_name="Demo CA Store - Satara", location="Satara",
         district="Satara", state="Maharashtra", capacity_quintal=1500,
         available_capacity_quintal=900, cost_per_quintal_day=18,
         distance_km=8.0, storage_type="CA (Controlled Atmosphere)",
         is_certified=True, enwr_loan_eligible=True, loan_advance_pct=75.0,
         available=True),
]

if not db.query(StorageOption).count():
    for so in DEMO_STORAGE:
        db.add(StorageOption(**so))
    print(f"{len(DEMO_STORAGE)} demo storage options seeded.")
else:
    print("Storage table already has records -- skipping.")

db.commit()
db.close()
print("\nDemo seed complete -- KrishiChakra prototype database is ready.")
print("WARNING: All buyer/logistics/storage records are DEMO ONLY. Not real companies.")

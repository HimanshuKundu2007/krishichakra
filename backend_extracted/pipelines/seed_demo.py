from datetime import date
from app.database import Base, engine, SessionLocal
from app.models import Farmer, Buyer, LogisticsOption, StorageOption, MandiPrice

Base.metadata.create_all(bind=engine)
db = SessionLocal()

if not db.query(Farmer).count():
    farmer = Farmer(name="Demo Farmer", phone="9999999999", village="Demo Village", district="Pune", state="Maharashtra", land_acres=4, vulnerability_score=.4, liquidity_need=.6)
    db.add(farmer)
if not db.query(Buyer).count():
    db.add(Buyer(name="Demo Institutional Buyer", buyer_type="Institutional", district="Pune", state="Maharashtra", verified=True, payment_reliability=.9, demand_commodity="Tomato", min_quantity=5, max_quantity=500, quality_requirements="Grade A/B", offered_price=3000))
if not db.query(LogisticsOption).count():
    db.add(LogisticsOption(provider_name="Demo Transporter", vehicle_type="Mini Truck", origin="Pune", destination="Nashik", cost_per_quintal=180, capacity_quintal=100))
if not db.query(StorageOption).count():
    db.add(StorageOption(provider_name="Demo Cold Storage", location="Pune", capacity_quintal=500, cost_per_quintal_day=15))
db.commit()
print("Demo entities seeded. Use /api/mandi/seed-demo only for development.")

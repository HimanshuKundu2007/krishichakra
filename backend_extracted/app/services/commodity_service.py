from typing import Optional
import re
from sqlalchemy.orm import Session
from sqlalchemy import desc, func, or_
from ..models import MandiPrice
from ..schemas import CommodityCatalogueItem

# Standardized mapping from lowercased raw government names to clean normalized names
RAW_TO_NORMALIZED: dict[str, str] = {
    # Alliums
    "onion": "Onion",
    "red onion": "Onion",
    "onion green": "Onion",
    "garlic": "Garlic",
    
    # Solanaceae
    "tomato": "Tomato",
    "potato": "Potato",
    "brinjal": "Brinjal",
    "green chilli": "Chilli",
    "chilli red": "Chilli",
    "chili red": "Chilli",
    "chilly capsicum": "Capsicum",
    "capsicum": "Capsicum",
    "dry chillies": "Chilli",
    
    # Grains & Cereals
    "wheat": "Wheat",
    "paddy(common)": "Paddy",
    "paddy": "Paddy",
    "rice": "Paddy",
    "maize": "Maize",
    "jowar(sorghum)": "Jowar",
    "jowar": "Jowar",
    "bajra(pearl millet/cumbu)": "Bajra",
    "bajra": "Bajra",
    "barley(jau)": "Barley",
    "ragi(finger millet)": "Ragi",
    "kodo millet(varagu)": "Kodo Millet",
    "kutki": "Kutki (Millet)",
    
    # Oilseeds & Commercial Crops
    "soyabean": "Soybean",
    "soybean": "Soybean",
    "cotton": "Cotton",
    "groundnut": "Groundnut",
    "ground nut seed": "Groundnut",
    "mustard": "Mustard",
    "sesamum(sesame,gingelly,til)": "Sesame (Til)",
    "safflower": "Safflower (Kardi)",
    "castor seed": "Castor Seed",
    "gur(jaggery)": "Jaggery",
    "sugar": "Sugarcane",
    
    # Pulses & Legumes
    "bengal gram(gram)(whole)": "Gram (Chana)",
    "bengal gram dal(chana dal)": "Chana Dal",
    "gram raw(chholia)": "Gram (Raw)",
    "red gram/arhar/tur(whole)": "Tur (Arhar)",
    "tur/arhar": "Tur (Arhar)",
    "tur": "Tur (Arhar)",
    "red gram split/arhar dal/tur dal": "Tur Dal",
    "black gram(urd beans)(whole)": "Urad",
    "black gram dal(urd dal)": "Urad Dal",
    "green gram(moong)(whole)": "Moong",
    "green gram dal(moong dal)": "Moong Dal",
    "lentil(masur)(whole)": "Masoor",
    "masur dal": "Masoor Dal",
    "moath dal": "Matki (Moth)",
    "cowpea(lobia/karamani)": "Cowpea (Chawli)",
    "cowpea(veg)": "Cowpea",
    "field pea": "Peas",
    "peas wet": "Peas",
    "green peas": "Peas",
    "pea pod/pea cod/हरी मटर": "Peas",
    
    # Gourds & Cucurbits
    "cucumbar(kheera)": "Cucumber",
    "cucumber": "Cucumber",
    "sponge gourd": "Sponge Gourd",
    "ridgeguard(tori)": "Ridge Gourd",
    "bottle gourd": "Bottle Gourd",
    "bitter gourd": "Bitter Gourd",
    "round gourd": "Round Gourd",
    "little gourd(kundru)": "Kundru",
    "pointed gourd(parval)": "Parwal",
    "snakeguard": "Snake Gourd",
    "ashgourd": "Ash Gourd",
    "pumpkin": "Pumpkin",
    "sweet pumpkin": "Pumpkin",
    "water melon": "Watermelon",
    "karbuja(musk melon)": "Muskmelon",
    
    # Fruits
    "banana": "Banana",
    "banana - green": "Banana",
    "guava": "Guava",
    "orange": "Orange",
    "mousambi(sweet lime)": "Sweet Lime (Mosambi)",
    "pomegranate": "Pomegranate",
    "grapes": "Grapes",
    "papaya": "Papaya",
    "mango": "Mango",
    "mango(raw-ripe)": "Mango",
    "apple": "Apple",
    "chikoos(sapota)": "Chikoo",
    "seetapal": "Custard Apple",
    "pineapple": "Pineapple",
    "pear(marasebu)": "Pear",
    
    # Vegetables & Greens
    "cauliflower": "Cauliflower",
    "cabbage": "Cabbage",
    "bhindi(ladies finger)": "Bhindi (Okra)",
    "ladies finger": "Bhindi (Okra)",
    "carrot": "Carrot",
    "beetroot": "Beetroot",
    "raddish": "Radish",
    "beans": "Beans",
    "french beans(frasbean)": "French Beans",
    "cluster beans": "Cluster Beans",
    "guar": "Guar",
    "guar seed(cluster beans seed)": "Guar",
    "drumstick": "Drumstick",
    "spinach": "Spinach",
    "amaranthus": "Amaranthus",
    "colacasia": "Colocasia (Arbi)",
    "elephant yam(suran)/amorphophallus": "Elephant Yam (Suran)",
    "sweet potato": "Sweet Potato",
    "tapioca": "Tapioca",
    
    # Spices & Condiments
    "ginger(green)": "Ginger",
    "ginger(dry)": "Ginger",
    "ginger": "Ginger",
    "turmeric": "Turmeric",
    "coriander(leaves)": "Coriander",
    "corriander seed": "Coriander Seeds",
    "methi(leaves)": "Methi",
    "methi seeds": "Methi Seeds",
    "mint(pudina)": "Mint (Pudina)",
    "black pepper": "Black Pepper",
    "tamarind fruit": "Tamarind",
    
    # Plantation & Misc
    "coconut": "Coconut",
    "tender coconut": "Coconut",
    "coconut seed": "Coconut",
    "cashewnuts": "Cashew",
    "lemon": "Lemon",
    "lime": "Lime",
    "amla(nelli kai)": "Amla",
    "raisins": "Raisins",
    "isabgul(psyllium)": "Isabgol",
}

COMMODITY_ICONS: dict[str, str] = {
    "Onion": "🧅",
    "Tomato": "🍅",
    "Potato": "🥔",
    "Soybean": "🌱",
    "Wheat": "🌾",
    "Paddy": "🌾",
    "Garlic": "🧄",
    "Chilli": "🌶️",
    "Banana": "🍌",
    "Guava": "🍐",
    "Orange": "🍊",
    "Sweet Lime (Mosambi)": "🍋",
    "Pomegranate": "🍎",
    "Grapes": "🍇",
    "Papaya": "🍈",
    "Maize": "🌽",
    "Cotton": "☁️",
    "Jaggery": "🍯",
    "Brinjal": "🍆",
    "Carrot": "🥕",
    "Cucumber": "🥒",
    "Sponge Gourd": "🥒",
    "Ridge Gourd": "🥒",
    "Bottle Gourd": "🥒",
    "Bitter Gourd": "🥒",
    "Round Gourd": "🥒",
    "Kundru": "🥒",
    "Parwal": "🥒",
    "Snake Gourd": "🥒",
    "Ash Gourd": "🥒",
    "Cauliflower": "🥦",
    "Cabbage": "🥬",
    "Ginger": "🫚",
    "Turmeric": "🟨",
    "Gram (Chana)": "🫘",
    "Tur (Arhar)": "🫘",
    "Moong": "🫘",
    "Urad": "🫘",
    "Jowar": "🌾",
    "Bajra": "🌾",
    "Groundnut": "🥜",
    "Bhindi (Okra)": "🥬",
    "Apple": "🍎",
    "Mango": "🥭",
    "Watermelon": "🍉",
    "Muskmelon": "🍈",
    "Peas": "🫛",
    "Spinach": "🥬",
    "Methi": "🌿",
    "Coriander": "🌿",
    "Mint (Pudina)": "🌿",
    "Coconut": "🥥",
    "Lemon": "🍋",
    "Lime": "🍋",
    "Radish": "🥕",
    "Beetroot": "🫐",
    "Pumpkin": "🎃",
    "Custard Apple": "🍈",
    "Chikoo": "🥔",
    "Pineapple": "🍍",
    "Capsicum": "🫑",
    "Sugarcane": "🎋",
}

def normalize_commodity_name(raw_name: str | None) -> str:
    if not raw_name:
        return "Unknown"
    clean = raw_name.strip()
    key = clean.lower()
    if key in RAW_TO_NORMALIZED:
        return RAW_TO_NORMALIZED[key]
    # Check without parenthetical text: e.g. "Chilli (Green)" -> "Chilli"
    base = re.sub(r'\(.*?\)', '', clean).strip()
    if base.lower() in RAW_TO_NORMALIZED:
        return RAW_TO_NORMALIZED[base.lower()]
    return base.title() if base else clean.title()

def get_commodity_icon(normalized_name: str) -> str:
    return COMMODITY_ICONS.get(normalized_name, "🌾")

def get_raw_commodity_aliases(query: str | None) -> list[str]:
    """
    Returns all raw government commodity strings that map to or match the query.
    Handles cross-spelling like Soybean <-> Soyabean, Paddy <-> Rice <-> Paddy(Common),
    Chilli <-> Green Chilli <-> Chilli Red, etc.
    """
    if not query:
        return []
    clean = query.strip()
    clean_lower = clean.lower()
    
    # 1. Direct normalized name match
    matches = set()
    matches.add(clean)

    # Check if query matches a normalized name directly or via RAW_TO_NORMALIZED
    target_norm = normalize_commodity_name(clean)

    for raw_k, norm_v in RAW_TO_NORMALIZED.items():
        if norm_v.lower() == target_norm.lower() or norm_v.lower() == clean_lower:
            matches.add(raw_k)
        elif clean_lower in raw_k or raw_k in clean_lower:
            matches.add(raw_k)

    return list(matches)

def apply_commodity_filter(query, commodity_param: str | None):
    """
    Filters a SQLAlchemy MandiPrice query using normalized alias expansion.
    """
    if not commodity_param:
        return query
    clean = commodity_param.strip()
    if clean.lower() == 'all':
        return query
        
    aliases = get_raw_commodity_aliases(clean)
    if not aliases:
        return query.filter(MandiPrice.commodity.ilike(f"%{clean}%"))
        
    clauses = [MandiPrice.commodity.ilike(f"%{a}%") for a in aliases]
    return query.filter(or_(*clauses))

def get_commodity_catalogue(db: Session, state: Optional[str] = None) -> list[CommodityCatalogueItem]:
    """
    Builds the unified normalized commodity catalogue from actual database records.
    Filters by state (e.g. Maharashtra) if requested.
    """
    q = db.query(MandiPrice).filter(MandiPrice.source != "DEMO_SEED")
    if state and state.strip().lower() != 'all india':
        q = q.filter(MandiPrice.state.ilike(f"%{state.strip()}%"))

    # Pull distinct commodity records with summary statistics
    records = q.order_by(desc(MandiPrice.arrival_date)).all()
    
    # Group by normalized commodity name
    grouped: dict[str, dict] = {}
    for r in records:
        norm = normalize_commodity_name(r.commodity)
        if norm not in grouped:
            grouped[norm] = {
                "commodity_name": r.commodity,
                "normalized_name": norm,
                "category": "Crops",
                "icon": get_commodity_icon(norm),
                "available_varieties": set(),
                "record_count": 0,
                "latest_modal_price": r.modal_price,
                "min_price": r.min_price,
                "max_price": r.max_price,
                "price_unit": r.unit or "Quintal",
                "latest_arrival_date": r.arrival_date,
                "states": set(),
                "has_maharashtra_records": False,
            }
        
        item = grouped[norm]
        item["record_count"] += 1
        if r.variety and r.variety != "Other":
            item["available_varieties"].add(r.variety)
        if r.state:
            item["states"].add(r.state)
            if "maharashtra" in r.state.lower():
                item["has_maharashtra_records"] = True
                
        # Keep track of price ranges
        if r.min_price is not None:
            if item["min_price"] is None or r.min_price < item["min_price"]:
                item["min_price"] = r.min_price
        if r.max_price is not None:
            if item["max_price"] is None or r.max_price > item["max_price"]:
                item["max_price"] = r.max_price

    # Priority sorting list for high-demand agricultural commodities
    priority_order = [
        "Wheat", "Paddy", "Sponge Gourd", "Garlic", "Chilli", "Onion", "Tomato", "Potato", "Soybean",
        "Banana", "Guava", "Cotton", "Maize",
        "Pomegranate", "Grapes", "Orange", "Sweet Lime (Mosambi)",
        "Jaggery", "Gram (Chana)", "Tur (Arhar)", "Jowar", "Bajra",
        "Brinjal", "Cauliflower", "Cabbage", "Ginger", "Turmeric"
    ]
    priority_map = {name.lower(): idx for idx, name in enumerate(priority_order)}

    catalogue: list[CommodityCatalogueItem] = []
    for norm_name, data in grouped.items():
        catalogue.append(
            CommodityCatalogueItem(
                commodity_name=data["commodity_name"],
                normalized_name=norm_name,
                category=data["category"],
                icon=data["icon"],
                available_varieties=sorted(data["available_varieties"]),
                record_count=data["record_count"],
                latest_modal_price=data["latest_modal_price"],
                min_price=data["min_price"],
                max_price=data["max_price"],
                price_unit=data["price_unit"],
                latest_arrival_date=data["latest_arrival_date"],
                states=sorted(data["states"]),
                has_maharashtra_records=data["has_maharashtra_records"],
            )
        )

    # Sort by priority order first, then record count descending
    catalogue.sort(
        key=lambda x: (
            priority_map.get(x.normalized_name.lower(), 999),
            -x.record_count
        )
    )

    return catalogue

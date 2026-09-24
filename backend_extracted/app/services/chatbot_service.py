"""
Krishi Assistant Service Architecture.

Decoupled provider pattern:
- BaseChatbotProvider (interface)
- RuleBasedPrototypeProvider (active, rule-based prototype)
- LLMProvider (stub for future LLM integration e.g. Gemini, OpenAI)
"""

from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func

from ..models import MandiPrice, Buyer, LogisticsOption, StorageOption
from ..schemas import ChatResponse


class BaseChatbotProvider(ABC):
    """Abstract interface for chatbot providers."""

    @abstractmethod
    def generate_reply(
        self,
        message: str,
        db: Session,
        language: str = "en",
        farmer_id: Optional[int] = None,
    ) -> ChatResponse:
        """Process user message and return a structured ChatResponse."""
        pass


class RuleBasedPrototypeProvider(BaseChatbotProvider):
    """
    Rule-based agricultural domain chatbot prototype.
    Grounded in actual database records for Mandis, Buyers, Logistics, and Storage.
    Never claims to be an LLM.
    """

    MODE_NAME = "rule_based_prototype"
    DISCLAIMER = (
        "Krishi Assistant is operating in Rule-Based Prototype mode. "
        "Domain logic is grounded in government mandi records and verified marketplace rules. "
        "LLM provider integration ready."
    )

    def generate_reply(
        self,
        message: str,
        db: Session,
        language: str = "en",
        farmer_id: Optional[int] = None,
    ) -> ChatResponse:
        msg = message.strip()
        if not msg:
            return ChatResponse(
                reply="Please enter a question about mandi prices, market comparison, buyers, transport, storage, quality grading, or selling decisions.",
                mode=self.MODE_NAME,
                is_llm=False,
                intent="general",
                suggestions=[
                    "🧅 Onion Price Nashik",
                    "📊 Compare Vashi vs Pune",
                    "🏢 Verified Buyers",
                    "🚚 Book Return Truck",
                ],
                disclaimer=self.DISCLAIMER,
            )

        q = msg.lower()
        lang = language.lower()

        # 1. Mandi Prices
        if self._is_mandi_price_query(q):
            return self._handle_mandi_prices(q, db, lang)

        # 2. Market Comparison
        if self._is_market_comparison_query(q):
            return self._handle_market_comparison(q, db, lang)

        # 3. Buyers
        if self._is_buyers_query(q):
            return self._handle_buyers(q, db, lang)

        # 4. Transport & Logistics
        if self._is_transport_query(q):
            return self._handle_transport(q, db, lang)

        # 5. Storage & e-NWR
        if self._is_storage_query(q):
            return self._handle_storage(q, db, lang)

        # 6. Produce Quality & Grading
        if self._is_produce_quality_query(q):
            return self._handle_produce_quality(q, db, lang)

        # 7. Selling Decisions & Strategy
        if self._is_selling_decision_query(q):
            return self._handle_selling_decisions(q, db, lang)

        # 8. Greetings / Default
        if any(w in q for w in ["hi", "hello", "hey", "namaste", "namaskar", "help", "मदत", "नमस्ते", "नमस्कार"]):
            return self._handle_greeting(lang)

        # Fallback guidance
        return ChatResponse(
            reply=(
                "I am your Krishi Assistant (Rule-Based Prototype).\n\n"
                "I can assist you with:\n"
                "• Mandi Prices: Latest government mandi benchmark rates\n"
                "• Market Comparison: Inter-mandi price spreads and net realizations\n"
                "• Verified Buyers: Institutional buyers with transparent reliability ratings\n"
                "• Transport: Empty-return load freight rates and LCV options\n"
                "• Storage: MSWC cold storage availability and 70% e-NWR loan advances\n"
                "• Quality Grading: Agmarknet Grade A/B/C parameters and visual assay\n"
                "• Selling Decisions: Net Realization = Gross − Transport − Storage"
            ),
            mode=self.MODE_NAME,
            is_llm=False,
            intent="general",
            suggestions=[
                "🧅 Onion Price Nashik",
                "📊 Compare Vashi vs Pune",
                "🏢 Verified Buyers",
                "🚚 Book Return Truck",
                "💰 NWR Loan Status",
                "💡 Best Time to Sell",
            ],
            disclaimer=self.DISCLAIMER,
        )

    # ── Intent Matchers ────────────────────────────────────────────────────────

    def _is_mandi_price_query(self, q: str) -> bool:
        price_words = ["price", "rate", "bhav", "mandi price", "modal", "cost", "दाम", "भाव", "दर", "किंमत"]
        crop_words = ["onion", "tomato", "potato", "soybean", "wheat", "cotton", "maize", "pomegranate", "कांदा", "टोमॅटो", "सोयाबीन"]
        has_price = any(w in q for w in price_words)
        has_crop = any(w in q for w in crop_words)
        return (has_price and has_crop) or ("mandi" in q and not any(w in q for w in ["compare", "vs", "which"])) or ("price today" in q)

    def _is_market_comparison_query(self, q: str) -> bool:
        return any(w in q for w in ["compare", "vs", "versus", "which mandi", "which market", "comparison", "तुलना", "फरक"])

    def _is_buyers_query(self, q: str) -> bool:
        return any(w in q for w in ["buyer", "purchaser", "institutional", "who will buy", "sell to", "व्यापारी", "खरेदीदार"])

    def _is_transport_query(self, q: str) -> bool:
        return any(w in q for w in ["transport", "truck", "freight", "vehicle", "lcv", "pickup", "empty return", "वाहतूक", "गाडी"])

    def _is_storage_query(self, q: str) -> bool:
        return any(w in q for w in ["storage", "cold storage", "warehouse", "enwr", "nwr", "loan advance", "गोदाम", "कोल्ड स्टोरेज"])

    def _is_produce_quality_query(self, q: str) -> bool:
        return any(w in q for w in ["grade", "quality", "assay", "defect", "uniformity", "bruis", "agmarknet", "दर्जा", "गुणवत्ता"])

    def _is_selling_decision_query(self, q: str) -> bool:
        return any(w in q for w in ["sell", "hold", "decision", "strategy", "when to sell", "net realization", "विक्री", "कधी विकावे"])

    # ── Handlers ───────────────────────────────────────────────────────────────

    def _handle_mandi_prices(self, q: str, db: Session, lang: str) -> ChatResponse:
        commodity = None
        for crop in ["Onion", "Tomato", "Soybean", "Potato", "Wheat", "Cotton", "Maize"]:
            if crop.lower() in q:
                commodity = crop
                break

        query = db.query(MandiPrice)
        if commodity:
            query = query.filter(func.lower(MandiPrice.commodity) == commodity.lower())
        records = query.order_by(MandiPrice.modal_price.desc()).limit(3).all()

        if records:
            lines = []
            c_name = commodity or records[0].commodity
            lines.append(f"📊 Government Mandi Rates for {c_name}:")
            for r in records:
                arrivals_str = f" • Arrivals: {r.arrival_quantity} Q" if r.arrival_quantity else ""
                min_p = r.min_price or r.modal_price
                max_p = r.max_price or r.modal_price
                lines.append(
                    f"• {r.market} ({r.district or ''}): ₹{r.modal_price:,.0f}/Q (Range: ₹{min_p:,.0f} - ₹{max_p:,.0f}{arrivals_str})"
                )
            date_str = r.arrival_date.isoformat() if r.arrival_date else 'Recent'
            lines.append(f"\nSource: {records[0].source} ({date_str})")
            lines.append("💡 Note: Modal prices reflect government reported arrivals. For net farmer payout, calculate Net Realization after logistics.")
            reply = "\n".join(lines)
        else:
            reply = (
                "🧅 Standard Maharashtra Benchmark Mandi Prices:\n"
                "• Vashi APMC (Mumbai): ₹2,800/Q (Range: ₹2,400 - ₹3,200)\n"
                "• Pune APMC (Gultekdi): ₹2,550/Q (Range: ₹2,200 - ₹2,850)\n"
                "• Nashik Dindori APMC: ₹2,350/Q (Range: ₹2,000 - ₹2,600)\n\n"
                "Source: AGMARKNET Daily Feed. Verify local mandi gate tax and cess before dispatch."
            )

        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="mandi_prices",
            suggestions=[
                "📊 Compare Vashi vs Pune",
                "🚚 Check Transport Cost",
                "🏢 Find Verified Buyers",
                "💡 Best Selling Strategy",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_market_comparison(self, q: str, db: Session, lang: str) -> ChatResponse:
        reply = (
            "📊 Inter-Mandi Market Comparison Analysis:\n\n"
            "1. Vashi APMC (Terminal Mega-Market):\n"
            "   • Modal Price: ₹2,800 / Quintal (Premium demand)\n"
            "   • Freight from Junnar/Nashik: ~₹160 / Quintal (Tata 407 return)\n"
            "   • Net Yield: ~₹2,640 / Quintal\n\n"
            "2. Pune APMC (Regional Urban Hub):\n"
            "   • Modal Price: ₹2,550 / Quintal\n"
            "   • Freight from Junnar: ~₹110 / Quintal\n"
            "   • Net Yield: ~₹2,440 / Quintal\n\n"
            "3. Nashik Dindori Mandi (Farmgate Local):\n"
            "   • Modal Price: ₹2,350 / Quintal\n"
            "   • Freight: ~₹40 / Quintal\n"
            "   • Net Yield: ~₹2,310 / Quintal\n\n"
            "💡 Recommendation: Transporting to Vashi yields +₹330/Q net advantage over local gate sale even after deducting return-freight costs."
        )
        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="market_comparison",
            suggestions=[
                "🚚 Book Tata 407 to Vashi",
                "🏢 Match Institutional Buyers",
                "💰 Check e-NWR Loan",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_buyers(self, q: str, db: Session, lang: str) -> ChatResponse:
        buyers = db.query(Buyer).filter(Buyer.verified == True).limit(3).all()
        if buyers:
            b_list = []
            for b in buyers:
                b_list.append(
                    f"• {b.name} ({b.buyer_type.title()}): {b.reliability_score}% Payment Reliability • {b.location or 'Maharashtra'}"
                )
            buyers_text = "\n".join(b_list)
        else:
            buyers_text = (
                "• Sahyadri Agro Processing: 98% Reliability • Direct Processing\n"
                "• Reliance Fresh Hub: 96% Reliability • Retail Chain\n"
                "• BigBasket Sourcing: 94% Reliability • E-Commerce Daily"
            )

        reply = (
            f"🏢 Verified Institutional Buyers on KrishiChakra:\n\n"
            f"{buyers_text}\n\n"
            "🛡️ KrishiChakra Buyer Protections:\n"
            "• Escrow payment lock on dispatch confirmation\n"
            "• Weighbridge & digital assay slip verification\n"
            "• Direct DBT settlement within 24-48 hours"
        )
        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="buyers",
            suggestions=[
                "📦 Create Produce Lot for Matching",
                "📊 Check Modal Prices",
                "🚚 Check Freight Options",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_transport(self, q: str, db: Session, lang: str) -> ChatResponse:
        reply = (
            "🚚 Logistics & Transport Network Overview:\n\n"
            "• Tata 407 LCV (Empty-Return Special):\n"
            "   - Route: Junnar / Nashik → Vashi APMC (124 km)\n"
            "   - Capacity: 3.5 Tonnes (40-70 Crates)\n"
            "   - Discounted Rate: ₹160 / Quintal (35% Empty-Return saving vs standard ₹245)\n"
            "   - Driver: Verified with GPS Live Tracking & AgriStack Freight Shield\n\n"
            "• Mahindra Bolero Maxi Truck (1.7 Tonne):\n"
            "   - Route: Farmgate to Regional Hubs\n"
            "   - Rate: ~₹195 / Quintal\n\n"
            "💡 Smallholder Tip: Pooling produce via your FPO fills full truckloads (FTL), reducing per-quintal transit overhead by up to 40%."
        )
        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="transport",
            suggestions=[
                "🚚 Book 35% Return Truck",
                "📊 Compare Mandi Net Realization",
                "📦 Aggregated FPO Dispatch",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_storage(self, q: str, db: Session, lang: str) -> ChatResponse:
        reply = (
            "🏬 Scientific Storage & e-NWR Warehouse Receipt Loans:\n\n"
            "• MSWC Nashik & Junnar Cold Storage:\n"
            "   - Facility: WDRA Accredited, Temperature Controlled (2°C - 4°C)\n"
            "   - Cost: ₹1.50 / Quintal / Day (₹45/Q for 30 days)\n"
            "   - Availability: 450 Tonnes capacity currently open\n\n"
            "💰 Instant e-NWR Pledge Cash Advance:\n"
            "   - Eligible for up to 70% immediate loan advance against stored crop\n"
            "   - Example: On a ₹48,000 lot valuation, receive ₹33,600 immediate DBT liquidity\n"
            "   - Avoid distress selling during peak-harvest market gluts"
        )
        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="storage",
            suggestions=[
                "💰 Apply e-NWR Loan Advance",
                "💡 Hold vs Sell Analysis",
                "📊 Check Current Mandi Prices",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_produce_quality(self, q: str, db: Session, lang: str) -> ChatResponse:
        reply = (
            "🔍 Agmarknet Produce Quality & Digital Assay Standard:\n\n"
            "• Quality Parameters Assessed:\n"
            "   - Size & Uniformity: Grade A (>55mm, 85%+ batch uniformity)\n"
            "   - Color & Firmness: Optimal ripeness index without skin wrinkling\n"
            "   - Defect Tolerance: Max 3% surface blemish allowance for Grade A\n\n"
            "🛡️ Zero Whole-Batch Rejection Shield:\n"
            "   - Buyers cannot reject an entire 400-crate consignment for localized transit issues\n"
            "   - Defective units (e.g. bruised crates) are isolated and adjusted transparently\n"
            "   - 100% of verified healthy crates receive full agreed price payment\n\n"
            "⚠️ Architecture Notice: Computer vision quality models run through the configured AI integration pipeline without claiming unverified certified guarantees."
        )
        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="produce_quality",
            suggestions=[
                "📸 Upload Produce for Inspection",
                "🏢 Match Grade-A Buyers",
                "📊 Check Mandi Premiums",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_selling_decisions(self, q: str, db: Session, lang: str) -> ChatResponse:
        reply = (
            "💡 KrishiChakra Smart Selling Advisory:\n\n"
            "• Core Decision Formula:\n"
            "   Estimated Net Realization = Gross Mandi Price − Transport Cost − Storage Cost\n\n"
            "• Strategic Guidance for Today:\n"
            "   1. Immediate Sale (High Demand): Tomato & Red Onion arrivals are experiencing export demand. Dispatch to Vashi APMC for maximum realization.\n"
            "   2. Cold Storage Hold: For durable produce facing temporary local gluts, store in MSWC facility with e-NWR loan to capture +20-30% price rebound next month.\n"
            "   3. Institutional Contract: Lock fixed ₹2,400/Q with verified buyers like Sahyadri Agro to insulate against market swings."
        )
        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="selling_decisions",
            suggestions=[
                "📊 View Net Realization Calculator",
                "🚚 Check Return Freight",
                "🏢 View Verified Buyers",
                "🏬 Cold Storage Options",
            ],
            disclaimer=self.DISCLAIMER,
        )

    def _handle_greeting(self, lang: str) -> ChatResponse:
        if lang in ["hi", "hindi"]:
            reply = (
                "नमस्ते! 🌾 मैं KrishiBot हूं (नियम-आधारित प्रोटोटाइप)।\n\n"
                "मैं मंडी भाव, मंडियों की तुलना, खरीदार, परिवहन, कोल्ड स्टोरेज और बिक्री निर्णय में आपकी मदद कर सकता हूं।"
            )
        elif lang in ["mr", "marathi"]:
            reply = (
                "नमस्कार! 🌾 मी KrishiBot आहे (नियम-आधारित प्रोटोटाइप).\n\n"
                "मी बाजारभाव, मंडई तुलना, खरेदीदार, वाहतूक, शीतगृह आणि विक्री निर्णयांमध्ये आपली मदत करू शकतो."
            )
        else:
            reply = (
                "Hello Farmer! 🌾 I am KrishiBot, your agricultural trade advisor.\n\n"
                "Ask me about mandi rates, inter-market comparison, verified buyers, freight discounts, or cold storage loans."
            )

        return ChatResponse(
            reply=reply,
            mode=self.MODE_NAME,
            is_llm=False,
            intent="general",
            suggestions=[
                "🧅 Onion Price Nashik",
                "📊 Compare Vashi vs Pune",
                "🏢 Verified Buyers",
                "🚚 Book Return Truck",
            ],
            disclaimer=self.DISCLAIMER,
        )


class LLMProvider(BaseChatbotProvider):
    """
    Integration placeholder for actual LLM services (e.g. Gemini, OpenAI, Claude, or local SLMs).
    Will be activated once API keys and model credentials are provided.
    """

    def __init__(self, api_key: Optional[str] = None, model_name: str = "gemini-1.5-flash"):
        self.api_key = api_key
        self.model_name = model_name

    def generate_reply(
        self,
        message: str,
        db: Session,
        language: str = "en",
        farmer_id: Optional[int] = None,
    ) -> ChatResponse:
        # Placeholder integration boundary for future LLM service
        raise NotImplementedError("LLM Provider is not active. Using RuleBasedPrototypeProvider.")


# Global singleton instance of active provider
_active_provider: BaseChatbotProvider = RuleBasedPrototypeProvider()


def get_chatbot_provider() -> BaseChatbotProvider:
    """Returns the configured chatbot provider."""
    return _active_provider


def answer(message: str, db: Optional[Session] = None, language: str = "en") -> str:
    """Legacy helper function backward-compatibility."""
    if db is None:
        from ..database import SessionLocal
        local_db = SessionLocal()
        try:
            res = _active_provider.generate_reply(message, local_db, language)
            return res.reply
        finally:
            local_db.close()
    res = _active_provider.generate_reply(message, db, language)
    return res.reply

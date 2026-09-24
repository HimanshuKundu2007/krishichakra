from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db
from ..schemas import ChatRequest, ChatResponse
from ..services.chatbot_service import get_chatbot_provider

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])


@router.post("/chat", response_model=ChatResponse)
def chat(data: ChatRequest, db: Session = Depends(get_db)):
    provider = get_chatbot_provider()
    return provider.generate_reply(
        message=data.message,
        db=db,
        language=data.language or "en",
        farmer_id=data.farmer_id,
    )

from uuid import UUID

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status, HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy import and_, desc, or_
from sqlalchemy.orm import Session

from app.core.dependencies import manager
from app.core.security import get_current_user
from app.core.database import get_db
from app.models import Message
from app.models.user import User

router = APIRouter(prefix="/messaging")


messages_router = APIRouter(prefix="/messages", tags=["messages"])


class SendMessageRequest(BaseModel):
    receiver_id: UUID
    content: str


def _serialize_message(message: Message) -> dict:
    return {
        "id": str(message.id),
        "sender_id": str(message.sender_id),
        "receiver_id": str(message.receiver_id),
        "content": message.content,
        "sent_at": message.sent_at.isoformat() if message.sent_at else None,
    }


@messages_router.get("/threads")
def list_threads(
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user_id = current_user.id

    messages = (
        session.query(Message)
        .filter(or_(Message.sender_id == user_id, Message.receiver_id == user_id))
        .order_by(desc(Message.sent_at))
        .all()
    )

    threads: dict[str, dict] = {}
    for message in messages:
        partner_id = (
            message.receiver_id if message.sender_id == user_id else message.sender_id
        )
        partner_key = str(partner_id)
        if partner_key in threads:
            continue

        partner = session.query(User).filter(User.id == partner_id).first()
        threads[partner_key] = {
            "participant_id": partner_key,
            "participant_name": partner.full_name if partner else "Community member",
            "last_message": message.content,
            "last_sent_at": message.sent_at.isoformat() if message.sent_at else None,
            "unread_count": 0,
        }

    return list(threads.values())


@messages_router.get("/threads/{participant_id}")
def get_thread_messages(
    participant_id: UUID,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user_id = current_user.id

    messages = (
        session.query(Message)
        .filter(
            or_(
                and_(Message.sender_id == user_id, Message.receiver_id == participant_id),
                and_(Message.sender_id == participant_id, Message.receiver_id == user_id),
            )
        )
        .order_by(Message.sent_at.asc())
        .all()
    )

    return [_serialize_message(m) for m in messages]


@messages_router.post("")
async def send_message(
    payload: SendMessageRequest,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    new_message = Message(
        sender_id=current_user.id,
        receiver_id=payload.receiver_id,
        content=payload.content,
    )
    session.add(new_message)
    session.commit()
    session.refresh(new_message)

    outgoing = _serialize_message(new_message)

    try:
        await manager.send_personal_message(
            message=outgoing,
            receiver_id=payload.receiver_id,
        )
    except Exception:
        pass

    return outgoing


@router.websocket("/ws")
async def messaging_endpoint(
        websocket: WebSocket,
        token: str = Query(...),
        session: Session = Depends(get_db)
):
    try:
        credentials = HTTPAuthorizationCredentials(
            scheme= "Bearer",
            credentials= token
        )

        current_user = get_current_user(
            credentials= credentials,
            session= session
        )

    except HTTPException:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await manager.connect(current_user.id, websocket)

    try:
        while True:
            data = await websocket.receive_json()

            receiver_id_str = data.get("receiver_id")
            content = data.get("content")

            if not receiver_id_str or not content:
                continue

            receiver_id = UUID(receiver_id_str)

            new_message = Message(
                sender_id=current_user.id,
                receiver_id=receiver_id,
                content=content
            )

            session.add(new_message)
            session.commit()
            session.refresh(new_message)

            outgoing_payload = {
                "id": str(new_message.id),
                "sender_id": str(new_message.sender_id),
                "content": new_message.content,
                "sent_at": new_message.sent_at.isoformat() if new_message.sent_at else None
            }

            await manager.send_personal_message(
                message= outgoing_payload,
                receiver_id= receiver_id
            )

    except WebSocketDisconnect:
        manager.disconnect(current_user.id)
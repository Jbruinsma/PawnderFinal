from uuid import UUID

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status, HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.dependencies import manager
from app.core.security import get_current_user
from app.database import get_db
from app.models import Message

router = APIRouter(prefix="/messaging")


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
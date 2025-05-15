import asyncio
import json

import websockets
from google.auth import default
from google.auth.transport.requests import Request
from websockets.legacy.protocol import WebSocketCommonProtocol
from websockets.legacy.server import WebSocketServerProtocol

HOST = "us-central1-aiplatform.googleapis.com"
SERVICE_URL = f"wss://{HOST}/ws/google.cloud.aiplatform.v1beta1.LlmBidiService/BidiGenerateContent"

DEBUG = False


async def proxy_task(
    client_websocket: WebSocketCommonProtocol, server_websocket: WebSocketCommonProtocol
) -> None:
    """
    Forwards messages from one WebSocket connection to another.

    Args:
        client_websocket: The WebSocket connection from which to receive messages.
        server_websocket: The WebSocket connection to which to send messages.
    """
    # client_websocket 에서 메시지 수신 
    async for message in client_websocket:
        try:
            data = json.loads(message)
            if DEBUG:
                print("proxying: ", data)
            await server_websocket.send(json.dumps(data))
        except Exception as e:
            print(f"Error processing message: {e}")

    await server_websocket.close()

#
async def get_access_token():
    credentials, _ = default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    credentials.refresh(Request())
    return credentials.token

# client_ws ↔ server_ws 로 양방향 메시지 전달 
async def create_proxy(
    client_websocket: WebSocketCommonProtocol, bearer_token: str
) -> None:
    """
    Establishes a WebSocket connection to the server and creates two tasks for
    bidirectional message forwarding between the client and the server.

    Args:
        client_websocket: The WebSocket connection of the client.
        bearer_token: The bearer token for authentication with the server.
    """

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {bearer_token}",
    }

    # Google Gemini API WebSocket에 연결 
    async with websockets.connect(
        SERVICE_URL, additional_headers=headers
    ) as server_websocket:
        client_to_server_task = asyncio.create_task(
            proxy_task(client_websocket, server_websocket)
        )
        # server_websocket 에서 메시지 수신 
        server_to_client_task = asyncio.create_task(
            proxy_task(server_websocket, client_websocket)
        )
        await asyncio.gather(client_to_server_task, server_to_client_task)


# 새로운 클라이언트 연결 처리 
async def handle_client(client_websocket: WebSocketServerProtocol) -> None:
    """
    Handles a new client connection. Instead of expecting a bearer token from the client,
    it retrieves a GCP access token from the metadata server or environment.
    """
    print("New connection...")

    try:
        # 🔐 GCP 서비스 계정 기반 액세스 토큰 자동 획득
        bearer_token = await get_access_token()
        print("Access token successfully retrieved.")
    except Exception as e:
        print(f"❌ Failed to get access token: {e}")
        await client_websocket.close(code=1011, reason="Token fetch failed")
        return

    # 🔁 client ↔ Gemini API 연결 프록시 생성
    await create_proxy(client_websocket, bearer_token)

# websockets.serve()를 통해 8080 포트에서 WebSocket 서버 시작
async def main() -> None:
    """
    Starts the WebSocket server and listens for incoming client connections.
    """
    async with websockets.serve(handle_client, "0.0.0.0", 8000):
        print("Running websocket server 0.0.0.0:8000...")
        await asyncio.Future()


# Entry point
if __name__ == "__main__":
    asyncio.run(main())

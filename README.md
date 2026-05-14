# MobileRelay

A self-hosted Android SMS Gateway API server with **dual-mode operation**:
- **Local Hotspot Mode**: Runs an HTTP server directly on your Android phone
- **Remote Server Mode**: Connects to your Node.js server via WebSocket (ngrok)

Send SMS messages through your SIM card via a simple REST API from any external app (Postman, Laravel, React, etc.).

---

## Features

- Two operation modes: Local HTTP server or Remote WebSocket client
- Easy mode switching via Settings screen
- Real-time SMS delivery via WebSocket events
- Secure API key authentication
- Request logging and statistics
- Modern dark-themed UI
- Auto-reconnection in remote mode

---

## Quick Start

### Prerequisites

- Flutter 3.x stable
- Android device (API 21 / Android 5.0+) with a SIM card and an active SMS plan
- For local mode: Phone and development machine on the **same Wi-Fi network**
- For remote mode: Node.js server with WebSocket support (ngrok URL)

### 1. Configure Remote Server (Optional)

If you want to use Remote Server Mode, edit `.env` file:

```env
REMOTE_SERVER_URL=ws://your-ngrok-url.ngrok.io
```

### 2. Configure API Key

Edit `.env` file and set your API key:

```env
API_KEY=your-secure-api-key-here
```

This key will be used for authentication in both local and remote modes.

### 3. Install & run

```bash
flutter pub get
flutter run                    # debug build connected to device
```

### 4. Build a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Transfer the APK to your device and install it (enable "Install from unknown sources" in settings if needed).

---

## Operation Modes

### Local Hotspot Mode

The phone runs an HTTP server that listens on port 8080. Other devices on the same network can send POST requests to send SMS.

**Use cases:**
- Testing and development
- Local network operations
- No internet required
- Direct device-to-device communication

### Remote Server Mode

The phone connects to your Node.js server via WebSocket and listens for SMS send events.

**Use cases:**
- Production deployments
- Access from anywhere via ngrok
- Integration with existing backend
- Centralized logging and management

---

## Switching Modes

1. Tap the **Settings** icon in the app's top bar
2. Select your preferred mode (Local Hotspot or Remote Server)
3. Tap **Save Settings**
4. Start the server from the home screen

---

## How to find your phone's local IP

The app displays the IP automatically after you tap **Start Server**. You can also find it manually:

- **Android**: Settings → Wi-Fi → tap the connected network → IP address
- **ADB**: `adb shell ip addr show wlan0`

### Network Requirements

The app works in the following scenarios:

- ✅ **WiFi Network**: Phone and client device on the same WiFi network
- ✅ **Hotspot Mode**: Phone creates hotspot, client connects to it
- ✅ **WiFi + Mobile Data**: Automatically prioritizes WiFi interface
- ❌ **Mobile Data Only**: Won't work (carrier NAT prevents external access)

### Troubleshooting Network Issues

If you can't connect to the server:

1. **Ensure Same Network**: Client device must be on the same WiFi/hotspot as the phone
2. **Check Firewall**: Some Android ROMs have built-in firewalls that block incoming connections
3. **Disable AP Isolation**: Some routers have "AP Isolation" or "Client Isolation" enabled, preventing devices from communicating
4. **Check Port**: Ensure port 8080 is not blocked by your router
5. **Use Hotspot**: If WiFi fails, use phone's hotspot mode (always works)
6. **Verify Permissions**: Ensure WiFi state permissions are granted to the app

---

## API Reference

### Local Hotspot Mode

**Base URL**: `http://<PHONE_IP>:8080`

#### `POST /api/sms/send`

**Required header**:
```
x-api-key: YOUR_API_KEY_FROM_ENV
```

**Request body**:
```json
{
  "phone": "9876543210",
  "message": "Hello from MobileRelay"
}
```

**Success response** (`200`):
```json
{
  "success": true,
  "id": "9ef22f04-55c7-4c71-9967-2040bda9005c",
  "status": "delivered",
  "duration": 170,
  "timestamp": "2026-05-14T10:17:07.396Z"
}
```

**Error responses**:

| Status | Cause |
|--------|-------|
| `400` | Missing or malformed `phone`/`message` fields, or invalid JSON |
| `401` | `x-api-key` header missing or incorrect |
| `404` | Path is not `/api/sms/send` or method is not `POST` |
| `500` | SMS failed to send (check device SMS permission) |

---

### Remote Server Mode

The phone connects to your Node.js server via WebSocket and listens for events.

#### WebSocket Authentication

On connection, the phone sends:
```json
{
  "type": "auth",
  "api_key": "YOUR_API_KEY_FROM_ENV",
  "device_id": "flutter-mobile-relay"
}
```

Server responds:
```json
{
  "type": "auth_result",
  "success": true
}
```

#### SMS Send Event (Server → Phone)

Your Node.js server sends:
```json
{
  "type": "send_sms",
  "id": "unique-request-id",
  "phone": "9876543210",
  "message": "Hello from remote server"
}
```

#### SMS Result Event (Phone → Server)

Phone responds with delivery status:
```json
{
  "type": "sms_result",
  "id": "unique-request-id",
  "success": true,
  "error": null,
  "timestamp": "2026-05-14T09:00:00Z"
}
```

---

## Example Usage (Local Mode)

### curl

### curl

```bash
curl -X POST http://192.168.1.42:8080/api/sms/send \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"phone":"9876543210","message":"Hello!"}'
```

### Laravel

```php
Http::withHeaders([
    'x-api-key' => 'YOUR_API_KEY',
])->post('http://192.168.1.42:8080/api/sms/send', [
    'phone'   => '9876543210',
    'message' => 'Hello from Laravel',
]);
```

### JavaScript / fetch

```js
await fetch('http://192.168.1.42:8080/api/sms/send', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-api-key': 'YOUR_API_KEY',
  },
  body: JSON.stringify({ phone: '9876543210', message: 'Hello!' }),
});
```

### Postman

1. Create a new request → `POST`
2. URL: `http://192.168.x.x:8080/api/sms/send` *(replace with your phone's IP)*
3. **Headers** tab:
   - Key: `x-api-key`  Value: `YOUR_API_KEY`
   - Key: `Content-Type`  Value: `application/json`
4. **Body** tab → raw → JSON:
   ```json
   {
     "phone": "9876543210",
     "message": "Test SMS from Postman"
   }
   ```
5. Send → you should receive:
   ```json
   {
     "success": true,
     "id": "...",
     "status": "delivered",
     "duration": 170,
     "timestamp": "2026-05-14T10:17:07.396Z"
   }
   ```

---

## Node.js Server Example (Remote Mode)

Create a WebSocket server to send SMS via the phone:

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws) => {
  console.log('Phone connected');

  ws.on('message', (data) => {
    const msg = JSON.parse(data);
    
    if (msg.type === 'auth') {
      // Verify API key
      if (msg.api_key === 'YOUR_API_KEY') {
        ws.send(JSON.stringify({ type: 'auth_result', success: true }));
      } else {
        ws.send(JSON.stringify({ type: 'auth_result', success: false }));
        ws.close();
      }
    }
    
    if (msg.type === 'sms_result') {
      console.log('SMS delivery result:', msg);
    }
  });

  // Send SMS request to phone
  setTimeout(() => {
    ws.send(JSON.stringify({
      type: 'send_sms',
      id: 'req-123',
      phone: '9876543210',
      message: 'Hello from Node.js!'
    }));
  }, 2000);
});
```

---

## Project Structure

```
lib/
├── main.dart                  # App entry, splash screen, theme, .env loader
├── constants/
│   └── app_constants.dart     # API key, port, channel name
├── models/
│   ├── app_settings.dart      # Settings model with ServerMode enum
│   ├── request_log.dart       # Log entry model
│   ├── sms_request.dart       # Parsed + validated SMS request
│   └── api_response.dart      # JSON response helper
├── services/
│   ├── server_service.dart    # dart:io HttpServer — routing, auth, logging
│   ├── websocket_service.dart # WebSocket client for remote mode
│   ├── sms_service.dart       # Platform channel → Android SmsManager
│   └── network_service.dart   # Resolves local Wi-Fi IP
├── providers/
│   └── app_provider.dart      # ChangeNotifier — all app state, dual-mode logic
├── widgets/
│   ├── status_card.dart       # Animated running/stopped indicator + mode badge
│   ├── api_info_card.dart     # IP, port, endpoint, copy-URL button (mode-aware)
│   ├── stats_card.dart        # SMS sent / total / error counters
│   ├── log_item_widget.dart   # Individual request log row
│   └── server_controls.dart   # Start / Stop buttons
├── screens/
│   ├── home_screen.dart       # Main dashboard
│   ├── settings_screen.dart   # Mode selection and configuration
│   └── logs_screen.dart       # Full request log list
└── utils/
    └── network_utils.dart     # dart:io NetworkInterface IP lookup + network_info_plus
android/app/src/main/kotlin/…/
└── MainActivity.kt            # MethodChannel → SmsManager bridge
.env                           # Remote server WebSocket URL
```

---

## SMS Permission Notes

Android requires `SEND_SMS` permission at **runtime** on API 23+. MobileRelay requests it automatically when you tap **Start Server** for the first time.

On **Android 10+** and some manufacturers' ROMs, programmatic SMS sending from non-default-SMS apps may be silently blocked even with the permission granted. If SMS is not delivered:

1. Set MobileRelay as the **default SMS app** temporarily (Settings → Apps → Default apps → SMS).
2. Alternatively, install on a device running **Android 9 or earlier** for unrestricted access.

---

## Production Recommendations

| Topic | Recommendation |
|-------|---------------|
| API Key | Use a long random string (≥32 chars). Store it outside the APK (shared prefs / remote config). |
| Network | Assign a static DHCP lease to the phone so the IP never changes. |
| Availability | Enable "Keep screen on" or use a wake lock so the server survives overnight. |
| Background | The HTTP server runs on Flutter's main isolate; keep the app in the foreground or add a `flutter_foreground_task` foreground service for uninterrupted operation. |
| HTTPS | Add a reverse proxy (e.g. nginx) with a self-signed cert on the same network for encrypted traffic. |
| Rate limiting | Add an in-memory request counter per minute in `ServerService` to prevent abuse. |
| Logs | Rotate / persist logs to SQLite (`sqflite`) for durable history across restarts. |

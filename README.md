# 📞 Flutter Video Call App

A real-time peer-to-peer video calling application built with Flutter and WebRTC. Users can join rooms and have high-quality video calls with multiple participants.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![WebRTC](https://img.shields.io/badge/WebRTC-333333?style=for-the-badge&logo=webrtc&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)
![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=for-the-badge&logo=socketdotio&logoColor=white)

## 📸 Screenshots

| Join Room | Waiting Screen | Video Call |
|-----------|----------------|------------|
| ![Join](https://via.placeholder.com/250x500/4CAF50/FFFFFF?text=Join+Room) | ![Waiting](https://via.placeholder.com/250x500/2196F3/FFFFFF?text=Waiting+Screen) | ![Call](https://via.placeholder.com/250x500/FF9800/FFFFFF?text=Video+Call) |


## ✨ Features

### 📱 Client Features
- **Real-time Video Calling** - High-quality peer-to-peer video communication
- **Audio Control** - Mute/unmute microphone during calls
- **Video Control** - Turn camera on/off during calls
- **Room-based System** - Join specific rooms using room IDs
- **Live User Presence** - See who's currently in the room
- **Responsive UI** - Beautiful Material Design interface
- **Auto Reconnection** - Automatic WebSocket reconnection on network issues
- **Cross Platform** - Works on Android and iOS
- **Permission Handling** - Smooth camera/microphone permission flow

### 🖥️ Server Features
- **WebSocket Signaling** - Real-time message relay between clients
- **Room Management** - Automatic room creation and cleanup
- **User Management** - Handle user join/leave events
- **WebRTC Signaling** - Relay offer/answer/ICE candidates
- **Connection Monitoring** - Track active connections and rooms
- **Error Handling** - Graceful error recovery
- **Health Check** - Built-in health monitoring endpoint
- **Logging** - Comprehensive logging system
- **24/7 Operation** - Production-ready server setup

## 🏗️ Architecture

```
┌─────────────────┐    WebSocket     ┌─────────────────┐    WebSocket     ┌─────────────────┐
│                 │ ◄─────────────── │                 │ ─────────────► │                 │
│   Flutter App   │                 │   Node.js       │                 │   Flutter App   │
│    (Alice)      │                 │   Server        │                 │     (Bob)       │
│                 │ ────────────────► │                 │ ◄────────────── │                 │
└─────────────────┘                 └─────────────────┘                 └─────────────────┘
         ▲                                                                         ▲
         │                          WebRTC P2P Connection                          │
         └─────────────────────────────────────────────────────────────────────────┘
                                   (Direct Video/Audio Stream)
```

### How It Works
1. **Users join rooms** via WebSocket connection to server
2. **Server manages rooms** and relays signaling messages
3. **WebRTC handshake** establishes direct peer-to-peer connection
4. **Video/audio streams** flow directly between devices
5. **Server handles** user presence and connection management

## 📋 Prerequisites

### For Flutter Development
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Android device/emulator or iOS device/simulator
- Camera and microphone permissions

### For Server Deployment
- Node.js (v14 or higher)
- npm or yarn package manager
- Server with public IP address
- Port access (default: 8080)

## 🚀 Quick Start

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/yourusername/flutter-video-call.git
cd flutter-video-call
```

### 2️⃣ Set Up the Server

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Start the server
npm start

# Server will run on http://localhost:8080
```

### 3️⃣ Set Up Flutter App

```bash
# Navigate back to root
cd ..

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### 4️⃣ Configure Connection

Update the WebSocket URL in `lib/main.dart`:

```dart
// Replace with your server URL
channel = IOWebSocketChannel.connect('ws://your-server-ip:8080');
```

## 📂 Project Structure

```
flutter-video-call/
├── lib/
│   └── main.dart                 # Main Flutter application
├── server/
│   ├── server.js                # Node.js WebSocket server
│   ├── package.json             # Server dependencies
│   ├── start.sh                 # Server startup script
│   └── logs/                    # Server logs directory
├── android/                     # Android configuration
├── ios/                         # iOS configuration
├── pubspec.yaml                 # Flutter dependencies
└── README.md                    # This file
```

## 🔧 Installation

### Flutter App Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Update permissions in `android/app/src/main/AndroidManifest.xml`:**
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
   ```

3. **For iOS, update `ios/Runner/Info.plist`:**
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access for video calling</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for video calling</string>
   ```

### Server Setup

1. **Install Node.js dependencies:**
   ```bash
   cd server
   npm install
   ```

2. **Start the server:**
   ```bash
   npm start
   ```

3. **For production deployment:**
   ```bash
   # Install PM2 for process management
   npm install -g pm2
   
   # Start with PM2
   pm2 start server.js --name "video-call-server"
   
   # Save PM2 configuration
   pm2 save
   pm2 startup
   ```

## 🔌 Dependencies

### Flutter Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  web_socket_channel: ^2.4.0      # WebSocket communication
  flutter_webrtc: ^0.9.36         # WebRTC functionality
  cupertino_icons: ^1.0.2         # iOS icons

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0           # Linting rules
```

### Server Dependencies (`package.json`)

```json
{
  "dependencies": {
    "ws": "^8.13.0"                
  }
}
```

## ⚙️ Configuration

### Environment Variables

Create `.env` file in server directory:

```env
PORT=8080
NODE_ENV=production
LOG_LEVEL=info
```

### Server Configuration

Update `server/server.js` configuration:

```javascript
// Server configuration
const PORT = process.env.PORT || 8080;
const HOST = '0.0.0.0';  // Listen on all interfaces

// STUN/TURN servers (add your own for better connectivity)
const iceServers = [
  { urls: 'stun:stun.l.google.com:19302' },
  { urls: 'stun:stun1.l.google.com:19302' },
  // Add TURN servers for better NAT traversal
];
```

### Flutter Configuration

Update connection settings in `lib/main.dart`:

```dart
// WebSocket server URL
const String WEBSOCKET_URL = 'ws://your-domain.com:8080';

// Video constraints
final Map<String, dynamic> mediaConstraints = {
  'audio': true,
  'video': {
    'facingMode': 'user',
    'width': {'min': 640, 'ideal': 1280},
    'height': {'min': 480, 'ideal': 720},
  },
};
```

## 📖 API Documentation

### WebSocket Message Types

#### Client → Server Messages

| Type | Description | Payload |
|------|-------------|---------|
| `join` | User joins a room | `{username, roomId, timestamp}` |
| `leave` | User leaves a room | `{username, roomId, timestamp}` |
| `call-user` | Start a video call | `{username, roomId}` |
| `call-accepted` | Accept incoming call | `{username, roomId}` |
| `offer` | WebRTC offer | `{username, roomId, offer}` |
| `answer` | WebRTC answer | `{username, roomId, answer}` |
| `ice-candidate` | ICE candidate | `{username, roomId, candidate}` |

#### Server → Client Messages

| Type | Description | Payload |
|------|-------------|---------|
| `join` | User joined room | `{username, roomId, timestamp}` |
| `leave` | User left room | `{username, roomId, timestamp}` |
| `call-user` | Incoming call notification | `{username, roomId}` |
| `call-accepted` | Call accepted | `{username, roomId}` |
| `offer` | WebRTC offer | `{username, roomId, offer}` |
| `answer` | WebRTC answer | `{username, roomId, answer}` |
| `ice-candidate` | ICE candidate | `{username, roomId, candidate}` |

### REST Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Server health check |

**Health Check Response:**
```json
{
  "status": "healthy",
  "uptime": 3600,
  "clients": 5,
  "rooms": 2,
  "roomDetails": [
    {"roomId": "room123", "members": 2},
    {"roomId": "room456", "members": 3}
  ],
  "timestamp": "2023-12-01T10:00:00.000Z"
}
```

## 🚀 Deployment

### Development

```bash
# Start server
cd server && npm start

# Start Flutter app (in another terminal)
flutter run
```

### Production

#### Server Deployment

1. **Deploy to your server:**
   ```bash
   # Upload files to server
   scp -r server/ user@your-server.com:/home/user/video-call-server/
   
   # SSH to server
   ssh user@your-server.com
   
   # Install dependencies
   cd /home/user/video-call-server
   npm install --production
   
   # Start with PM2
   pm2 start server.js --name "video-call"
   pm2 save
   pm2 startup
   ```

2. **Configure firewall:**
   ```bash
   # Allow WebSocket port
   sudo ufw allow 8080/tcp
   ```

3. **Set up nginx (optional):**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location /ws {
           proxy_pass http://localhost:8080;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
           proxy_set_header Host $host;
       }
   }
   ```

#### Flutter App Deployment

1. **Build for Android:**
   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Build for iOS:**
   ```bash
   flutter build ios --release
   # Open build/ios/iphoneos/Runner.app in Xcode for signing
   ```

## 🐛 Troubleshooting

### Common Issues

#### Connection Issues

**Problem:** Cannot connect to WebSocket server
```
Solution:
1. Check server is running: netstat -tlnp | grep 8080
2. Verify firewall settings
3. Check WebSocket URL in Flutter app
4. Ensure server IP is accessible from device
```

**Problem:** Video not showing
```
Solution:
1. Grant camera permissions in device settings
2. Check camera is not used by other apps  
3. Verify WebRTC connection establishment
4. Check browser/device WebRTC support
```

#### Permission Issues

**Problem:** Camera/Microphone permissions denied
```
Solution:
1. Manually grant permissions in device settings
2. Uninstall and reinstall app
3. Check permission requests in code
4. Test on different device
```

### Debug Mode

Enable debug logging in Flutter:

```dart
// Add this for detailed WebRTC logs
void main() {
  // Enable WebRTC logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  runApp(MyApp());
}
```

Enable debug logging in server:

```javascript
// Set environment variable
process.env.DEBUG = 'true';

// Or modify logging level
const LOG_LEVEL = process.env.LOG_LEVEL || 'debug';
```

### Performance Optimization

1. **Reduce video quality for slower connections:**
   ```dart
   final constraints = {
     'video': {
       'width': {'max': 640},
       'height': {'max': 480},
       'frameRate': {'max': 15},
     }
   };
   ```

2. **Server optimization:**
   ```javascript
   // Increase server limits
   server.setTimeout(0);
   server.maxHeadersCount = 0;
   ```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/amazing-feature`
3. **Commit your changes:** `git commit -m 'Add amazing feature'`
4. **Push to the branch:** `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines

- Follow Flutter best practices
- Write clean, documented code
- Test on multiple devices
- Update documentation for new features
- Follow semantic versioning

### Code Style

- Use `flutter format` for Dart code formatting
- Use ESLint for JavaScript code formatting
- Write meaningful commit messages
- Add comments for complex logic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2023 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- WebRTC community for peer-to-peer communication
- Contributors and testers
- Open source community



## 🔮 Roadmap

- [ ] **Group Video Calls** - Support for multiple participants
- [ ] **Chat Messages** - Text chat during video calls
- [ ] **Screen Sharing** - Share device screen
- [ ] **Recording** - Record video calls
- [ ] **File Sharing** - Share files during calls
- [ ] **Push Notifications** - Notify users of incoming calls
- [ ] **User Authentication** - Login system
- [ ] **Call History** - Track previous calls
- [ ] **Mobile Responsiveness** - Better tablet support
- [ ] **Desktop Support** - Windows/Mac/Linux desktop apps

## 📊 Statistics

- **Lines of Code:** ~2,000
- **Languages:** Dart, JavaScript
- **Platforms:** Android, iOS
- **Server:** Node.js
- **Database:** None (stateless)
- **Real-time:** WebSocket + WebRTC

## 🔧 System Requirements

### Minimum Requirements
- **Android:** API level 21+ (Android 5.0)
- **iOS:** iOS 10.0+
- **RAM:** 2GB
- **Storage:** 100MB
- **Network:** 3G/WiFi connection

### Recommended Requirements  
- **Android:** API level 28+ (Android 9.0)
- **iOS:** iOS 13.0+
- **RAM:** 4GB+
- **Storage:** 200MB
- **Network:** 4G/WiFi connection

---

<div align="center">

**⭐ Star this repository if it helped you! ⭐**

Made with ❤️ by [Ezz Masre](https://github.com/ezzmasre)

</div>

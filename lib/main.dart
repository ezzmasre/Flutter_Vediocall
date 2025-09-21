import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VideoCallScreen(),
    );
  }
}

class VideoCallScreen extends StatefulWidget {
  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late WebSocketChannel channel;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  // Connection state
  bool isConnected = false;
  String userName = '';
  String roomId = '';
  List<String> roomMembers = [];

  // Video call state
  bool isInCall = false;
  RTCPeerConnection? peerConnection;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;
  bool isVideoOn = true;
  bool isAudioOn = true;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showJoinDialog();
    });
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join Video Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _roomController,
                decoration: InputDecoration(
                  hintText: 'Enter room ID',
                  prefixIcon: Icon(Icons.video_call),
                  helperText: 'Everyone with same room ID will join video call',
                ),
                onSubmitted: (value) => _joinRoom(),
              ),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: _joinRoom, child: Text('Join Room')),
          ],
        );
      },
    );
  }

  void _joinRoom() {
    if (_nameController.text.isNotEmpty && _roomController.text.isNotEmpty) {
      setState(() {
        userName = _nameController.text.trim();
        roomId = _roomController.text.trim();
      });
      Navigator.of(context).pop();
      _connectToWebSocket();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both name and room ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _connectToWebSocket() {
    try {
      print('Connecting to WebSocket...');
      channel = IOWebSocketChannel.connect('ws://192.168.1.9:8080');

      setState(() {
        isConnected = true;
      });

      _sendMessage({
        'type': 'join',
        'username': userName,
        'roomId': roomId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      channel.stream.listen(
        (data) {
          final message = json.decode(data);
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            isConnected = false;
          });
          // Auto-reconnect after short delay
          _reconnectWebSocket();
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            isConnected = false;
          });
          // Auto-reconnect after short delay
          _reconnectWebSocket();
        },
      );

      print('WebSocket connected successfully');
    } catch (e) {
      print('Connection error: $e');
      setState(() {
        isConnected = false;
      });
      _reconnectWebSocket();
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'join':
        if (message['username'] != userName) {
          setState(() {
            if (!roomMembers.contains(message['username'])) {
              roomMembers.add(message['username']);
            }
          });
        }
        break;
      case 'leave':
        setState(() {
          roomMembers.remove(message['username']);
        });
        break;
      case 'offer':
        _handleOffer(message);
        break;
      case 'answer':
        _handleAnswer(message);
        break;
      case 'ice-candidate':
        _handleIceCandidate(message);
        break;
      case 'call-user':
        _handleCallUser(message);
        break;
      case 'call-accepted':
        _handleCallAccepted(message);
        break;
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      channel.sink.add(json.encode(message));
    }
  }

  // Video call functions
  Future<void> _startVideoCall() async {
    try {
      // First, show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Requesting camera permission...'),
                ],
              ),
            ),
      );

      // Request permission and get media
      await _getUserMedia();

      // Close loading dialog
      Navigator.of(context).pop();

      // Create peer connection
      await _createPeerConnection();

      setState(() {
        isInCall = true;
      });

      // Notify others in room about the call
      _sendMessage({
        'type': 'call-user',
        'username': userName,
        'roomId': roomId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video call started! Waiting for others to join...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error starting video call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to start video call. Check camera permissions.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      // Reconnect WebSocket if disconnected
      if (!isConnected) {
        _reconnectWebSocket();
      }
    }
  }

  void _reconnectWebSocket() {
    print('Attempting to reconnect WebSocket...');
    Future.delayed(Duration(seconds: 2), () {
      if (!isConnected) {
        _connectToWebSocket();
      }
    });
  }

  Future<void> _getUserMedia() async {
    try {
      final Map<String, dynamic> constraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'min': 640, 'ideal': 1280},
          'height': {'min': 480, 'ideal': 720},
        },
      };

      print('Requesting user media...');
      MediaStream stream = await navigator.mediaDevices.getUserMedia(
        constraints,
      );

      if (mounted) {
        localRenderer.srcObject = stream;
        localStream = stream;
        print('User media obtained successfully');
      }
    } catch (e) {
      print('Error getting user media: $e');
      throw Exception('Camera/Microphone permission denied or not available');
    }
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
      ],
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {"OfferToReceiveAudio": true, "OfferToReceiveVideo": true},
      "optional": [],
    };

    peerConnection = await createPeerConnection(
      configuration,
      offerSdpConstraints,
    );

    // Add local stream tracks
    if (localStream != null) {
      localStream!.getTracks().forEach((track) async {
        await peerConnection!.addTrack(track, localStream!);
      });
    }

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('ICE Candidate: ${candidate.candidate}');
      _sendMessage({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
        'username': userName,
        'roomId': roomId,
      });
    };

    peerConnection!.onTrack = (RTCTrackEvent event) {
      print('Remote track received: ${event.track.kind}');
      if (event.streams.isNotEmpty && mounted) {
        setState(() {
          remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');
    };

    peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state: $state');
    };
  }

  void _handleCallUser(Map<String, dynamic> message) {
    if (message['username'] != userName) {
      _showIncomingCallDialog(message['username']);
    }
  }

  void _showIncomingCallDialog(String callerName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Incoming Video Call'),
            content: Text('$callerName is calling you'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Decline'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _acceptCall();
                },
                child: Text('Accept'),
              ),
            ],
          ),
    );
  }

  Future<void> _acceptCall() async {
    try {
      await _getUserMedia();
      await _createPeerConnection();
      setState(() {
        isInCall = true;
      });

      _sendMessage({
        'type': 'call-accepted',
        'username': userName,
        'roomId': roomId,
      });

      await _createOffer();
    } catch (e) {
      print('Error accepting call: $e');
    }
  }

  void _handleCallAccepted(Map<String, dynamic> message) async {
    await _createOffer();
  }

  Future<void> _createOffer() async {
    RTCSessionDescription description = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(description);

    _sendMessage({
      'type': 'offer',
      'offer': description.toMap(),
      'username': userName,
      'roomId': roomId,
    });
  }

  void _handleOffer(Map<String, dynamic> message) async {
    if (!isInCall) {
      await _getUserMedia();
      await _createPeerConnection();
      setState(() {
        isInCall = true;
      });
    }

    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(message['offer']['sdp'], message['offer']['type']),
    );

    RTCSessionDescription description = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(description);

    _sendMessage({
      'type': 'answer',
      'answer': description.toMap(),
      'username': userName,
      'roomId': roomId,
    });
  }

  void _handleAnswer(Map<String, dynamic> message) async {
    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(
        message['answer']['sdp'],
        message['answer']['type'],
      ),
    );
  }

  void _handleIceCandidate(Map<String, dynamic> message) async {
    if (peerConnection != null && message['candidate'] != null) {
      RTCIceCandidate candidate = RTCIceCandidate(
        message['candidate']['candidate'],
        message['candidate']['sdpMid'],
        message['candidate']['sdpMLineIndex'],
      );
      await peerConnection!.addCandidate(candidate);
    }
  }

  void _endCall() {
    try {
      // Stop all tracks
      localStream?.getTracks().forEach((track) {
        track.stop();
      });

      // Dispose stream
      localStream?.dispose();
      localStream = null;

      // Close peer connection
      peerConnection?.close();
      peerConnection?.dispose();
      peerConnection = null;

      if (mounted) {
        setState(() {
          isInCall = false;
          localRenderer.srcObject = null;
          remoteRenderer.srcObject = null;
          isVideoOn = true;
          isAudioOn = true;
        });
      }

      print('Call ended successfully');
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  void _toggleVideo() {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      bool videoEnabled = localStream!.getVideoTracks()[0].enabled;
      localStream!.getVideoTracks()[0].enabled = !videoEnabled;
      setState(() {
        isVideoOn = !videoEnabled;
      });
    }
  }

  void _toggleAudio() {
    if (localStream != null && localStream!.getAudioTracks().isNotEmpty) {
      bool audioEnabled = localStream!.getAudioTracks()[0].enabled;
      localStream!.getAudioTracks()[0].enabled = !audioEnabled;
      setState(() {
        isAudioOn = !audioEnabled;
      });
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      _sendMessage({
        'type': 'leave',
        'username': userName,
        'roomId': roomId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      channel.sink.close();
    }

    _endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isInCall) {
      return _buildVideoCallScreen();
    }

    return _buildWaitingScreen();
  }

  Widget _buildVideoCallScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen) or waiting message
          Container(
            width: double.infinity,
            height: double.infinity,
            child:
                remoteRenderer.srcObject != null
                    ? RTCVideoView(remoteRenderer, mirror: false)
                    : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 20),
                            Text(
                              'Waiting for others to join...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Share room "$roomId" with others',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),

          // Local video (small window)
          if (localRenderer.srcObject != null)
            Positioned(
              top: 50,
              right: 20,
              width: 120,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: RTCVideoView(localRenderer, mirror: true),
                ),
              ),
            ),

          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _toggleAudio,
                  backgroundColor: isAudioOn ? Colors.white : Colors.red,
                  child: Icon(
                    isAudioOn ? Icons.mic : Icons.mic_off,
                    color: isAudioOn ? Colors.black : Colors.white,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.call_end, color: Colors.white),
                ),
                FloatingActionButton(
                  onPressed: _toggleVideo,
                  backgroundColor: isVideoOn ? Colors.white : Colors.red,
                  child: Icon(
                    isVideoOn ? Icons.videocam : Icons.videocam_off,
                    color: isVideoOn ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Room info and connection status
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Room: $roomId',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Video Room: $roomId'),
        backgroundColor: isConnected ? Colors.green : Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              userName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Room: $roomId', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            if (roomMembers.isNotEmpty) ...[
              Text('People in room:', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    roomMembers
                        .map((member) => Chip(label: Text(member)))
                        .toList(),
              ),
              SizedBox(height: 30),
            ],

            Container(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: isConnected ? _startVideoCall : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call, size: 30, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Start Video Call',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

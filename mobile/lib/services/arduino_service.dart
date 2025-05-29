import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ArduinoService with ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String _lastMessage = '';
  bool _isConnected = false;
  
  // Getters
  String get lastMessage => _lastMessage;
  bool get isConnected => _isConnected;

  /**
   * Connect to the Arduino WebSocket server.
   * @param url The WebSocket URL to connect to, typically in the format 'ws://<arduino_ip>:<port>'.
   */
  void connect(String url) {
    try {
      _channel = IOWebSocketChannel.connect(url);
      _isConnected = true;
      
      // Listen for messages from the Arduino
      _subscription = _channel!.stream.listen(
        (message) {
          _lastMessage = message.toString();
          notifyListeners(); // Notify listeners about new data
          print('Received from Arduino: $_lastMessage');
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
          print('WebSocket connection closed');
        },
        onError: (error) {
          _isConnected = false;
          notifyListeners();
          print('WebSocket error: $error');
        }
      );
      
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      print('Error connecting to WebSocket: $e');
      notifyListeners();
    }
  }
  
  // Send message to Arduino
  Future<void> sendMessage(String message) async {
      final ip = "http://192.168.1.110";
      final url = message == "on" ? "$ip/led/on" : "$ip/led/off";
      await http.get(Uri.parse(url));
  }
  
  // Disconnect from WebSocket server
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    notifyListeners();
    print('Disconnected from WebSocket server');
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/arduino_service.dart';

class ArduinoPage extends StatefulWidget {
  const ArduinoPage({Key? key}) : super(key: key);

  @override
  State<ArduinoPage> createState() => _ArduinoPageState();
}

class _ArduinoPageState extends State<ArduinoPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late ArduinoService _arduinoService;
  List<String> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    // Default WebSocket URL - change this to your server address
    _urlController.text = 'ws://192.168.1.100:81/ws';
    
    // Initialize the Arduino service
    _arduinoService = Provider.of<ArduinoService>(context, listen: false);
    
    // Listen for changes in the Arduino service
    _arduinoService.addListener(_onArduinoServiceChanged);
  }
  
  void _onArduinoServiceChanged() {
    if (_arduinoService.lastMessage.isNotEmpty && 
        !_receivedMessages.contains(_arduinoService.lastMessage)) {
      setState(() {
        _receivedMessages.add(_arduinoService.lastMessage);
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _arduinoService.removeListener(_onArduinoServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arduino Connection'),
      ),
      body: Consumer<ArduinoService>(
        builder: (context, arduinoService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection status
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: arduinoService.isConnected
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        arduinoService.isConnected
                            ? Icons.check_circle
                            : Icons.error,
                        color: arduinoService.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        arduinoService.isConnected
                            ? 'Connected to Arduino'
                            : 'Not connected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // WebSocket URL input
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'WebSocket URL',
                    hintText: 'ws://192.168.1.100:81/ws',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        arduinoService.isConnected
                            ? Icons.link_off
                            : Icons.link,
                      ),
                      onPressed: () {
                        if (arduinoService.isConnected) {
                          arduinoService.disconnect();
                        } else {
                          arduinoService.connect(_urlController.text);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Message input and send button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Message to Arduino',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: arduinoService.isConnected
                          ? () {
                              if (_messageController.text.isNotEmpty) {
                                arduinoService.sendMessage(_messageController.text);
                                _messageController.clear();
                              }
                            }
                          : null,
                      child: Text('Send'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Received messages
                Text(
                  'Received from Arduino:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _receivedMessages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages received yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _receivedMessages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(_receivedMessages[index]),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 
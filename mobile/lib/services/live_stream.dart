import 'dart:io';

final String host = '';
final int port = 80; //Http default port

/**
 * Create a socket connection
 * Handles multiple connections
 */
Future<Socket> createSocket() async {
  final socket = await Socket.connect(host, port);
  return socket;
}

/**
 * Close a socket connection
 */
Future<void> closeSocket(Socket socket) async {
  socket.destroy();
}
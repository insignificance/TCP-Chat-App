import 'dart:io';

Future<void> main() async {
  print('Testing UDP Socket for Local IP...');
  
  try {
    // Bind to any local address
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    
    // "Connect" to a public DNS server (doesn't send packets, just sets routing)
    // This tells the OS to select the interface that would be used to reach 8.8.8.8
    socket.connect(InternetAddress('8.8.8.8'), 53);
    
    // Check the address of the socket now
    print('UDP Socket address after connect: ${socket.address.address}');
    
    socket.close();
  } catch (e) {
    print('Error: $e');
  }
}

class MockUsers {
  static const List<Map<String, String>> users = [
    {'id': 'u1', 'name': 'Col. Aryan Singh', 'email': 'admin@mil.local', 'role': 'Admin', 'password': 'admin123'},
    {'id': 'u2', 'name': 'Dr. Meera Sharma', 'email': 'analyst@mil.local', 'role': 'Analyst', 'password': 'analyst123'},
    {'id': 'u3', 'name': 'Operator Kabir', 'email': 'monitor@mil.local', 'role': 'Monitor', 'password': 'monitor123'},
  ];
}

class SeedData {
  static const List<Map<String, dynamic>> trafficSeries = [
    {'time': '10:00', 'normal': 240, 'attack': 14, 'total': 254},
    {'time': '10:05', 'normal': 260, 'attack': 11, 'total': 271},
    {'time': '10:10', 'normal': 248, 'attack': 18, 'total': 266},
    {'time': '10:15', 'normal': 285, 'attack': 16, 'total': 301},
    {'time': '10:20', 'normal': 272, 'attack': 22, 'total': 294},
    {'time': '10:25', 'normal': 292, 'attack': 15, 'total': 307},
  ];

  static const List<Map<String, dynamic>> liveTraffic = [
    {'id': 't1', 'source': '10.0.1.12', 'destination': '10.0.3.20', 'protocol': 'TCP', 'packetSize': 450, 'time': '10:25:21', 'status': 'Normal', 'severity': 'Low', 'attackType': 'None'},
    {'id': 't2', 'source': '10.0.2.4', 'destination': '10.0.7.9', 'protocol': 'UDP', 'packetSize': 780, 'time': '10:25:24', 'status': 'Attack', 'severity': 'High', 'attackType': 'DDoS'},
    {'id': 't3', 'source': '172.16.2.11', 'destination': '10.0.3.45', 'protocol': 'ICMP', 'packetSize': 520, 'time': '10:25:27', 'status': 'Normal', 'severity': 'Low', 'attackType': 'None'},
    {'id': 't4', 'source': '10.0.5.17', 'destination': '10.0.8.3', 'protocol': 'TCP', 'packetSize': 910, 'time': '10:25:29', 'status': 'Warning', 'severity': 'Medium', 'attackType': 'Spoofing'},
  ];

  static const List<Map<String, dynamic>> alerts = [
    {'id': 'a1', 'message': 'Unusual UDP flood pattern detected near node 10.0.2.4', 'severity': 'High', 'timestamp': '2026-04-03T10:25:24Z', 'attackType': 'DDoS'},
    {'id': 'a2', 'message': 'Repeated failed key exchange from 10.0.5.17', 'severity': 'Medium', 'timestamp': '2026-04-03T10:22:10Z', 'attackType': 'Spoofing'},
    {'id': 'a3', 'message': 'Packet jitter spike resolved automatically', 'severity': 'Low', 'timestamp': '2026-04-03T10:19:44Z', 'attackType': 'None'},
  ];
}

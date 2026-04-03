import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

// Helper to create a client with timeout
Future<http.Response> _get(Uri url, Map<String, String> headers) {
  return http.get(url, headers: headers).timeout(const Duration(seconds: 10));
}

Future<http.Response> _post(Uri url, Map<String, String> headers, String body) {
  return http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 10));
}

Future<http.Response> _patch(Uri url, Map<String, String> headers, String body) {
  return http.patch(url, headers: headers, body: body).timeout(const Duration(seconds: 10));
}

Future<http.Response> _delete(Uri url, Map<String, String> headers) {
  return http.delete(url, headers: headers).timeout(const Duration(seconds: 10));
}

class ApiService {
  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await _post(
      Uri.parse('$apiBaseUrl/api/users/login'),
      _headers,
      jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> payload) async {
    final response = await _post(
      Uri.parse('$apiBaseUrl/api/users'),
      _headers,
      jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Registration failed');
  }

  // Traffic
  static Future<List<dynamic>> fetchTraffic() async {
    final response = await _get(
      Uri.parse('$apiBaseUrl/api/traffic'),
      _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch traffic');
  }

  static Future<Map<String, dynamic>?> fetchLiveTraffic() async {
    final response = await _get(
      Uri.parse('$apiBaseUrl/api/traffic/live'),
      _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return null;
    }
    throw Exception('Failed to fetch live traffic');
  }

  // Alerts
  static Future<List<dynamic>> fetchAlerts() async {
    final response = await _get(
      Uri.parse('$apiBaseUrl/api/alerts'),
      _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch alerts');
  }

  // Stats
  static Future<Map<String, dynamic>?> fetchStats() async {
    final response = await _get(
      Uri.parse('$apiBaseUrl/api/stats'),
      _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch stats');
  }

  // Simulate
  static Future<Map<String, dynamic>> simulateTraffic(String type) async {
    final response = await _post(
      Uri.parse('$apiBaseUrl/api/simulate'),
      _headers,
      jsonEncode({'type': type}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Simulation failed');
  }

  // Users
  static Future<List<dynamic>> fetchUsers() async {
    final response = await _get(
      Uri.parse('$apiBaseUrl/api/users'),
      _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch users');
  }

  static Future<Map<String, dynamic>> createUserByAdmin(Map<String, dynamic> payload) async {
    final response = await _post(
      Uri.parse('$apiBaseUrl/api/users/admin'),
      _headers,
      jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to create user');
  }

  static Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    final response = await _patch(
      Uri.parse('$apiBaseUrl/api/users/$userId/role'),
      _headers,
      jsonEncode({'role': role}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to update role');
  }

  static Future<void> deleteUser(String userId) async {
    final response = await _delete(
      Uri.parse('$apiBaseUrl/api/users/$userId'),
      _headers,
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to delete user');
    }
  }

  // Audit
  static Future<Map<String, dynamic>?> fetchAuditSummary() async {
    final response = await _get(
      Uri.parse('$apiBaseUrl/api/audit'),
      _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch audit data');
  }
}

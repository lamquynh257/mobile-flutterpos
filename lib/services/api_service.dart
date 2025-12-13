import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your backend URL
  // For Android emulator: http://10.0.2.2:3000
  // For real device on same network: http://YOUR_IP:3000
  // For web/desktop: http://localhost:3000
  static const String baseUrl = 'http://localhost:3000/api';
  
  static String? _token;
  
  // Get stored token
  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }
  
  // Save token
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Clear token (logout)
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // GET request
  static Future<http.Response> get(String endpoint) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: headers);
  }
  
  // POST request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: headers, body: json.encode(body));
  }
  
  // PUT request
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.put(url, headers: headers, body: json.encode(body));
  }
  
  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(url, headers: headers);
  }
  
  // Handle response
  static dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Request failed');
    }
  }
}

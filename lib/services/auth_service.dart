import 'api_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await ApiService.post('/auth/login', {
      'username': username,
      'password': password,
    });
    
    final data = ApiService.handleResponse(response);
    
    // Save token
    if (data['token'] != null) {
      await ApiService.saveToken(data['token']);
    }
    
    return data;
  }
  
  // Logout
  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout', {});
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await ApiService.clearToken();
    }
  }
  
  // Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiService.get('/auth/me');
    return ApiService.handleResponse(response);
  }
  
  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await ApiService.getToken();
    if (token == null) return false;
    
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      await ApiService.clearToken();
      return false;
    }
  }
}

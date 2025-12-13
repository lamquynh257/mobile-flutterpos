import '../models/user.dart';
import 'api_service.dart';

class UserService {
  // Get all users
  static Future<List<User>> getAll() async {
    final response = await ApiService.get('/users');
    final data = ApiService.handleResponse(response);
    
    return (data as List).map((json) => User.fromJson(json)).toList();
  }
  
  // Get user by ID
  static Future<User> getById(int id) async {
    final response = await ApiService.get('/users/$id');
    final data = ApiService.handleResponse(response);
    
    return User.fromJson(data);
  }
  
  // Create user
  static Future<User> create({
    required String username,
    required String password,
    String role = 'STAFF',
  }) async {
    final response = await ApiService.post('/users', {
      'username': username,
      'password': password,
      'role': role,
    });
    
    final data = ApiService.handleResponse(response);
    return User.fromJson(data);
  }
  
  // Update user
  static Future<User> update(int id, {
    String? password,
    String? role,
  }) async {
    final body = <String, dynamic>{};
    if (password != null) body['password'] = password;
    if (role != null) body['role'] = role;
    
    final response = await ApiService.put('/users/$id', body);
    final data = ApiService.handleResponse(response);
    
    return User.fromJson(data);
  }
  
  // Delete user
  static Future<void> delete(int id) async {
    await ApiService.delete('/users/$id');
  }
}

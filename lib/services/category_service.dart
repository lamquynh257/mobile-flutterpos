import '../models/category.dart';
import 'api_service.dart';

class CategoryService {
  // Get all categories
  static Future<List<Category>> getAll() async {
    final response = await ApiService.get('/menu/categories');
    final data = ApiService.handleResponse(response);
    
    return (data as List).map((json) => Category.fromJson(json)).toList();
  }
  
  // Get category by ID
  static Future<Category> getById(int id) async {
    final response = await ApiService.get('/menu/categories/$id');
    final data = ApiService.handleResponse(response);
    
    return Category.fromJson(data);
  }
  
  // Create category
  static Future<Category> create({
    required String name,
    int order = 0,
  }) async {
    final response = await ApiService.post('/menu/categories', {
      'name': name,
      'order': order,
    });
    
    final data = ApiService.handleResponse(response);
    return Category.fromJson(data);
  }
  
  // Update category
  static Future<Category> update(int id, {
    String? name,
    int? order,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (order != null) body['order'] = order;
    
    final response = await ApiService.put('/menu/categories/$id', body);
    final data = ApiService.handleResponse(response);
    
    return Category.fromJson(data);
  }
  
  // Delete category
  static Future<void> delete(int id) async {
    await ApiService.delete('/menu/categories/$id');
  }
}

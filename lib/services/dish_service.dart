import '../models/dish.dart';
import 'api_service.dart';

class DishService {
  // Get all dishes (optionally filter by category)
  static Future<List<Dish>> getAll({int? categoryId}) async {
    final endpoint = categoryId != null 
        ? '/menu/dishes?categoryId=$categoryId' 
        : '/menu/dishes';
    final response = await ApiService.get(endpoint);
    final data = ApiService.handleResponse(response);
    
    return (data as List).map((json) => Dish.fromJson(json)).toList();
  }
  
  // Get dish by ID
  static Future<Dish> getById(int id) async {
    final response = await ApiService.get('/menu/dishes/$id');
    final data = ApiService.handleResponse(response);
    
    return Dish.fromJson(data);
  }
  
  // Create dish
  static Future<Dish> create({
    required int categoryId,
    required String name,
    required double price,
    String? description,
    bool available = true,
  }) async {
    final response = await ApiService.post('/menu/dishes', {
      'categoryId': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'available': available,
    });
    
    final data = ApiService.handleResponse(response);
    return Dish.fromJson(data);
  }
  
  // Update dish
  static Future<Dish> update(int id, {
    String? name,
    double? price,
    String? description,
    bool? available,
    int? categoryId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (price != null) body['price'] = price;
    if (description != null) body['description'] = description;
    if (available != null) body['available'] = available;
    if (categoryId != null) body['categoryId'] = categoryId;
    
    final response = await ApiService.put('/menu/dishes/$id', body);
    final data = ApiService.handleResponse(response);
    
    return Dish.fromJson(data);
  }
  
  // Delete dish
  static Future<void> delete(int id) async {
    await ApiService.delete('/menu/dishes/$id');
  }
}

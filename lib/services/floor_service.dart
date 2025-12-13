import '../models/floor.dart';
import 'api_service.dart';

class FloorService {
  // Get all floors
  static Future<List<Floor>> getAll() async {
    final response = await ApiService.get('/floors');
    final data = ApiService.handleResponse(response);
    
    return (data as List).map((json) => Floor.fromJson(json)).toList();
  }
  
  // Get floor by ID
  static Future<Floor> getById(int id) async {
    final response = await ApiService.get('/floors/$id');
    final data = ApiService.handleResponse(response);
    
    return Floor.fromJson(data);
  }
  
  // Create floor
  static Future<Floor> create(String name, {int order = 0}) async {
    final response = await ApiService.post('/floors', {
      'name': name,
      'order': order,
    });
    
    final data = ApiService.handleResponse(response);
    return Floor.fromJson(data);
  }
  
  // Update floor
  static Future<Floor> update(int id, {String? name, int? order}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (order != null) body['order'] = order;
    
    final response = await ApiService.put('/floors/$id', body);
    final data = ApiService.handleResponse(response);
    
    return Floor.fromJson(data);
  }
  
  // Delete floor
  static Future<void> delete(int id) async {
    await ApiService.delete('/floors/$id');
  }
}

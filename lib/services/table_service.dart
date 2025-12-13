import '../models/table_model.dart';
import 'api_service.dart';

class TableService {
  // Get all tables (optionally filter by floor)
  static Future<List<TableModel>> getAll({int? floorId}) async {
    final endpoint = floorId != null ? '/tables?floorId=$floorId' : '/tables';
    print('🔍 Fetching tables from: $endpoint');
    final response = await ApiService.get(endpoint);
    print('📦 Response status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');
    final data = ApiService.handleResponse(response);
    print('✅ Parsed data: $data');
    
    final List<TableModel> tables = [];
    for (var json in (data as List)) {
      try {
        final table = TableModel.fromJson(json);
        tables.add(table);
      } catch (e, stack) {
        print('❌ Error parsing table: $e');
        print('   JSON: $json');
        print('   Stack: $stack');
        rethrow;
      }
    }
    return tables;
  }
  
  // Get table by ID with full details
  static Future<TableModel> getById(int id) async {
    final response = await ApiService.get('/tables/$id');
    final data = ApiService.handleResponse(response);
    
    return TableModel.fromJson(data);
  }
  
  // Create table
  static Future<TableModel> create({
    required int floorId,
    required String name,
    double x = 0,
    double y = 0,
    double hourlyRate = 0,
  }) async {
    final response = await ApiService.post('/tables', {
      'floorId': floorId,
      'name': name,
      'x': x,
      'y': y,
      'hourlyRate': hourlyRate,
    });
    
    final data = ApiService.handleResponse(response);
    return TableModel.fromJson(data);
  }
  
  // Update table
  static Future<TableModel> update(int id, {
    String? name,
    double? x,
    double? y,
    double? hourlyRate,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (x != null) body['x'] = x;
    if (y != null) body['y'] = y;
    if (hourlyRate != null) body['hourlyRate'] = hourlyRate;
    if (status != null) body['status'] = status;
    
    final response = await ApiService.put('/tables/$id', body);
    final data = ApiService.handleResponse(response);
    
    return TableModel.fromJson(data);
  }
  
  // Delete table
  static Future<void> delete(int id) async {
    await ApiService.delete('/tables/$id');
  }
  
  // Book table (start session)
  static Future<Map<String, dynamic>> book(int id, {DateTime? startTime}) async {
    final response = await ApiService.post(
      '/tables/$id/book',
      {
        'startTime': (startTime ?? DateTime.now()).toIso8601String(), // Send client's local time or selected time
      },
    );
    return ApiService.handleResponse(response);
  }
  
  // Preview checkout (calculate charges WITHOUT ending session)
  static Future<Map<String, dynamic>> previewCheckout(int id) async {
    final response = await ApiService.get('/tables/$id/preview-checkout');
    return ApiService.handleResponse(response);
  }
  
  // Checkout table (end session and calculate charges)
  static Future<Map<String, dynamic>> checkout(int id) async {
    final response = await ApiService.post('/tables/$id/checkout', {});
    return ApiService.handleResponse(response);
  }
}

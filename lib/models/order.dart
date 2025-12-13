import '../models/order.dart';
import '../services/api_service.dart';

class OrderService {
  // Get all orders (optionally filter by table or session)
  static Future<List<Order>> getAll({int? tableId, int? sessionId}) async {
    String endpoint = '/orders';
    final params = <String>[];
    if (tableId != null) params.add('tableId=$tableId');
    if (sessionId != null) params.add('sessionId=$sessionId');
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';
    
    final response = await ApiService.get(endpoint);
    final data = ApiService.handleResponse(response);
    
    return (data as List).map((json) => Order.fromJson(json)).toList();
  }
  
  // Create order
  static Future<Order> create({
    required int tableId,
    int? tableSessionId,
    required List<OrderItem> items,
  }) async {
    final response = await ApiService.post('/orders', {
      'tableId': tableId,
      'tableSessionId': tableSessionId,
      'items': items.map((item) => {
        'dishId': item.dishId,
        'quantity': item.quantity,
        'price': item.price,
      }).toList(),
    });
    
    final data = ApiService.handleResponse(response);
    return Order.fromJson(data);
  }
  
  // Update order status
  static Future<Order> updateStatus(int id, String status) async {
    final response = await ApiService.put('/orders/$id/status', {
      'status': status,
    });
    
    final data = ApiService.handleResponse(response);
    return Order.fromJson(data);
  }
}

class Order {
  final int id;
  final int tableId;
  final int? tableSessionId;
  final String status;
  final double total;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.tableId,
    this.tableSessionId,
    required this.status,
    required this.total,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      tableId: json['tableId'] as int,
      tableSessionId: json['tableSessionId'] as int?,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      items: json['items'] != null
          ? (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList()
          : [],
    );
  }
}

class OrderItem {
  final int dishId;
  final int quantity;
  final double price;
  final String? dishName;

  OrderItem({
    required this.dishId,
    required this.quantity,
    required this.price,
    this.dishName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dishId: json['dishId'] as int,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      dishName: json['dish']?['name'] as String?,
    );
  }
}

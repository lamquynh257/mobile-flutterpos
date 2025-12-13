import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/table_model.dart';
import '../../models/order.dart' as OrderModel;
import '../../provider/src.dart';
import '../../services/api_service.dart';

class ModernOrderScreen extends StatefulWidget {
  final TableModel table;

  const ModernOrderScreen({Key? key, required this.table}) : super(key: key);

  @override
  State<ModernOrderScreen> createState() => _ModernOrderScreenState();
}

class _ModernOrderScreenState extends State<ModernOrderScreen> {
  final Map<int, int> _cart = {}; // dishId -> quantity
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingOrders();
  }

  Future<void> _loadExistingOrders() async {
    setState(() => _isLoading = true);
    try {
      int? sessionId = widget.table.activeSession?.id;
      
      // Debug: Loading orders for table ${widget.table.id}, sessionId: $sessionId
      
      // Only load if table has an active session (endTime is null)
      if (sessionId != null && widget.table.activeSession?.endTime == null) {
        final response = await ApiService.get('/orders?tableSessionId=$sessionId&status=PENDING');
        final data = ApiService.handleResponse(response);
        
        final orders = (data as List).map((json) => OrderModel.Order.fromJson(json)).toList();
        // Debug: Found ${orders.length} pending orders
        
        // Clear cart first
        _cart.clear();
        
        // Populate cart with existing items
        for (var order in orders) {
          // Debug: Order ${order.id}: ${order.items.length} items
          for (var item in order.items) {
            _cart[item.dishId] = (_cart[item.dishId] ?? 0) + item.quantity;
            // Debug: Dish ${item.dishId}: ${item.quantity}x
          }
        }
        // Debug: Cart initialized with ${_cart.length} unique dishes
      } else {
        // Debug: No active session - starting with empty cart
        _cart.clear();
      }
    } catch (e) {
      // Error loading orders: $e
      _cart.clear();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateQuantity(int dishId, int change) {
    setState(() {
      final newQty = (_cart[dishId] ?? 0) + change;
      if (newQty <= 0) {
        _cart.remove(dishId);
      } else {
        _cart[dishId] = newQty;
      }
    });
  }

  double _getTotal(List<Dish> menu) {
    double total = 0;
    _cart.forEach((dishId, quantity) {
      try {
        final dish = menu.firstWhere((d) => d.id == dishId);
        total += dish.price * quantity;
      } catch (e) {
        // Dish not found in menu (might have been deleted)
        print('⚠️ Dish $dishId not found in menu');
      }
    });
    return total;
  }

  Future<void> _submitOrder(List<Dish> menu) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn món')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int? sessionId = widget.table.activeSession?.id;
      
      // Step 1: Create new order with current cart FIRST
      final items = _cart.entries.map((entry) {
        try {
          final dish = menu.firstWhere((d) => d.id == entry.key);
          return {
            'dishId': dish.id,
            'quantity': entry.value,
            'price': dish.price,
          };
        } catch (e) {
          // Debug: Dish ${entry.key} not found in menu, skipping
          return null;
        }
      }).where((item) => item != null).toList();

      // Debug: Creating new order with ${items.length} items
      await ApiService.post('/orders', {
        'tableId': widget.table.id,
        'tableSessionId': sessionId,
        'items': items,
      });

      // Debug: New order created successfully
      
      // Step 2: Only cancel old PENDING orders AFTER new order is created successfully
      if (sessionId != null) {
        // Debug: Cancelling old pending orders for session $sessionId
        final existingResponse = await ApiService.get('/orders?tableSessionId=$sessionId&status=PENDING');
        final existingData = ApiService.handleResponse(existingResponse);
        final existingOrders = (existingData as List).map((json) => OrderModel.Order.fromJson(json)).toList();
        
        // Cancel all PENDING orders except the one we just created
        for (var order in existingOrders) {
          // Skip if this is the order we just created (it will be the newest one)
          if (existingOrders.indexOf(order) < existingOrders.length - 1) {
            await ApiService.put('/orders/${order.id}/status', {'status': 'CANCELLED'});
            // Debug: Cancelled old order ${order.id}
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật món thành công!')),
        );
      }
    } catch (e) {
      // Error submitting order: $e
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}đ';
  }

  @override
  Widget build(BuildContext context) {
    final menuSupplier = context.watch<MenuSupplier>();

    if (menuSupplier.loading || _isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Gọi món - ${widget.table.name}'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final menu = menuSupplier.menu;
    final cartItemCount = _cart.values.fold<int>(0, (sum, qty) => sum + qty);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gọi món - ${widget.table.name}'),
        backgroundColor: Colors.orange,
        actions: [
          if (cartItemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Menu grid
          Expanded(
            flex: 2,
            child: menu.isEmpty
                ? const Center(child: Text('Chưa có món nào'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      final dish = menu[index];
                      final inCart = _cart[dish.id] ?? 0;

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _updateQuantity(dish.id, 1),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        image: DecorationImage(
                                          image: dish.imgProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (inCart > 0)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$inCart',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dish.dish,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(dish.price),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Cart sidebar
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange,
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Giỏ hàng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (cartItemCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$cartItemCount món',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có món nào',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: menu
                              .where((dish) => _cart.containsKey(dish.id))
                              .map((dish) {
                            final quantity = _cart[dish.id]!;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: dish.imgProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dish.dish,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(dish.price),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle),
                                          color: Colors.red,
                                          onPressed: () => _updateQuantity(dish.id, -1),
                                        ),
                                        Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle),
                                          color: Colors.green,
                                          onPressed: () => _updateQuantity(dish.id, 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(_getTotal(menu)),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : () => _submitOrder(menu),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(
                              _isSubmitting ? 'Đang gửi...' : 'Xác nhận gọi món',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

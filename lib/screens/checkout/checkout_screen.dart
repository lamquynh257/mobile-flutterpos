import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../models/table_model.dart';
import '../../services/table_service.dart';

class CheckoutScreen extends StatefulWidget {
  final TableModel table;

  const CheckoutScreen({Key? key, required this.table}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _checkoutData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  Future<void> _loadCheckoutData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final data = await TableService.previewCheckout(widget.table.id);
      print('📦 Checkout data received: ${data.keys}');
      print('📦 Orders in data: ${data['orders']}');
      print('📦 Session orders: ${data['session']?['orders']}');
      if (mounted) {
        setState(() {
          _checkoutData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}đ';
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    try {
      String dateStr = dateTime.toString();
      
      // If it's in format "YYYY-MM-DDTHH:mm:ss" (without timezone), parse as local time
      // Backend now returns this format to avoid timezone conversion issues
      if (dateStr.contains('T') && !dateStr.contains('+') && !dateStr.contains('Z')) {
        // Format: "2025-12-14T01:59:00" - parse as local time components
        final parts = dateStr.split('T');
        if (parts.length == 2) {
          final datePart = parts[0].split('-');
          final timePart = parts[1].split(':');
          if (datePart.length == 3 && timePart.length >= 2) {
            // Parse directly as local time (no timezone conversion)
            final year = int.parse(datePart[0]);
            final month = int.parse(datePart[1]);
            final day = int.parse(datePart[2]);
            final hour = int.parse(timePart[0]);
            final minute = int.parse(timePart[1]);
            
            return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
      }
      
      // Fallback: parse as ISO string (may have timezone)
      final dt = DateTime.parse(dateStr);
      // Use local time components to avoid timezone conversion
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _formatDuration(double totalHours) {
    final seconds = (totalHours * 3600).round();
    final duration = Duration(seconds: seconds);
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _completePayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: const Text('Bạn có chắc muốn hoàn tất thanh toán?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TableService.checkout(widget.table.id);
        
        // Ask if user wants to print receipt
        if (mounted) {
          final shouldPrint = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('In hóa đơn'),
              content: const Text('Bạn có muốn in hóa đơn không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Không'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('In'),
                ),
              ],
            ),
          );

          if (shouldPrint == true) {
            await _printReceipt();
          }

          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi thanh toán: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _printReceipt() async {
    try {
      if (_checkoutData == null) return;

      final session = _checkoutData!['session'] as Map<String, dynamic>?;
      final table = _checkoutData!['table'] as Map<String, dynamic>?;
      // Fix: Get orders from session if not at root
      final orders = (_checkoutData!['orders'] ?? session?['orders']) as List?;
      
      if (session == null || table == null) return;

      final printer = BlueThermalPrinter.instance;
      
      // Check for bonded devices
      List<BluetoothDevice>? bondedDevices;
      try {
        bondedDevices = await printer.getBondedDevices();
        if (bondedDevices == null || bondedDevices.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy thiết bị Bluetooth!')),
            );
          }
          return;
        }
      } on PlatformException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi Bluetooth: ${e.message}')),
          );
        }
        return;
      }

      // Connect
      final isConnected = await printer.isConnected;
      if (isConnected != null && !isConnected) {
        try {
          await printer.connect(bondedDevices[0]);
        } on PlatformException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể kết nối: ${e.message}')),
            );
          }
          return;
        }
      }

      // Prepare data
      final totalHours = (session['totalHours'] ?? 0.0) as num;
      final hourlyRate = (table['hourlyRate'] ?? 0.0) as num;
      final hourlyCharge = (_checkoutData!['hourlyCharge'] ?? 0.0) as num;
      final orderTotal = (_checkoutData!['orderTotal'] ?? 0.0) as num;
      final grandTotal = (_checkoutData!['grandTotal'] ?? 0.0) as num;

      // Print Header
      await printer.printCustom('HOA DON', 3, 1); // Remove accents
      await printer.printCustom(_formatDateTime(session['startTime']), 0, 1);
      await printer.printCustom('================================', 1, 1);
      
      // Print Table & Hours
      await printer.printLeftRight('Ban:', table['name'] ?? 'N/A', 0);
      await printer.printLeftRight('Tong gio:', _formatDuration(totalHours.toDouble()), 0);
      await printer.printCustom('--------------------------------', 0, 1);
      
      // Print Hourly Charge Breakdown
      await printer.printLeftRight(
        'Tien ban:',
        _formatCurrency(hourlyCharge.toDouble()),
        0
      );
      await printer.printLeftRight(
        '  ${_formatDuration(totalHours.toDouble())}',
        'x ${_formatCurrency(hourlyRate.toDouble())}',
        0
      );
      
      // Print Food Items
      if (orders != null && orders.isNotEmpty) {
        await printer.printCustom('--------------------------------', 0, 1);
        await printer.printCustom('Mon an:', 1, 0); // Bold, Left
        
        for (final order in orders) {
          final items = order['items'] as List? ?? [];
          for (final item in items) {
            final dish = item['dish'] as Map<String, dynamic>?;
            final quantity = (item['quantity'] ?? 0) as int;
            final price = (item['price'] ?? 0.0) as num;
            final total = quantity * price.toDouble();
            
            await printer.printLeftRight(
              '  ${dish?['name'] ?? 'N/A'} (x$quantity)',
              _formatCurrency(total),
              0,
            );
          }
        }
        
        await printer.printCustom('--------------------------------', 0, 1);
        await printer.printLeftRight('Tong mon:', _formatCurrency(orderTotal.toDouble()), 1);
      }
      
      // Print Total
      await printer.printCustom('================================', 1, 1);
      await printer.printLeftRight('TONG CONG:', _formatCurrency(grandTotal.toDouble()), 2); // Size 2
      await printer.printCustom('================================', 1, 1);
      
      // Print Footer
      await printer.printCustom('Cam on quy khach!', 2, 1);
      await printer.printNewLine();
      await printer.printNewLine();
      await printer.printNewLine();
      await printer.paperCut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('In hóa đơn thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi in hóa đơn: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: $_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_checkoutData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: const Center(child: Text('Không có dữ liệu')),
      );
    }

    try {
      final session = _checkoutData!['session'] as Map<String, dynamic>?;
      final table = _checkoutData!['table'] as Map<String, dynamic>?;
      // Get orders from root level (preferred) or from session
      final orders = _checkoutData!['orders'] as List? ?? session?['orders'] as List?;
      print('🔍 Display orders: ${orders?.length ?? 0} orders found');
      
      if (session == null || table == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Thanh toán')),
          body: const Center(child: Text('Dữ liệu không hợp lệ')),
        );
      }

      final totalHours = (session['totalHours'] ?? 0.0) as num;
      final hourlyRate = (table['hourlyRate'] ?? 0.0) as num;
      final hourlyCharge = (_checkoutData!['hourlyCharge'] ?? 0.0) as num;
      final orderTotal = (_checkoutData!['orderTotal'] ?? 0.0) as num;
      final grandTotal = (_checkoutData!['grandTotal'] ?? 0.0) as num;

      return Scaffold(
        appBar: AppBar(
          title: Text('Thanh toán - ${table['name'] ?? 'N/A'}'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin session',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Giờ vào', 
                        _formatDateTime(session['startTime'])
                      ),
                      _buildInfoRow(
                        'Tổng giờ', 
                        _formatDuration(totalHours.toDouble())
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết thanh toán',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Tiền bàn',
                        '${_formatDuration(totalHours.toDouble())} × ${_formatCurrency(hourlyRate.toDouble())}/giờ',
                      ),
                      _buildInfoRow('', _formatCurrency(hourlyCharge.toDouble())),
                      if (orders != null && orders.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Món ăn:', style: TextStyle(fontWeight: FontWeight.w500)),
                        ...() {
                          // CHỈ lấy PENDING orders (bỏ qua CANCELLED và COMPLETED)
                          final pendingOrders = orders.where((order) {
                            final status = order['status'] as String?;
                            return status == 'PENDING';
                          }).toList();
                          
                          print('📋 Total orders: ${orders.length}, PENDING orders: ${pendingOrders.length}');
                          
                          // Gộp tất cả items từ PENDING orders lại theo dishId
                          final Map<int, Map<String, dynamic>> groupedItems = {};
                          
                          for (var order in pendingOrders) {
                            final orderId = order['id'] as int?;
                            final items = order['items'] as List? ?? [];
                            print('📦 Processing order $orderId with ${items.length} items');
                            
                            for (var item in items) {
                              final dish = item['dish'] as Map<String, dynamic>?;
                              final dishId = dish?['id'] as int?;
                              final dishName = dish?['name'] as String?;
                              final quantity = (item['quantity'] ?? 0) as int;
                              final price = (item['price'] ?? 0.0) as num;
                              
                              print('  ➕ Item: $dishName (id: $dishId) x$quantity @ ${price}đ');
                              
                              if (dishId != null) {
                                if (groupedItems.containsKey(dishId)) {
                                  // Cộng dồn quantity nếu dish đã tồn tại
                                  final existing = groupedItems[dishId]!;
                                  final existingQty = existing['quantity'] as int;
                                  final newQty = existingQty + quantity;
                                  groupedItems[dishId] = {
                                    'dish': dish,
                                    'quantity': newQty,
                                    'price': price, // Giữ giá từ item đầu tiên
                                  };
                                  print('    📊 Updated: $dishName from $existingQty to $newQty');
                                } else {
                                  // Thêm dish mới
                                  groupedItems[dishId] = {
                                    'dish': dish,
                                    'quantity': quantity,
                                    'price': price,
                                  };
                                  print('    ✨ Added: $dishName x$quantity');
                                }
                              }
                            }
                          }
                          
                          print('🛒 Final grouped items: ${groupedItems.length} unique dishes');
                          for (var entry in groupedItems.entries) {
                            final dish = entry.value['dish'] as Map<String, dynamic>?;
                            print('  - ${dish?['name']}: x${entry.value['quantity']}');
                          }
                          
                          // Chuyển đổi thành list widgets để hiển thị
                          return groupedItems.values.map<Widget>((itemData) {
                            final dish = itemData['dish'] as Map<String, dynamic>?;
                            final quantity = itemData['quantity'] as int;
                            final price = (itemData['price'] ?? 0.0) as num;
                            final total = quantity * price.toDouble();
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('${dish?['name'] ?? 'N/A'} (x$quantity)'),
                                  ),
                                  Text(_formatCurrency(total)),
                                ],
                              ),
                            );
                          }).toList();
                        }(),
                        const Divider(),
                        _buildInfoRow('Tổng món ăn', _formatCurrency(orderTotal.toDouble())),
                      ],
                      const Divider(thickness: 2),
                      _buildInfoRow(
                        'TỔNG CỘNG',
                        _formatCurrency(grandTotal.toDouble()),
                        isBold: true,
                        fontSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hoàn tất thanh toán', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Checkout error: $e');
      print('Stack: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Lỗi hiển thị', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

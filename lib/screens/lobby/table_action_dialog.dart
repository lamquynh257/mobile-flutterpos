import 'package:flutter/material.dart';
import '../../models/table_model.dart';
import '../../services/table_service.dart';
import '../checkout/checkout_screen.dart';
import '../order/order_food_screen.dart';

class TableActionDialog extends StatelessWidget {
  final TableModel table;
  final VoidCallback onRefresh;

  const TableActionDialog({
    Key? key,
    required this.table,
    required this.onRefresh,
  }) : super(key: key);

  Future<void> _bookTable(BuildContext context) async {
    try {
      // Tự động lấy giờ hiện tại từ máy client
      final clientTime = DateTime.now();
      
      // Show confirmation với giờ hiện tại
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đặt bàn'),
          content: Text('Đặt bàn ${table.name} lúc ${_formatDateTime(clientTime, showDate: true)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đặt bàn'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Gửi giờ hiện tại của client lên server
      await TableService.book(table.id, startTime: clientTime);
      
      if (!context.mounted) return;
      
      // Close dialog first
      Navigator.pop(context);
      
      // Then refresh and show message
      onRefresh();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đặt ${table.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
      }
    }
  }

  Future<void> _showTableInfo(BuildContext context) async {
    try {
      final tableDetail = await TableService.getById(table.id);
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thông tin ${tableDetail.name}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Trạng thái', _getStatusText(tableDetail.status)),
                _buildInfoRow('Giá giờ', '${_formatCurrency(tableDetail.hourlyRate)}/giờ'),
                if (tableDetail.activeSession != null) ...[
                  const Divider(),
                  const Text('Session hiện tại:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow('Giờ vào', _formatDateTime(tableDetail.activeSession!.startTime)),
                  _buildInfoRow('Đã chơi', '${tableDetail.elapsedTime?.inMinutes ?? 0} phút'),
                  _buildInfoRow('Tiền giờ hiện tại', _formatCurrency(tableDetail.currentHourlyCharge)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}đ';
  }

  String _formatDateTime(DateTime dt, {bool showDate = false}) {
    if (showDate) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'EMPTY':
        return 'Trống';
      case 'OCCUPIED':
        return 'Đang sử dụng';
      case 'RESERVED':
        return 'Đã đặt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = table.status == 'EMPTY';
    final bool isOccupied = table.status == 'OCCUPIED';

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              table.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(table.status),
              style: TextStyle(
                color: isEmpty ? Colors.green : (isOccupied ? Colors.red : Colors.orange),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            if (isEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _bookTable(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Đặt bàn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
            if (isOccupied) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog first
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(table: table),
                      ),
                    );
                    
                    // If checkout completed, refresh and close
                    if (result == true) {
                      onRefresh();
                    }
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Thanh toán'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Chỉ hiển thị nút "Gọi món" khi bàn không trống (đang sử dụng hoặc đã đặt)
            if (!isEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModernOrderScreen(table: table),
                      ),
                    );
                    
                    // Refresh if order was placed
                    if (result == true) {
                      onRefresh();
                    }
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Gọi món'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showTableInfo(context);
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Thông tin bàn'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/rally.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  Future<void> _deleteAllData() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa dữ liệu'),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ dữ liệu?\n\n'
          'Dữ liệu sẽ bị xóa:\n'
          '• Tất cả đơn hàng (Orders)\n'
          '• Tất cả phiên bàn (Table Sessions)\n'
          '• Tất cả thanh toán (Payments)\n\n'
          'Dữ liệu được giữ lại:\n'
          '• Người dùng (Users)\n'
          '• Tầng (Floors)\n'
          '• Bàn (Tables)\n'
          '• Món ăn (Dishes)\n\n'
          'Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show second confirmation
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lần cuối'),
        content: const Text(
          'Bạn có CHẮC CHẮN muốn xóa toàn bộ dữ liệu?\n\n'
          'Hành động này sẽ xóa vĩnh viễn tất cả đơn hàng, phiên bàn và thanh toán.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('XÓA NGAY'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final response = await ApiService.delete('/admin/clear-data');
      ApiService.handleResponse(response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa toàn bộ dữ liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: RallyColors.primaryBackground,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Management Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Quản lý User'),
              subtitle: const Text('Thêm, sửa, xóa người dùng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/user-management');
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Bill Settings Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Cài đặt hóa đơn'),
              subtitle: const Text('Chỉnh sửa thông tin cửa hàng và QR code'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/bill-settings');
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Danger Zone
          Card(
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Vùng nguy hiểm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                  title: Text(
                    'Xóa dữ liệu',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Xóa toàn bộ đơn hàng, phiên bàn và thanh toán\n'
                    '(Giữ lại: User, Tầng, Bàn, Món ăn)',
                    style: TextStyle(
                      color: Colors.red.shade800,
                    ),
                  ),
                  trailing: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.chevron_right, color: Colors.red.shade700),
                  onTap: _isDeleting ? null : _deleteAllData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


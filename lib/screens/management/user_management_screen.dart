import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import 'user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await UserService.getAll();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi load users: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showUserDialog({User? user}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserDialog(user: user),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa user "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await UserService.delete(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa user thành công')),
          );
        }
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý User'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Chưa có user nào'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                    columns: const [
                      DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(Text(user.username)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user.role == 'ADMIN' ? Colors.red.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.role,
                                style: TextStyle(
                                  color: user.role == 'ADMIN' ? Colors.red.shade900 : Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDate(user.createdAt))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showUserDialog(user: user),
                                  tooltip: 'Sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm User'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

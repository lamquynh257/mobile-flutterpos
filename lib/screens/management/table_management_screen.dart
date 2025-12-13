import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/floor.dart';
import '../../models/table_model.dart';
import '../../services/table_service.dart';

class TableManagementScreen extends StatefulWidget {
  final Floor floor;

  const TableManagementScreen({Key? key, required this.floor}) : super(key: key);

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  List<TableModel> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final tables = await TableService.getAll(floorId: widget.floor.id);
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddTableDialog() async {
    final nameController = TextEditingController();
    final hourlyRateController = TextEditingController(text: '50000');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm bàn mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên bàn',
                  hintText: 'VD: Bàn 1',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Giá theo giờ (VNĐ)',
                  hintText: '50000',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              const Text(
                'Giá này sẽ được tính khi khách chơi bàn theo giờ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên bàn')),
                );
                return;
              }

              try {
                await TableService.create(
                  floorId: widget.floor.id,
                  name: nameController.text.trim(),
                  hourlyRate: double.tryParse(hourlyRateController.text) ?? 0,
                );
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadTables();
    }
  }

  Future<void> _showEditTableDialog(TableModel table) async {
    final nameController = TextEditingController(text: table.name);
    final hourlyRateController = TextEditingController(text: '${table.hourlyRate.toInt()}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa bàn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên bàn'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Giá theo giờ (VNĐ)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await TableService.update(
                  table.id,
                  name: nameController.text.trim(),
                  hourlyRate: double.tryParse(hourlyRateController.text) ?? table.hourlyRate,
                );
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadTables();
    }
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${table.name}"?'),
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
        await TableService.delete(table.id);
        _loadTables();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa bàn')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}đ';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'EMPTY':
        return Colors.green;
      case 'OCCUPIED':
        return Colors.red;
      case 'RESERVED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý bàn - ${widget.floor.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Chưa có bàn nào trong ${widget.floor.name}'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddTableDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm bàn đầu tiên'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tables.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(table.status),
                          child: const Icon(Icons.table_restaurant, color: Colors.white),
                        ),
                        title: Text(
                          table.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Giá: ${_formatCurrency(table.hourlyRate)}/giờ'),
                            Text(
                              'Trạng thái: ${_getStatusText(table.status)}',
                              style: TextStyle(
                                color: _getStatusColor(table.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTableDialog(table),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTable(table),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTableDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

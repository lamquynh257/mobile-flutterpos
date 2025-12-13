import 'package:flutter/material.dart';
import '../../models/floor.dart';
import '../../services/floor_service.dart';

class FloorManagementScreen extends StatefulWidget {
  const FloorManagementScreen({Key? key}) : super(key: key);

  @override
  State<FloorManagementScreen> createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> {
  List<Floor> _floors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFloors();
  }

  Future<void> _loadFloors() async {
    setState(() => _isLoading = true);
    try {
      final floors = await FloorService.getAll();
      setState(() {
        _floors = floors;
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

  Future<void> _showAddFloorDialog() async {
    final nameController = TextEditingController();
    final orderController = TextEditingController(text: '${_floors.length + 1}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tầng mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên tầng',
                hintText: 'VD: Tầng 1',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: orderController,
              decoration: const InputDecoration(
                labelText: 'Thứ tự hiển thị',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
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
                  const SnackBar(content: Text('Vui lòng nhập tên tầng')),
                );
                return;
              }

              try {
                await FloorService.create(
                  nameController.text.trim(),
                  order: int.tryParse(orderController.text) ?? 0,
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
      _loadFloors();
    }
  }

  Future<void> _showEditFloorDialog(Floor floor) async {
    final nameController = TextEditingController(text: floor.name);
    final orderController = TextEditingController(text: '${floor.order}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa tầng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên tầng'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: orderController,
              decoration: const InputDecoration(labelText: 'Thứ tự'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FloorService.update(
                  floor.id,
                  name: nameController.text.trim(),
                  order: int.tryParse(orderController.text) ?? floor.order,
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
      _loadFloors();
    }
  }

  Future<void> _deleteFloor(Floor floor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${floor.name}"?\nTất cả bàn trong tầng này cũng sẽ bị xóa.'),
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
        await FloorService.delete(floor.id);
        _loadFloors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tầng')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tầng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFloors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _floors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Chưa có tầng nào'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddFloorDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm tầng đầu tiên'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _floors.length,
                  itemBuilder: (context, index) {
                    final floor = _floors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${floor.order}'),
                        ),
                        title: Text(floor.name),
                        subtitle: Text('ID: ${floor.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.table_restaurant),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/table-management',
                                  arguments: floor,
                                );
                              },
                              tooltip: 'Quản lý bàn',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditFloorDialog(floor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFloor(floor),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFloorDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

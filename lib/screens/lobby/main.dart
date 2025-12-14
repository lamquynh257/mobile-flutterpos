import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../database_factory.dart';
import '../../storage_engines/connection_interface.dart';
import '../../models/floor.dart' as ApiFloor;
import '../../models/table_model.dart';
import '../../services/floor_service.dart';
import '../../services/table_service.dart';
import '../../services/auth_service.dart';
import './table_icon.dart';
import './table_action_dialog.dart';
import '../../common/common.dart';
import '../../theme/rally.dart';
import '../../provider/src.dart';
import 'anim_longclick_fab.dart';

class LobbyScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final floors = useState<List<ApiFloor.Floor>>([]);
    final isLoading = useState(true);
    final currentFloorIndex = useState(0);

    // Load floors from API
    useEffect(() {
      Future<void> loadFloors() async {
        try {
          final loadedFloors = await FloorService.getAll();
          floors.value = loadedFloors;
          isLoading.value = false;
        } catch (e) {
          isLoading.value = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi load tầng: ${e.toString()}')),
          );
        }
      }

      loadFloors();
      return null;
    }, []);

    final tabs = useMemoized(
      () => floors.value.map((f) => Tab(text: f.name)).toList(),
      [floors.value],
    );

    final ticker = useSingleTickerProvider(keys: [floors.value.length]);
    final controller = useMemoized(
      () {
        // Ensure length is at least 1 to avoid "Invalid argument: 0" error
        final length = floors.value.length > 0 ? floors.value.length : 1;
        return TabController(
          length: length,
          vsync: ticker,
          initialIndex: currentFloorIndex.value.clamp(0, length - 1),
        );
      },
      [floors.value.length],
    );

    useEffect(() {
      void listener() {
        if (floors.value.isNotEmpty) {
          currentFloorIndex.value = controller.index;
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    if (isLoading.value) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (floors.value.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Chưa có tầng nào'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/floor-management'),
                icon: const Icon(Icons.add),
                label: const Text('Quản lý tầng & bàn'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context),
      );
    }

    // Store GlobalKeys for each floor tab to access their state
    final floorTabKeysMap = useMemoized(
      () {
        final map = <int, GlobalKey<_FloorTabViewState>>{};
        for (var floor in floors.value) {
          map[floor.id] = GlobalKey<_FloorTabViewState>();
        }
        return map;
      },
      [floors.value.map((f) => f.id).join(',')],
    );

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(context),
      floatingActionButton: AnimatedLongClickableFAB(
        onLongPress: () {
          // Keep old functionality for adding tables via long press
          if (floors.value.isNotEmpty) {
            final currentFloor = floors.value[controller.index];
            context.read<NodeSupplier>().addNode(currentFloor.id);
          }
        },
        onPressed: () {
          // Add table to current floor when button is tapped
          if (floors.value.isNotEmpty) {
            final currentFloor = floors.value[controller.index];
            _showAddTableDialog(context, currentFloor, () {
              // Reload tables for current floor after adding
              final key = floorTabKeysMap[currentFloor.id];
              if (key?.currentState != null) {
                key!.currentState!._loadTables();
              }
            });
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        title: TabBar(
          controller: controller,
          isScrollable: true,
          tabs: tabs,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              isLoading.value = true;
              try {
                final loadedFloors = await FloorService.getAll();
                floors.value = loadedFloors;
                isLoading.value = false;
              } catch (e) {
                isLoading.value = false;
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: floors.value
            .map((floor) => _FloorTabView(
                  key: floorTabKeysMap[floor.id],
                  floor: floor,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Tooltip(
            message: AppLocalizations.of(context)?.lobby_report ?? 'Report',
            child: MaterialButton(
              onPressed: () {
                _showBottomSheetMenu(context);
              },
              minWidth: MediaQuery.of(context).size.width / 2,
              shape: const CustomShape(side: CustomShapeSide.left),
              child: const Icon(Icons.menu),
            ),
          ),
          Tooltip(
            message: AppLocalizations.of(context)?.lobby_menuEdit ?? 'Edit Menu',
            child: MaterialButton(
              onPressed: () => Navigator.pushNamed(context, '/edit-menu'),
              minWidth: MediaQuery.of(context).size.width / 2,
              shape: const CustomShape(side: CustomShapeSide.right),
              child: const Icon(Icons.menu_book_sharp),
            ),
          )
        ],
      ),
    );
  }

  Future _showBottomSheetMenu(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text(
                'QUẢN LÝ TẦNG & BÀN',
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/floor-management');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: Text(
                AppLocalizations.of(context)?.lobby_report.toUpperCase() ?? 'REPORT',
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text(
                'CÀI ĐẶT',
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'ĐĂNG XUẤT',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTableDialog(
    BuildContext context,
    ApiFloor.Floor floor,
    VoidCallback onSuccess,
  ) async {
    final nameController = TextEditingController();
    final hourlyRateController = TextEditingController(text: '50000');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm bàn mới vào ${floor.name}'),
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
                  floorId: floor.id,
                  name: nameController.text.trim(),
                  hourlyRate: double.tryParse(hourlyRateController.text) ?? 50000,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm bàn thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result == true) {
      onSuccess();
    }
  }
}

/// Floor tab view showing tables from API
class _FloorTabView extends StatefulWidget {
  final ApiFloor.Floor floor;

  const _FloorTabView({Key? key, required this.floor}) : super(key: key);

  @override
  State<_FloorTabView> createState() => _FloorTabViewState();
}

class _FloorTabViewState extends State<_FloorTabView>
    with AutomaticKeepAliveClientMixin {
  List<TableModel> _tables = [];
  bool _isLoading = true;
  late GlobalKey bgKey;
  late TransformationController transformController;
  final _dragEndEvent = StreamController<Map<String, num>>.broadcast();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    bgKey = GlobalKey();
    transformController = TransformationController();
    _loadTables();
    
    // Update timer every second for occupied tables
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _tables.any((t) => t.isOccupied)) {
        setState(() {
          // Force rebuild to update timer display
        });
      }
    });
  }

  // Make _loadTables public so it can be called from parent
  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final tables = await TableService.getAll(floorId: widget.floor.id);
      print('📊 Loaded ${tables.length} tables for floor ${widget.floor.id}');
      
      // Auto-arrange tables if they're all at (0,0)
      final needsArrange = tables.isNotEmpty && tables.every((t) => t.x == 0 && t.y == 0);
      print('🔧 Needs arrange: $needsArrange');
      
      if (needsArrange) {
        print('🎯 Auto-arranging ${tables.length} tables...');
        await _autoArrangeTables(tables);
        print('✅ Auto-arrange complete, reloading...');
        // Reload after arranging
        final updatedTables = await TableService.getAll(floorId: widget.floor.id);
        print('📊 Reloaded ${updatedTables.length} tables after arrange');
        setState(() {
          _tables = updatedTables;
          _isLoading = false;
        });
      } else {
        print('✅ Tables already arranged');
        setState(() {
          _tables = tables;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading tables: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi load bàn: ${e.toString()}')),
        );
      }
    }
  }

  // Update single table without reloading all
  Future<void> _updateSingleTable(int tableId) async {
    try {
      final updatedTable = await TableService.getById(tableId);
      setState(() {
        final index = _tables.indexWhere((t) => t.id == tableId);
        if (index != -1) {
          _tables[index] = updatedTable;
        }
      });
    } catch (e) {
      print('❌ Error updating table: $e');
      // Fallback to full reload if single update fails
      _loadTables();
    }
  }

  Future<void> _autoArrangeTables(List<TableModel> tables) async {
    // Arrange tables in a grid pattern
    const double startX = 20;
    const double startY = 20;
    const double spacing = 100;
    const int tablesPerRow = 6; // Changed from 4 to 6 columns

    print('🎨 Starting auto-arrange for ${tables.length} tables');
    for (int i = 0; i < tables.length; i++) {
      final row = i ~/ tablesPerRow;
      final col = i % tablesPerRow;
      final x = startX + (col * spacing);
      final y = startY + (row * spacing);

      print('  📍 Table ${tables[i].name}: ($x, $y)');
      try {
        await TableService.update(tables[i].id, x: x, y: y);
        print('  ✅ Updated ${tables[i].name}');
      } catch (e) {
        print('  ❌ Error updating ${tables[i].name}: $e');
      }
    }
    print('🎨 Auto-arrange loop complete');
  }

  @override
  void dispose() {
    _timer?.cancel();
    transformController.dispose();
    _dragEndEvent.close();
    super.dispose();
  }

  Color _getTableColor(String status) {
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

  String _formatElapsedTime(Duration? elapsed) {
    if (elapsed == null) return '';
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Chưa có bàn nào trong ${widget.floor.name}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/table-management',
                  arguments: widget.floor,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm bàn'),
            ),
          ],
        ),
      );
    }

    // Use GridView for automatic 6-column layout
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // 6 columns
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _tables.length,
      itemBuilder: (context, index) {
        final table = _tables[index];
        
        return GestureDetector(
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => TableActionDialog(
                table: table,
                onRefresh: () => _updateSingleTable(table.id),
              ),
            );
            // No need to reload - onRefresh already called in dialog
          },
          child: Container(
            decoration: BoxDecoration(
              color: _getTableColor(table.status),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.table_restaurant, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  table.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (table.isOccupied && table.elapsedTime != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatElapsedTime(table.elapsedTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

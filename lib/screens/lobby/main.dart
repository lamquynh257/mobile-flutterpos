import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../database_factory.dart';
import '../../storage_engines/connection_interface.dart';
import '../../models/floor.dart' as ApiFloor;
import '../../models/table_model.dart';
import '../../services/floor_service.dart';
import '../../services/table_service.dart';
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
            .map((floor) => _FloorTabView(floor: floor))
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
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text(
                'QUẢN LÝ THỰC ĐƠN',
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/menu-management');
              },
            ),
            const Divider(),
            ListTile(
              title: Text(
                AppLocalizations.of(context)?.lobby_report.toUpperCase() ?? 'HISTORY',
                textAlign: TextAlign.center,
              ),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)?.lobby_journal.toUpperCase() ?? 'EXPENSE JOURNAL',
                textAlign: TextAlign.center,
              ),
              onTap: () => Navigator.pushNamed(context, '/expense'),
            ),
          ],
        );
      },
    );
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

  Future<void> _autoArrangeTables(List<TableModel> tables) async {
    // Arrange tables in a grid pattern
    const double startX = 20;
    const double startY = 20;
    const double spacing = 100;
    const int tablesPerRow = 4;

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

    return InteractiveViewer(
      maxScale: 2.0,
      transformationController: transformController,
      child: Stack(
        children: [
          Container(key: bgKey),
          for (var table in _tables)
            Positioned(
              left: table.x,
              top: table.y,
              child: GestureDetector(
                onTap: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => TableActionDialog(
                      table: table,
                      onRefresh: _loadTables,
                    ),
                  );
                  
                  // Refresh if dialog returned true (after checkout)
                  if (result == true) {
                    _loadTables();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getTableColor(table.status),
                    borderRadius: BorderRadius.circular(8),
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
                      const Icon(Icons.table_restaurant, color: Colors.white, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        table.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (table.isOccupied && table.elapsedTime != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatElapsedTime(table.elapsedTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../../storage_engines/connection_interface.dart';
import '../../services/category_service.dart';
import '../../services/dish_service.dart';
import '../../models/category.dart' as ApiCategory;
import '../../models/dish.dart' as ApiDish;

import '../src.dart';

class MenuSupplier extends ChangeNotifier {
  List<Dish> _m = [];

  List<Dish> get menu => _m;

  bool _loading = false;
  bool get loading => _loading;

  final RIUDRepository<Dish>? database;
  
  // Default category for dishes (since UI doesn't have categories)
  int? _defaultCategoryId;

  MenuSupplier({this.database, List<Dish>? mockMenu}) {
    if (mockMenu != null) {
      _m = mockMenu;
      _loading = false;
      return;
    }
    _loading = true;
    Future(() async {
      try {
        // Ensure default category exists
        await _ensureDefaultCategory();
        
        // Load dishes from API
        await _loadDishesFromAPI();
        
        // Ensure menu is not empty
        if (_m.isEmpty) {
          print('⚠️ Menu is empty after loading, using defaults');
          _m = _defaultMenu();
        }
        
        _loading = false;
        notifyListeners();
      } catch (e, stack) {
        print('❌ Error loading menu: $e');
        print('Stack: $stack');
        // Fallback to default menu if API fails
        if (_m.isEmpty) {
          print('📋 Using default menu as fallback');
          _m = _defaultMenu();
        }
        _loading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _ensureDefaultCategory() async {
    try {
      final categories = await CategoryService.getAll();
      
      if (categories.isEmpty) {
        // Create default category
        final category = await CategoryService.create(name: 'Thực đơn', order: 0);
        _defaultCategoryId = category.id;
        print('✅ Created default category: ${category.id}');
      } else {
        _defaultCategoryId = categories.first.id;
        print('✅ Using existing category: $_defaultCategoryId');
      }
    } catch (e, stack) {
      print('❌ Error ensuring category: $e');
      print('Stack: $stack');
      // Don't rethrow - allow fallback to default menu
      // Set a default category ID to avoid null issues
      _defaultCategoryId = 1; // Fallback ID
      print('⚠️ Using fallback category ID: $_defaultCategoryId');
    }
  }

  Future<void> _loadDishesFromAPI() async {
    try {
      print('🍽️ Loading ALL dishes from API (not filtering by category)');
      
      // Load ALL dishes from API, not just from one category
      // This ensures we get all dishes from the database
      final apiDishes = await DishService.getAll(); // No categoryId filter
      print('🍽️ Received ${apiDishes.length} dishes from API');
      
      if (apiDishes.isEmpty) {
        print('⚠️ No dishes found in API, using default menu');
        _m = _defaultMenu();
        return;
      }
      
      // Convert API dishes to local Dish model
      print('🔄 Converting ${apiDishes.length} dishes from API...');
      _m = apiDishes.map((apiDish) {
        try {
          final converted = _convertFromApiDish(apiDish);
          print('  ✅ Converted: ${apiDish.id} - ${apiDish.name} (${apiDish.price})');
          return converted;
        } catch (e, stack) {
          print('⚠️ Error converting dish ${apiDish.id} (${apiDish.name}): $e');
          print('Stack: $stack');
          return null;
        }
      }).whereType<Dish>().toList();
      
      print('🍽️ Successfully converted ${_m.length} dishes to local model');
      print('📋 Final menu items:');
      for (var dish in _m) {
        print('  - ${dish.id}: ${dish.dish} (${dish.price})');
      }
      
      // If no dishes, add defaults
      if (_m.isEmpty) {
        print('🍽️ No dishes found, adding defaults...');
        _m = _defaultMenu();
        // Try to save defaults to API (but don't fail if it errors)
        try {
          for (var dish in _m) {
            await _saveDishToAPI(dish);
          }
          print('🍽️ Saved ${_m.length} default dishes to API');
        } catch (e) {
          print('⚠️ Could not save defaults to API: $e');
          // Continue anyway - menu is loaded locally
        }
      }
    } catch (e, stack) {
      print('❌ Error loading dishes from API: $e');
      print('Stack: $stack');
      // Always fallback to default menu
      print('📋 Falling back to default menu');
      _m = _defaultMenu();
    }
  }

  Dish _convertFromApiDish(ApiDish.Dish apiDish) {
    // Convert API dish to local Dish model
    // Local Dish model expects: {id, dish, price, asset}
    print('🔄 Converting dish: ${apiDish.id} - ${apiDish.name} - ${apiDish.price}');
    
    // Map dish name to asset path (similar to default menu)
    final assetPath = _getAssetPathForDish(apiDish.name);
    
    return Dish.fromJson({
      'id': apiDish.id,
      'dish': apiDish.name, // API uses 'name', local uses 'dish'
      'price': apiDish.price,
      'asset': assetPath, // Set asset path for icon
    });
  }

  /// Map dish name to asset path based on name matching
  /// This ensures dishes from API have the same icons as default menu
  String? _getAssetPathForDish(String dishName) {
    final name = dishName.toLowerCase().trim();
    
    // Map common dish names to asset paths (matching default menu)
    // Coffee variations
    if (name.contains('coffee') || name.contains('cà phê') || name.contains('cf') || 
        name == 'cf' || name == 'cf den' || name.contains('cà phê đen')) {
      return 'assets/coffee.png';
    }
    // Tea variations
    else if (name.contains('trà') || name.contains('tea') || 
             name.contains('việt quất') || name.contains('tra da')) {
      return 'assets/lime_juice.png'; // Use juice icon for tea/drinks
    }
    // Water/drinks
    else if (name.contains('aqua') || name.contains('nước') || name.contains('water')) {
      return 'assets/lime_juice.png';
    }
    // Noodles
    else if (name.contains('noodle') || name.contains('mì') || name.contains('phở')) {
      if (name.contains('vegan') || name.contains('chay')) {
        return 'assets/vegan_noodles.png';
      } else {
        return 'assets/rice_noodles.png';
      }
    }
    // Juice
    else if (name.contains('juice') || name.contains('nước ép') || name.contains('lime')) {
      return 'assets/lime_juice.png';
    }
    // Oatmeal
    else if (name.contains('oatmeal') || name.contains('yến mạch')) {
      return 'assets/oatmeal_with_berries_and_coconut.png';
    }
    // Chicken/Egg
    else if (name.contains('chicken') || name.contains('gà') || 
             name.contains('egg') || name.contains('trứng')) {
      return 'assets/fried_chicken-with_with_wit_egg.png';
    }
    // Kimchi
    else if (name.contains('kimchi')) {
      return 'assets/kimchi.png';
    }
    
    // Default fallback - use coffee icon
    return 'assets/coffee.png';
  }

  Future<void> _saveDishToAPI(Dish dish) async {
    if (_defaultCategoryId == null) return;
    
    try {
      await DishService.create(
        categoryId: _defaultCategoryId!,
        name: dish.dish,
        price: dish.price,
      );
    } catch (e) {
      print('Error saving dish to API: $e');
    }
  }

  Dish getDish(int index) {
    return _m.elementAt(index);
  }

  /// returns null if invalid ID
  Dish? find(int id) {
    if (_m.any((d) => d.id == id)) {
      return _m.firstWhere((d) => d.id == id);
    }
    return null;
  }

  Future<Dish> addDish(String name, double price, [Uint8List? image]) async {
    print('➕ Adding dish: $name, price: $price');
    if (_defaultCategoryId == null) {
      print('⚠️ No default category, creating one...');
      await _ensureDefaultCategory();
    }
    
    try {
      print('📡 Calling API to create dish in category $_defaultCategoryId');
      // Save to API
      final apiDish = await DishService.create(
        categoryId: _defaultCategoryId!,
        name: name,
        price: price,
      );
      print('✅ API returned dish: ${apiDish.id} - ${apiDish.name}');
      
      // Convert to local model
      final newDish = _convertFromApiDish(apiDish);
      _m.add(newDish);
      print('✅ Added to local menu, total dishes: ${_m.length}');
      notifyListeners();
      return newDish;
    } catch (e, stack) {
      print('❌ Error adding dish to API: $e');
      print('Stack: $stack');
      // Fallback to local
      final t = Dish(name, price, image);
      _m.add(t);
      notifyListeners();
      return t;
    }
  }

  /// Input value is from current [Menu] instance
  Future<void> updateDish(Dish dish, [String? name, double? price, Uint8List? image]) async {
    assert(_m.contains(dish));
    
    try {
      // Update API
      await DishService.update(
        dish.id,
        name: name ?? dish.dish,
        price: price ?? dish.price,
      );
      
      // Update local
      dish.dish = name ?? dish.dish;
      dish.price = price ?? dish.price;
      dish.imgProvider = image != null ? MemoryImage(image) : dish.imgProvider;
      notifyListeners();
    } catch (e) {
      print('Error updating dish: $e');
      // Update local anyway
      dish.dish = name ?? dish.dish;
      dish.price = price ?? dish.price;
      dish.imgProvider = image != null ? MemoryImage(image) : dish.imgProvider;
      notifyListeners();
    }
  }

  /// Input value is from current [Menu] instance
  Future<void> removeDish(Dish dish) async {
    assert(_m.contains(dish));

    try {
      // Delete from API
      await DishService.delete(dish.id);
      
      // Remove from local
      _m.remove(dish);
      notifyListeners();
    } catch (e) {
      print('Error removing dish: $e');
      // Remove from local anyway
      _m.remove(dish);
      notifyListeners();
    }
  }

  /// Reload dishes from API/database
  /// This method should be called when entering EditMenuScreen to ensure fresh data
  Future<void> reload() async {
    print('🔄 Reloading menu from API...');
    _loading = true;
    notifyListeners();
    
    try {
      // Ensure default category exists
      await _ensureDefaultCategory();
      
      // Load dishes from API
      await _loadDishesFromAPI();
      
      // Ensure menu is not empty
      if (_m.isEmpty) {
        print('⚠️ Menu is empty after reload, using defaults');
        _m = _defaultMenu();
      }
      
      _loading = false;
      notifyListeners();
      print('✅ Menu reloaded successfully, ${_m.length} dishes');
    } catch (e, stack) {
      print('❌ Error reloading menu: $e');
      print('Stack: $stack');
      // Fallback to default menu if API fails
      if (_m.isEmpty) {
        print('📋 Using default menu as fallback');
        _m = _defaultMenu();
      }
      _loading = false;
      notifyListeners();
    }
  }
}

List<Dish> _defaultMenu() {
  return [
    Dish.fromAsset(
      'Rice Noodles',
      10000,
      'assets/rice_noodles.png',
    ),
    Dish.fromAsset(
      'Lime Juice',
      20000,
      'assets/lime_juice.png',
    ),
    Dish.fromAsset(
      'Vegan Noodle',
      30000,
      'assets/vegan_noodles.png',
    ),
    Dish.fromAsset(
      'Oatmeal with Berries and Coconut',
      40000,
      'assets/oatmeal_with_berries_and_coconut.png',
    ),
    Dish.fromAsset(
      'Fried Chicken with Egg',
      50000,
      'assets/fried_chicken-with_with_wit_egg.png',
    ),
    Dish.fromAsset(
      'Kimchi',
      60000,
      'assets/kimchi.png',
    ),
    Dish.fromAsset(
      'Coffee',
      70000,
      'assets/coffee.png',
    ),
  ];
}

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
        
        _loading = false;
        notifyListeners();
      } catch (e) {
        print('Error loading menu: $e');
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
      } else {
        _defaultCategoryId = categories.first.id;
      }
    } catch (e) {
      print('Error ensuring category: $e');
      rethrow;
    }
  }

  Future<void> _loadDishesFromAPI() async {
    try {
      print('🍽️ Loading dishes from API for category: $_defaultCategoryId');
      final apiDishes = await DishService.getAll(categoryId: _defaultCategoryId);
      print('🍽️ Received ${apiDishes.length} dishes from API');
      
      // Convert API dishes to local Dish model
      _m = apiDishes.map((apiDish) => _convertFromApiDish(apiDish)).toList();
      print('🍽️ Converted ${_m.length} dishes to local model');
      
      // If no dishes, add defaults
      if (_m.isEmpty) {
        print('🍽️ No dishes found, adding defaults...');
        _m = _defaultMenu();
        // Save defaults to API
        for (var dish in _m) {
          await _saveDishToAPI(dish);
        }
        print('🍽️ Saved ${_m.length} default dishes to API');
      }
    } catch (e, stack) {
      print('❌ Error loading dishes from API: $e');
      print('Stack: $stack');
      _m = _defaultMenu();
    }
  }

  Dish _convertFromApiDish(ApiDish.Dish apiDish) {
    // Convert API dish to local Dish model
    final dish = Dish(apiDish.name, apiDish.price);
    // Store API ID in local dish
    return Dish.fromJson({
      'id': apiDish.id,
      'dish': apiDish.name,
      'price': apiDish.price,
    });
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

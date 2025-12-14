import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class BillSettingsService {
  static const String _keyQrCodeImage = 'bill_qr_code_image'; // Base64 encoded image - stored locally

  // Get store name from backend
  static Future<String> getStoreName() async {
    try {
      final response = await ApiService.get('/store-settings');
      if (response.statusCode == 404) {
        print('⚠️ Store settings endpoint not found (404). Server may need to be updated.');
        return '';
      }
      final data = ApiService.handleResponse(response);
      final name = data['storeName'] ?? '';
      print('📥 Got store name: $name');
      return name;
    } catch (e) {
      print('❌ Error getting store name: $e');
      return '';
    }
  }

  // Set store name to backend
  static Future<void> setStoreName(String name) async {
    try {
      final currentSettings = await _getCurrentSettings();
      await ApiService.put('/store-settings', {
        ...currentSettings,
        'storeName': name,
      });
    } catch (e) {
      print('Error setting store name: $e');
      rethrow;
    }
  }

  // Get store address from backend
  static Future<String> getStoreAddress() async {
    try {
      final response = await ApiService.get('/store-settings');
      if (response.statusCode == 404) {
        print('⚠️ Store settings endpoint not found (404). Server may need to be updated.');
        return '';
      }
      final data = ApiService.handleResponse(response);
      return data['storeAddress'] ?? '';
    } catch (e) {
      print('❌ Error getting store address: $e');
      return '';
    }
  }

  // Set store address to backend
  static Future<void> setStoreAddress(String address) async {
    try {
      final currentSettings = await _getCurrentSettings();
      await ApiService.put('/store-settings', {
        ...currentSettings,
        'storeAddress': address,
      });
    } catch (e) {
      print('Error setting store address: $e');
      rethrow;
    }
  }

  // Get store phone from backend
  static Future<String> getStorePhone() async {
    try {
      final response = await ApiService.get('/store-settings');
      if (response.statusCode == 404) {
        print('⚠️ Store settings endpoint not found (404). Server may need to be updated.');
        return '';
      }
      final data = ApiService.handleResponse(response);
      return data['storePhone'] ?? '';
    } catch (e) {
      print('❌ Error getting store phone: $e');
      return '';
    }
  }

  // Set store phone to backend
  static Future<void> setStorePhone(String phone) async {
    try {
      final currentSettings = await _getCurrentSettings();
      await ApiService.put('/store-settings', {
        ...currentSettings,
        'storePhone': phone,
      });
    } catch (e) {
      print('Error setting store phone: $e');
      rethrow;
    }
  }

  // Helper to get current settings
  static Future<Map<String, dynamic>> _getCurrentSettings() async {
    try {
      final response = await ApiService.get('/store-settings');
      return ApiService.handleResponse(response);
    } catch (e) {
      // If no settings exist, return empty
      return {
        'storeName': '',
        'storeAddress': null,
        'storePhone': null,
      };
    }
  }

  // Update all settings at once
  static Future<void> updateAll({
    required String storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    try {
      print('🌐 Calling PUT /store-settings');
      print('  - storeName: $storeName');
      print('  - storeAddress: $storeAddress');
      print('  - storePhone: $storePhone');
      
      final response = await ApiService.put('/store-settings', {
        'storeName': storeName,
        'storeAddress': storeAddress,
        'storePhone': storePhone,
      });
      
      print('📦 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');
      
      if (response.statusCode == 404) {
        throw Exception('Endpoint /store-settings không tồn tại. Vui lòng cập nhật server backend với route mới.');
      }
      
      ApiService.handleResponse(response);
      print('✅ Settings updated successfully');
    } catch (e, stackTrace) {
      print('❌ Error updating store settings: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get QR code image as Uint8List
  static Future<Uint8List?> getQrCodeImage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString(_keyQrCodeImage);
    if (base64Image == null || base64Image.isEmpty) {
      return null;
    }
    try {
      return base64Decode(base64Image);
    } catch (e) {
      print('Error decoding QR code image: $e');
      return null;
    }
  }

  // Set QR code image from Uint8List
  static Future<void> setQrCodeImage(Uint8List? imageBytes) async {
    final prefs = await SharedPreferences.getInstance();
    if (imageBytes == null) {
      await prefs.remove(_keyQrCodeImage);
    } else {
      final base64Image = base64Encode(imageBytes);
      await prefs.setString(_keyQrCodeImage, base64Image);
    }
  }

  // Get all settings as a map
  static Future<Map<String, dynamic>> getAllSettings() async {
    try {
      final response = await ApiService.get('/store-settings');
      final data = ApiService.handleResponse(response);
      return {
        'storeName': data['storeName'] ?? '',
        'storeAddress': data['storeAddress'] ?? '',
        'storePhone': data['storePhone'] ?? '',
        'hasQrCode': (await getQrCodeImage()) != null,
      };
    } catch (e) {
      print('Error getting all settings: $e');
      return {
        'storeName': '',
        'storeAddress': '',
        'storePhone': '',
        'hasQrCode': (await getQrCodeImage()) != null,
      };
    }
  }
}


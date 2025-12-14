import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/bill_settings_service.dart';
import '../../theme/rally.dart';

class BillSettingsScreen extends StatefulWidget {
  const BillSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BillSettingsScreen> createState() => _BillSettingsScreenState();
}

class _BillSettingsScreenState extends State<BillSettingsScreen> {
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  Uint8List? _qrCodeImage;
  bool _hasQrCode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      print('📥 Loading store settings...');
      final storeName = await BillSettingsService.getStoreName();
      final storeAddress = await BillSettingsService.getStoreAddress();
      final storePhone = await BillSettingsService.getStorePhone();
      final qrCodeImage = await BillSettingsService.getQrCodeImage();

      print('📥 Loaded settings:');
      print('  - Store Name: $storeName');
      print('  - Store Address: $storeAddress');
      print('  - Store Phone: $storePhone');
      print('  - Has QR Code: ${qrCodeImage != null}');

      setState(() {
        _storeNameController.text = storeName;
        _storeAddressController.text = storeAddress;
        _storePhoneController.text = storePhone;
        _qrCodeImage = qrCodeImage;
        _hasQrCode = qrCodeImage != null;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading settings: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải cài đặt: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickQrCodeImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _qrCodeImage = bytes;
          _hasQrCode = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn hình ảnh: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeQrCodeImage() async {
    setState(() {
      _qrCodeImage = null;
      _hasQrCode = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      print('💾 Saving store settings...');
      print('  - Store Name: ${_storeNameController.text.trim()}');
      print('  - Store Address: ${_storeAddressController.text.trim()}');
      print('  - Store Phone: ${_storePhoneController.text.trim()}');
      
      // Save to backend
      await BillSettingsService.updateAll(
        storeName: _storeNameController.text.trim(),
        storeAddress: _storeAddressController.text.trim().isEmpty 
            ? null 
            : _storeAddressController.text.trim(),
        storePhone: _storePhoneController.text.trim().isEmpty 
            ? null 
            : _storePhoneController.text.trim(),
      );
      print('✅ Store settings saved to backend');
      
      // Save QR code to local storage
      await BillSettingsService.setQrCodeImage(_qrCodeImage);
      print('✅ QR code saved to local storage');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cài đặt thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('❌ Error saving settings: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        String errorMessage = 'Lỗi lưu cài đặt';
        if (e.toString().contains('404') || e.toString().contains('Route not found')) {
          errorMessage = 'Lỗi: Server chưa có endpoint /store-settings.\n'
              'Vui lòng cập nhật và restart server backend.';
        } else if (e.toString().contains('401') || e.toString().contains('token')) {
          errorMessage = 'Lỗi: Chưa đăng nhập hoặc token hết hạn.\n'
              'Vui lòng đăng nhập lại.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'Lỗi: Bạn không có quyền admin.\n'
              'Chỉ admin mới có thể thay đổi cài đặt hóa đơn.';
        } else {
          errorMessage = 'Lỗi lưu cài đặt: ${e.toString()}\n'
              'Vui lòng kiểm tra kết nối và thử lại.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt hóa đơn'),
          backgroundColor: RallyColors.primaryBackground,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hóa đơn'),
        backgroundColor: RallyColors.primaryBackground,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Store Information Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: RallyColors.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Thông tin cửa hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: 'Tên cửa hàng',
                      hintText: 'VD: Quán cà phê ABC',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _storeAddressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ',
                      hintText: 'VD: 123 Đường ABC, Quận XYZ, TP.HCM',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _storePhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'VD: 0123456789',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // QR Code Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: RallyColors.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'QR Code chuyển khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'QR code này sẽ được in trên hóa đơn để khách hàng quét chuyển khoản',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasQrCode && _qrCodeImage != null)
                    Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _qrCodeImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickQrCodeImage,
                              icon: const Icon(Icons.edit),
                              label: const Text('Đổi hình'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RallyColors.buttonColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _removeQrCodeImage,
                              icon: const Icon(Icons.delete),
                              label: const Text('Xóa'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _pickQrCodeImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Chọn QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RallyColors.buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


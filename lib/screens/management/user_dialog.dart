import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserDialog extends StatefulWidget {
  final User? user; // null = create mode, not null = edit mode

  const UserDialog({Key? key, this.user}) : super(key: key);

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'STAFF';
  bool _isSubmitting = false;

  bool get isEditMode => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _usernameController.text = widget.user!.username;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (isEditMode) {
        // Update user
        await UserService.update(
          widget.user!.id,
          password: _passwordController.text.isEmpty ? null : _passwordController.text,
          role: _selectedRole,
        );
      } else {
        // Create user
        await UserService.create(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Đã cập nhật user' : 'Đã tạo user mới'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditMode ? 'Sửa User' : 'Thêm User Mới'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !isEditMode, // Cannot change username
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEditMode ? 'Mật khẩu mới (để trống nếu không đổi)' : 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (!isEditMode && (value == null || value.isEmpty)) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Mật khẩu phải ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: const [
                  DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditMode ? 'Cập nhật' : 'Tạo'),
        ),
      ],
    );
  }
}

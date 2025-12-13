import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  double _totalRevenue = 0;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get all completed sessions
      final response = await ApiService.get('/table-sessions/completed');
      final data = ApiService.handleResponse(response);
      
      setState(() {
        _sessions = data as List;
        _calculateTotal();
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

  void _calculateTotal() {
    _totalRevenue = _sessions.fold(0.0, (sum, session) {
      final hourlyCharge = (session['hourlyCharge'] ?? 0).toDouble();
      return sum + hourlyCharge;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        // Filter sessions by date range
        // TODO: Implement date filtering
      });
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}đ';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BÁO CÁO DOANH THU'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Chọn khoảng thời gian',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Revenue Summary Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'TỔNG DOANH THU',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(_totalRevenue),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tổng số phiên: ${_sessions.length}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Sessions List
                Expanded(
                  child: _sessions.isEmpty
                      ? const Center(
                          child: Text('Chưa có dữ liệu'),
                        )
                      : ListView.builder(
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            final tableName = session['table']?['name'] ?? 'N/A';
                            final startTime = _formatDateTime(session['startTime']);
                            final endTime = _formatDateTime(session['endTime']);
                            final totalHours = (session['totalHours'] ?? 0).toDouble();
                            final hourlyCharge = (session['hourlyCharge'] ?? 0).toDouble();
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(tableName),
                                ),
                                title: Text(
                                  'Bàn $tableName',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bắt đầu: $startTime'),
                                    Text('Kết thúc: $endTime'),
                                    Text('Thời gian: ${totalHours.toStringAsFixed(2)} giờ'),
                                  ],
                                ),
                                trailing: Text(
                                  _formatCurrency(hourlyCharge),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

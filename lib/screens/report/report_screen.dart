import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

enum DateFilterType {
  today,
  week,
  month,
  year,
  custom,
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTimeRange? _customDateRange;
  
  // Statistics
  double _totalTableRevenue = 0; // Tiền bàn
  double _totalFoodRevenue = 0; // Tiền món ăn
  double _totalRevenue = 0; // Tổng
  int _totalSessions = 0;
  double _totalHours = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTimeRange _getDateRangeForFilter(DateFilterType filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (filter) {
      case DateFilterType.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        );
      case DateFilterType.week:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: startOfWeek,
          end: now,
        );
      case DateFilterType.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case DateFilterType.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case DateFilterType.custom:
        return _customDateRange ?? DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        );
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dateRange = _getDateRangeForFilter(_selectedFilter);
      final startDate = dateRange.start.toIso8601String().split('T')[0];
      final endDate = dateRange.end.toIso8601String().split('T')[0];
      
      final response = await ApiService.get(
        '/table-sessions/completed?startDate=$startDate&endDate=$endDate'
      );
      final data = ApiService.handleResponse(response);
      
      setState(() {
        _sessions = data as List;
        _calculateStatistics();
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

  void _calculateStatistics() {
    _totalTableRevenue = 0;
    _totalFoodRevenue = 0;
    _totalSessions = _sessions.length;
    _totalHours = 0;

    for (var session in _sessions) {
      // Tiền bàn
      final hourlyCharge = (session['hourlyCharge'] ?? 0).toDouble();
      _totalTableRevenue += hourlyCharge;
      
      // Tổng giờ
      final totalHours = (session['totalHours'] ?? 0).toDouble();
      _totalHours += totalHours;
      
      // Tiền món ăn từ orders
      final orders = session['orders'] as List? ?? [];
      for (var order in orders) {
        final items = order['items'] as List? ?? [];
        for (var item in items) {
          final quantity = (item['quantity'] ?? 0) as int;
          final price = (item['price'] ?? 0.0) as num;
          _totalFoodRevenue += quantity * price.toDouble();
        }
      }
    }
    
    _totalRevenue = _totalTableRevenue + _totalFoodRevenue;
  }

  Future<void> _selectCustomDateRange() async {
    // Open date picker first (don't set filter or load data yet)
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    
    // Only set filter and load data if user selected a date range
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = DateFilterType.custom;
      });
      _loadData();
    }
    // If user cancelled, do nothing (keep current filter and data)
  }

  void _selectFilter(DateFilterType filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter != DateFilterType.custom) {
        _customDateRange = null;
      }
    });
    _loadData();
  }

  String _getFilterLabel(DateFilterType filter) {
    switch (filter) {
      case DateFilterType.today:
        return 'Hôm nay';
      case DateFilterType.week:
        return 'Tuần này';
      case DateFilterType.month:
        return 'Tháng này';
      case DateFilterType.year:
        return 'Năm này';
      case DateFilterType.custom:
        if (_customDateRange != null) {
          final start = DateFormat('dd/MM/yyyy').format(_customDateRange!.start);
          final end = DateFormat('dd/MM/yyyy').format(_customDateRange!.end);
          return '$start - $end';
        }
        return 'Tùy chọn';
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
        title: const Text('Báo cáo doanh thu'),
        actions: [
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
                // Date Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn khoảng thời gian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick filter buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterButton(
                            'Hôm nay',
                            DateFilterType.today,
                            Icons.today,
                          ),
                          _buildFilterButton(
                            'Tuần này',
                            DateFilterType.week,
                            Icons.view_week,
                          ),
                          _buildFilterButton(
                            'Tháng này',
                            DateFilterType.month,
                            Icons.calendar_month,
                          ),
                          _buildFilterButton(
                            'Năm này',
                            DateFilterType.year,
                            Icons.calendar_today,
                          ),
                          _buildCustomFilterButton(),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Statistics Cards
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Total Revenue Card
                        _buildStatCard(
                          'Tổng doanh thu',
                          _formatCurrency(_totalRevenue),
                          Colors.green,
                          Icons.attach_money,
                        ),
                        const SizedBox(height: 16),
                        
                        // Statistics Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Tiền bàn',
                                _formatCurrency(_totalTableRevenue),
                                Colors.blue,
                                Icons.table_restaurant,
                                isSmall: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Tiền món ăn',
                                _formatCurrency(_totalFoodRevenue),
                                Colors.orange,
                                Icons.restaurant,
                                isSmall: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Số phiên',
                                '$_totalSessions',
                                Colors.purple,
                                Icons.event,
                                isSmall: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Tổng giờ',
                                '${_totalHours.toStringAsFixed(1)}h',
                                Colors.teal,
                                Icons.access_time,
                                isSmall: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Sessions List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chi tiết phiên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_sessions.length} phiên',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Sessions List
                        _sessions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Chưa có dữ liệu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sessions.length,
                                itemBuilder: (context, index) {
                                  return _buildSessionCard(_sessions[index]);
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(
    String label,
    DateFilterType filter, [
    IconData? icon,
  ]) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => _selectFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFilterButton() {
    final isSelected = _selectedFilter == DateFilterType.custom;
    return InkWell(
      onTap: _selectCustomDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              _getFilterLabel(DateFilterType.custom),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isSmall = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final tableName = session['table']?['name'] ?? 'N/A';
    final startTime = _formatDateTime(session['startTime']);
    final endTime = _formatDateTime(session['endTime']);
    final totalHours = (session['totalHours'] ?? 0).toDouble();
    final hourlyCharge = (session['hourlyCharge'] ?? 0).toDouble();
    final orders = session['orders'] as List? ?? [];
    
    // Calculate food revenue for this session
    double foodRevenue = 0;
    int totalItems = 0;
    for (var order in orders) {
      final items = order['items'] as List? ?? [];
      for (var item in items) {
        final quantity = (item['quantity'] ?? 0) as int;
        final price = (item['price'] ?? 0.0) as num;
        foodRevenue += quantity * price.toDouble();
        totalItems += quantity;
      }
    }
    
    final sessionTotal = hourlyCharge + foodRevenue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(
            Icons.table_restaurant,
            color: Colors.blue.shade700,
          ),
        ),
        title: Text(
          'Bàn $tableName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy').format(DateTime.parse(session['endTime'] ?? session['startTime']))} • ${totalHours.toStringAsFixed(1)}h',
        ),
        trailing: Text(
          _formatCurrency(sessionTotal),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Giờ vào', startTime),
                _buildInfoRow('Giờ ra', endTime),
                _buildInfoRow('Thời gian', '${totalHours.toStringAsFixed(2)} giờ'),
                const Divider(),
                _buildInfoRow('Tiền bàn', _formatCurrency(hourlyCharge)),
                if (foodRevenue > 0) ...[
                  _buildInfoRow('Tiền món ăn', _formatCurrency(foodRevenue)),
                  _buildInfoRow('Số món', '$totalItems món'),
                ],
                const Divider(),
                _buildInfoRow(
                  'Tổng cộng',
                  _formatCurrency(sessionTotal),
                  isBold: true,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

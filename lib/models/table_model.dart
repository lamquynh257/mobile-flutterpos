class TableModel {
  final int id;
  final int floorId;
  final String name;
  final double x;
  final double y;
  final double hourlyRate;
  final String status; // EMPTY, RESERVED, OCCUPIED
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Active session info (if any)
  final TableSession? activeSession;

  TableModel({
    required this.id,
    required this.floorId,
    required this.name,
    required this.x,
    required this.y,
    required this.hourlyRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.activeSession,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as int,
      floorId: json['floorId'] as int,
      name: json['name'] as String,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'EMPTY',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      activeSession: json['sessions'] != null && (json['sessions'] as List).isNotEmpty
          ? TableSession.fromJson(json['sessions'][0] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floorId': floorId,
      'name': name,
      'x': x,
      'y': y,
      'hourlyRate': hourlyRate,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // Check if table is occupied
  bool get isOccupied => status == 'OCCUPIED';
  
  // Get elapsed time if session is active
  Duration? get elapsedTime {
    if (activeSession == null) return null;
    return DateTime.now().difference(activeSession!.startTime);
  }
  
  // Calculate current hourly charge
  double get currentHourlyCharge {
    final elapsed = elapsedTime;
    if (elapsed == null) return 0;
    final hours = elapsed.inMinutes / 60.0;
    return hours * hourlyRate;
  }
}

class TableSession {
  final int id;
  final int? tableId;  // Make nullable
  final DateTime startTime;
  final DateTime? endTime;
  final double? totalHours;
  final double? hourlyCharge;

  TableSession({
    required this.id,
    this.tableId,  // No longer required
    required this.startTime,
    this.endTime,
    this.totalHours,
    this.hourlyCharge,
  });

  factory TableSession.fromJson(Map<String, dynamic> json) {
    return TableSession(
      id: json['id'] as int,
      tableId: json['tableId'] as int?,  // Nullable
      startTime: DateTime.parse(json['startTime'] as String), // Parse as local time
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      totalHours: json['totalHours'] != null ? (json['totalHours'] as num).toDouble() : null,
      hourlyCharge: json['hourlyCharge'] != null ? (json['hourlyCharge'] as num).toDouble() : null,
    );
  }
}

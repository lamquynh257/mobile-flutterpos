class Floor {
  final int id;
  final String name;
  final int order;

  Floor({
    required this.id,
    required this.name,
    required this.order,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'],
      name: json['name'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
    };
  }
}

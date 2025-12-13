class Dish {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final String? description;
  final bool available;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Dish({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.description,
    required this.available,
    this.createdAt,
    this.updatedAt,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      available: json['available'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'available': available,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

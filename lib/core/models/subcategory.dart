class Subcategory {
  final String id;
  final String categoryId;
  final String propertyId;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.propertyId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> j) => Subcategory(
    id: j['id'] as String,
    categoryId: j['category_id'] as String,
    propertyId: j['property_id'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

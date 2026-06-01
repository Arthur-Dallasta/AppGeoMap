





class Category {
  final String id;           
  final String key;          
  final String name;         
  final String color;        
  final String? description; 
  final DateTime createdAt;  

  const Category({
    required this.id,
    required this.key,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
  });

  
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        key: j['key'] as String,
        name: j['name'] as String,
        color: j['color'] as String,
        description: j['description'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

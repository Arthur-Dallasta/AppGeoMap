







class AreaProperties {
  final String id;              
  final String type;            
  final String? categoryId;     
  final String? categoryColor;  
  final String? categoryName;   
  final String? subcategoryId;  
  final String? subcategoryName;

  const AreaProperties({
    required this.id,
    required this.type,
    this.categoryId,
    this.categoryColor,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
  });

  factory AreaProperties.fromJson(Map<String, dynamic> j) => AreaProperties(
        id: j['id'] as String,
        type: j['type'] as String,
        categoryId: j['category_id'] as String?,
        categoryColor: j['category_color'] as String?,
        categoryName: j['category_name'] as String?,
        subcategoryId: j['subcategory_id'] as String?,
        subcategoryName: j['subcategory_name'] as String?,
      );
}



class AreaFeature {
  final Map<String, dynamic> geometry; 
  final AreaProperties properties;     

  const AreaFeature({required this.geometry, required this.properties});

  factory AreaFeature.fromJson(Map<String, dynamic> j) => AreaFeature(
        geometry: j['geometry'] as Map<String, dynamic>,
        properties: AreaProperties.fromJson(j['properties'] as Map<String, dynamic>),
      );
}




class AreaListResponse {
  final AreaFeature? boundary;      
  final List<AreaFeature> internal; 

  const AreaListResponse({this.boundary, required this.internal});

  factory AreaListResponse.fromJson(Map<String, dynamic> j) => AreaListResponse(
        boundary: j['boundary'] != null
            ? AreaFeature.fromJson(j['boundary'] as Map<String, dynamic>)
            : null,
        internal: (j['internal'] as List)
            .map((e) => AreaFeature.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get isEmpty => boundary == null && internal.isEmpty;
}

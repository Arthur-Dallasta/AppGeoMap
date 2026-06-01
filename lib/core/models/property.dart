



class Property {
  final String id;              
  final String name;            
  final String location;        
  final String municipality;    
  final String state;           
  final String zipCode;         
  final double totalAreaHa;     
  final double ownAreaHa;       
  final double leasedAreaHa;    
  final double protectedAreaHa; 
  final int peopleCount;        
  final double cropAreaHa;      
  final String userId;          
  final DateTime createdAt;     
  final DateTime updatedAt;     

  const Property({
    required this.id,
    required this.name,
    required this.location,
    required this.municipality,
    required this.state,
    required this.zipCode,
    required this.totalAreaHa,
    required this.ownAreaHa,
    required this.leasedAreaHa,
    required this.protectedAreaHa,
    required this.peopleCount,
    required this.cropAreaHa,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  
  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.parse(v.toString());

  static int _i(dynamic v) =>
      v is int ? v : int.parse(v.toString());

  factory Property.fromJson(Map<String, dynamic> j) => Property(
        id: j['id'] as String,
        name: j['name'] as String,
        location: j['location'] as String,
        municipality: j['municipality'] as String,
        state: j['state'] as String,
        zipCode: j['zip_code'] as String,
        totalAreaHa: _d(j['total_area_ha']),
        ownAreaHa: _d(j['own_area_ha']),
        leasedAreaHa: _d(j['leased_area_ha']),
        protectedAreaHa: _d(j['protected_area_ha']),
        peopleCount: _i(j['people_count']),
        cropAreaHa: _d(j['crop_area_ha']),
        userId: j['user_id'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

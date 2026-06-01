

class User {
  final int? id;        
  final String name;    
  final String email;   
  final String? phone;  
  final String? lastName; 

  User({this.id, required this.name, required this.email, this.phone, this.lastName});

  
  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        lastName: map['last_name'], 
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'last_name': lastName,
      };
}

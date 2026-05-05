class User{
  final int? id;
  final String name;
  final String email;
  final String? image;


  User({required this.id, required this.name, required this.email, this.image,});
  
  factory User.fomJson(Map<String,dynamic> json){
    return User(id: json['id'], name: json['name'], email: json['email'], image: json['image']);
  }
}
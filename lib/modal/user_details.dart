import 'package:edu_gym/api/api.dart';

class UserDetails{
  static int? id;
  static bool? isLoggedIn;
  final String? email;
  final String? name;
  final String? image;
  final String? ip;
  final String? gender;
  final String? bio;



  UserDetails.fromJson(Map<String,dynamic> json):
        email=json['email'],
        name=json['name'],
        image=json['image'] != null && json['image'].toString().isNotEmpty
            ? "${Api.imgBaseUrl}/${json['image']}"
            : null,
        ip=json['ip_address'],
        gender=json['gender'],
        bio=json['bio'];
}

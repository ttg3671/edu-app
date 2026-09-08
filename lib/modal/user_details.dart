import 'package:edu_gym/api/api.dart';
import 'subscription_details.dart';

class UserDetails {
  final String email;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final int isSubscribed;
  final int isReviewer;
  final bool emailVerified;
  final SubscriptionDetails? subscriptionDetails;

  UserDetails({
    required this.email,
    this.name,
    this.bio,
    this.avatarUrl,
    required this.isSubscribed,
    required this.isReviewer,
    this.emailVerified = true,
    this.subscriptionDetails,
  });

  String get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return '';
    if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
      return avatarUrl!;
    }
    final cleanPath = avatarUrl!.startsWith('/') ? avatarUrl!.substring(1) : avatarUrl!;
    final base = Api.imgBaseUrl.endsWith('/')
        ? Api.imgBaseUrl.substring(0, Api.imgBaseUrl.length - 1)
        : Api.imgBaseUrl;
    return '$base/$cleanPath';
  }

  factory UserDetails.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json = (rawJson['user'] is Map)
        ? Map<String, dynamic>.from(rawJson['user'])
        : rawJson;

    final dynamic subJson = json['subscription_details'] ??
        json['subscription'] ??
        json['sub_details'] ??
        json['subscriptionDetails'];

    SubscriptionDetails? sub;
    if (subJson is Map) {
      final Map<String, dynamic> subMap = Map<String, dynamic>.from(subJson);
      if (subMap['max_devices'] == null && json['max_devices'] != null) {
        subMap['max_devices'] = json['max_devices'];
      }
      sub = SubscriptionDetails.fromJson(subMap);
    } else if (json['max_devices'] != null || json['plan'] != null) {
      sub = SubscriptionDetails.fromJson(json);
    }

    return UserDetails(
      email: json['email'] ?? '',
      name: json['profile_name'] ?? json['name'],
      bio: json['profile_bio'] ?? json['bio'],
      avatarUrl: json['avatar_url'] ?? json['profile_image'] ?? json['image'] ?? json['avatarUrl'],
      isSubscribed: json['is_subscribed'] is int
          ? json['is_subscribed']
          : (json['is_subscribed'] == true || json['is_subscribed'] == '1' ? 1 : 0),
      isReviewer: json['is_reviewer'] is int
          ? json['is_reviewer']
          : (json['is_reviewer'] == true || json['is_reviewer'] == '1' ? 1 : 0),
      emailVerified: json['email_verified'] == true || json['email_verified'] == 1,
      subscriptionDetails: sub,
    );
  }

  UserDetails copyWith({
    String? email,
    String? name,
    String? bio,
    String? avatarUrl,
    int? isSubscribed,
    int? isReviewer,
    bool? emailVerified,
    SubscriptionDetails? subscriptionDetails,
  }) {
    return UserDetails(
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isReviewer: isReviewer ?? this.isReviewer,
      emailVerified: emailVerified ?? this.emailVerified,
      subscriptionDetails: subscriptionDetails ?? this.subscriptionDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'profile_name': name,
      'profile_bio': bio,
      'name': name,
      'bio': bio,
      'avatar_url': avatarUrl,
      'is_subscribed': isSubscribed,
      'is_reviewer': isReviewer,
      'email_verified': emailVerified,
      'subscription_details': subscriptionDetails?.toJson(),
      'max_devices': subscriptionDetails?.maxDevices,
    };
  }
}

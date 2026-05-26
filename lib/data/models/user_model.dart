import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final String role;

  @HiveField(5)
  final bool isVerified;

  @HiveField(6)
  final String? fcmToken;

  @HiveField(7)
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.role = 'patient',
    this.isVerified = false,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'patient',
      isVerified: json['isVerified'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : json['createdAt'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'isVerified': isVerified,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? role,
    bool? isVerified,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName)';
}

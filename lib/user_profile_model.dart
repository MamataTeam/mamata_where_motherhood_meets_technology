import 'dart:core';

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? firstDayOfLastPeriod;
  final String? dueDate;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.firstDayOfLastPeriod,
    this.dueDate,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      fullName:
          json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      firstDayOfLastPeriod: json['first_day_of_last_period'] as String? ??
          json['firstDayOfLastPeriod'] as String?,
      dueDate: json['due_date'] as String? ?? json['dueDate'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ??
          json['createdAt'] as String? ??
          DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ??
          json['updatedAt'] as String? ??
          DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'first_day_of_last_period': firstDayOfLastPeriod,
      'due_date': dueDate,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

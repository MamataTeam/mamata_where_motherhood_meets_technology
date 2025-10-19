class Hospital {
  final String name;
  final String address;
  final String phone;
  final String type;
  final List<String> specialties;
  final String? website;
  final bool emergency;
  final double latitude;
  final double longitude;
  double? distance; // Optional – calculated dynamically

  Hospital({
    required this.name,
    required this.address,
    required this.phone,
    required this.type,
    required this.specialties,
    this.website,
    required this.emergency,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      name: json['name'],
      address: json['address'],
      phone: json['phone'] is List
          ? (json['phone'] as List).join(", ")
          : json['phone'],
      type: json['type'],
      specialties: List<String>.from(json['specialties']),
      website: json['website'],
      emergency: json['emergency']?.toString().toLowerCase() == 'yes',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

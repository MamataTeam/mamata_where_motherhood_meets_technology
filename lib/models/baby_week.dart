class BabyWeek {
  final int week;
  final String comparison;
  final double weightGrams;
  final double heightCm;
  final String heartRateBpm;
  final String hcgRange;
  final String imageUrl;

  BabyWeek({
    required this.week,
    required this.comparison,
    required this.weightGrams,
    required this.heightCm,
    required this.heartRateBpm,
    required this.hcgRange,
    required this.imageUrl,
  });

  factory BabyWeek.fromJson(Map<String, dynamic> json) {
    return BabyWeek(
      week: json['week'] as int,
      comparison: json['comparison'] as String,
      weightGrams: (json['weight_grams'] as num).toDouble(),
      heightCm: (json['height_cm'] as num).toDouble(),
      heartRateBpm: json['heart_rate_bpm'] as String,
      hcgRange: json['hcg_range'] as String,
      imageUrl: json['image_url'] as String,
    );
  }
}
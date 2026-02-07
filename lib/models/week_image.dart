class WeekImage {
  final int week;
  final String imageUrl;

  WeekImage({
    required this.week,
    required this.imageUrl,
  });

  factory WeekImage.fromJson(Map<String, dynamic> json) {
    return WeekImage(
      week: json['week'] as int,
      imageUrl: json['image_url'] as String,
    );
  }
}
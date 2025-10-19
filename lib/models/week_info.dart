class WeekInfo {
  final int week;
  final String imageUrl;
  final String baby;
  final String mom;
  final String helpfulTips;

  WeekInfo({
    required this.week,
    required this.imageUrl,
    required this.baby,
    required this.mom,
    required this.helpfulTips,
  });

  factory WeekInfo.fromJson(Map<String, dynamic> json) {
    return WeekInfo(
      week: json['week'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      baby: json['baby'] ?? '',
      mom: json['mom'] ?? '',
      helpfulTips: json['helpful_tips'] ?? '',
    );
  }
}

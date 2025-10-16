class FoodItem {
  final String food;
  final String localName;
  final String? reason;

  FoodItem({
    required this.food,
    required this.localName,
    this.reason,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      food: json['food'] as String? ?? '',
      localName: json['localName'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }
}

class FoodCategory {
  final String name;
  final List<FoodItem> items;

  FoodCategory({
    required this.name,
    required this.items,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      name: json['name'] as String? ?? '',
      items: (json['items'] as List?)
              ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TrimesterNutrition {
  final int trimesterNumber;
  final String name;
  final String weeks;
  final String focus;
  final List<FoodCategory> categories;
  final List<FoodItem> foodsToAvoid;

  TrimesterNutrition({
    required this.trimesterNumber,
    required this.name,
    required this.weeks,
    required this.focus,
    required this.categories,
    required this.foodsToAvoid,
  });

  factory TrimesterNutrition.fromJson(Map<String, dynamic> json) {
    return TrimesterNutrition(
      trimesterNumber: json['trimesterNumber'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      weeks: json['weeks'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      categories: (json['categories'] as List?)
              ?.map((e) => FoodCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      foodsToAvoid: (json['foodsToAvoid'] as List?)
              ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SafetyItem {
  final String item;
  final String reason;

  SafetyItem({
    required this.item,
    required this.reason,
  });

  factory SafetyItem.fromJson(Map<String, dynamic> json) {
    return SafetyItem(
      item: json['item'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}

class GeneralSafety {
  final String name;
  final List<SafetyItem> items;

  GeneralSafety({
    required this.name,
    required this.items,
  });

  factory GeneralSafety.fromJson(Map<String, dynamic> json) {
    return GeneralSafety(
      name: json['name'] as String? ?? '',
      items: (json['items'] as List?)
              ?.map((e) => SafetyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PregnancyNutritionData {
  final String title;
  final String description;
  final List<TrimesterNutrition> trimesters;
  final GeneralSafety generalSafety;

  PregnancyNutritionData({
    required this.title,
    required this.description,
    required this.trimesters,
    required this.generalSafety,
  });

  factory PregnancyNutritionData.fromJson(Map<String, dynamic> json) {
    final guide = json['pregnancyNutritionGuide'] as Map<String, dynamic>? ?? {};
    
    return PregnancyNutritionData(
      title: guide['title'] as String? ?? '',
      description: guide['description'] as String? ?? '',
      trimesters: (guide['trimesters'] as List?)
              ?.map((e) => TrimesterNutrition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generalSafety: GeneralSafety.fromJson(
          guide['generalSafety'] as Map<String, dynamic>? ?? {}),
    );
  }

  TrimesterNutrition? get firstTrimester =>
      trimesters.firstWhere((t) => t.trimesterNumber == 1);
  
  TrimesterNutrition? get secondTrimester =>
      trimesters.firstWhere((t) => t.trimesterNumber == 2);
  
  TrimesterNutrition? get thirdTrimester =>
      trimesters.firstWhere((t) => t.trimesterNumber == 3);
}
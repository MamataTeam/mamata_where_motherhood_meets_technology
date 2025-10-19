class Exercise {
  final String id;
  final String name;
  final String duration;
  final String description;
  final List<String> benefits;
  final List<String> steps;
  final List<String> precautions;
  final List<String> tips;
  final String youtubeUrl;
  final String videoTitle;
  final String videoDuration;
  final Map<String, String> trimesterModifications;

  Exercise({
    required this.id,
    required this.name,
    required this.duration,
    required this.description,
    required this.benefits,
    required this.steps,
    required this.precautions,
    required this.tips,
    required this.youtubeUrl,
    required this.videoTitle,
    required this.videoDuration,
    required this.trimesterModifications,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: (json['id'] as String?) ?? 'N/A',
      name: (json['name'] as String?) ?? 'Untitled Exercise',
      duration: (json['duration'] as String?) ?? 'N/A',
      description:
          (json['description'] as String?) ?? 'No description provided.',
      benefits: List<String>.from((json['benefits'] as List?) ?? []),
      steps: List<String>.from((json['steps'] as List?) ?? []),
      precautions: List<String>.from((json['precautions'] as List?) ?? []),
      tips: List<String>.from((json['tips'] as List?) ?? []),
      youtubeUrl: (json['youtubeUrl'] as String?) ?? '',
      videoTitle: (json['videoTitle'] as String?) ?? 'Video Not Available',
      videoDuration: (json['videoDuration'] as String?) ?? 'N/A',
      trimesterModifications: Map<String, String>.from(
          (json['trimesterModifications'] as Map?) ?? {}),
    );
  }
}

class PregnancyExerciseData {
  final List<Exercise> firstTrimester;
  final List<Exercise> secondTrimester;
  final List<Exercise> thirdTrimester;

  PregnancyExerciseData({
    required this.firstTrimester,
    required this.secondTrimester,
    required this.thirdTrimester,
  });

  factory PregnancyExerciseData.fromJson(Map<String, dynamic> json) {
    // Map directly to Exercise.fromJson
    return PregnancyExerciseData(
      firstTrimester: (json['first_trimester'] as List?)
              ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      secondTrimester: (json['second_trimester'] as List?)
              ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      thirdTrimester: (json['third_trimester'] as List?)
              ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

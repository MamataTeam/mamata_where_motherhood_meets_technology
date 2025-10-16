import 'package:flutter/material.dart';
import 'exercise_detail_page.dart';
import '../models/exercise_model.dart';
import '../services/exercise_service.dart';

class PregnancyExerciseScreen extends StatefulWidget {
  const PregnancyExerciseScreen({super.key});

  @override
  State<PregnancyExerciseScreen> createState() =>
      _PregnancyExerciseScreenState();
}

class _PregnancyExerciseScreenState extends State<PregnancyExerciseScreen> {
  PregnancyExerciseData? _exerciseData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final data = await ExerciseService.loadExercises();
      setState(() {
        _exerciseData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getEmojiForExercise(String name) {
    name = name.toLowerCase();

    // Walking
    if (name.contains('walking')) return '🚶🏼‍♀️';

    // Cycling/Aerobics
    if (name.contains('cycling')) return '🚲';
    if (name.contains('aerobics')) return '💃🏻';

    // Swimming
    if (name.contains('swim')) return '🏊';

    // Strength Training
    if (name.contains('squats') || name.contains('weightlifting')) return '🏋️';

    // Core/Plank (Full-body core tension)
    if (name.contains('plank')) return '🤸';

    // Core/Stability (Use ball emoji for stability exercises)
    if (name.contains('stability')) return '🔮';

    // Calisthenics
    if (name.contains('pushups')) return '💪';

    // Mind/Body
    if (name.contains('yoga')) return '🧘‍♀️';

    // Default fallback
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8D5F2),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 60, color: Colors.red),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load exercises',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _error = null;
                                    });
                                    _loadExercises();
                                  },
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              _buildTrimesterSection(
                                context: context,
                                trimesterNumber: '1',
                                title: 'First Trimester',
                                weeks: 'Weeks 1-12',
                                color: Color(0xFF667EEA),
                                exercises: _exerciseData!.firstTrimester,
                              ),
                              const SizedBox(height: 20),
                              _buildTrimesterSection(
                                context: context,
                                trimesterNumber: '2',
                                title: 'Second Trimester',
                                weeks: 'Weeks 13-27',
                                color: Color(0xFF764BA2),
                                exercises: _exerciseData!.secondTrimester,
                              ),
                              const SizedBox(height: 20),
                              _buildTrimesterSection(
                                context: context,
                                trimesterNumber: '3',
                                title: 'Third Trimester',
                                weeks: 'Weeks 28-40',
                                color: Color(0xFFE77E7E),
                                exercises: _exerciseData!.thirdTrimester,
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    _buildPrecautionsSection(),
                                    const SizedBox(height: 16),
                                    _buildGeneralTipsSection(),
                                    const SizedBox(height: 16),
                                    _buildExerciseDisclaimer(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: 50,
        left: 20,
        right: 30,
        bottom: 30,
      ),
      child: Column(
        children: [
          Text(
            ' Pregnancy Exercise Guide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Safe exercises for each trimester',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.95),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrimesterSection({
    required BuildContext context,
    required String trimesterNumber,
    required String title,
    required String weeks,
    required Color color,
    required List<Exercise> exercises, 
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      trimesterNumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        weeks,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseCard(context, exercise, color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, Exercise exercise, Color color) {
    final emoji = _getEmojiForExercise(exercise.name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailPage(
              exercise: exercise,
              categoryEmoji: emoji,
              categoryColor: color,
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                exercise.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Content section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            exercise.duration,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Focus',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF718096),
                                  letterSpacing: 0.5,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            exercise.description.length > 80
                                ? '${exercise.description.substring(0, 80)}...'
                                : exercise.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4A5568),
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (exercise.benefits.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Key Benefit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF718096),
                                    letterSpacing: 0.5,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              exercise.benefits.first.length > 60
                                  ? '${exercise.benefits.first.substring(0, 60)}...'
                                  : exercise.benefits.first,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A5568),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecautionsSection() {
    final precautions = [
      'Stop if experiencing pain or discomfort',
      'Avoid lying flat on back after 1st trimester',
      'Stay hydrated during exercise',
      'Avoid high-impact activities',
      'Do not hold breath during exercises',
      'Wear comfortable, loose clothing',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFF5F5),
        border: Border.all(color: Color(0xFFFEB2B2), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '⚠️',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Important Precautions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC53030),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...precautions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        color: Color(0xFFC53030),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGeneralTipsSection() {
    final tips = [
      'Start slowly and gradually increase intensity',
      'Aim for 150 minutes of moderate activity per week',
      'Include warm-up and cool-down (5 minutes each)',
      'Practice breathing techniques from yoga',
      'Listen to your body and rest when needed',
      'Exercise in cool environment',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF0FFF4),
        border: Border.all(color: Color(0xFF9AE6B4), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '💡',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'General Tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF22543D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '→',
                      style: TextStyle(
                        color: Color(0xFF48BB78),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2F855A),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExerciseDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Color(0xFF4299E1), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚕️',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, color: Color(0xFF2D3748)),
                children: [
                  TextSpan(
                    text: 'Medical Disclaimer: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  TextSpan(
                    text:
                        'These exercises are general guidelines. Always consult your healthcare provider or physiotherapist before starting any exercise program during pregnancy.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

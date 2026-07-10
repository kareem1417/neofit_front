import 'dart:typed_data';

class ProgramBuilderData {
  String title = '';
  String description = '';

  int? sportId;
  String sportName = 'Boxing';

  String goal = 'strength';
  String level = 'amateur';

  String duration = '6';
  String frequency = '3';

  String? coverImageUrl;
  Uint8List? descriptionImageBytes;

  String? coachName;
  Uint8List? coachImageBytes;

  List<ProgramBlockData> blocks = [];

  Map<String, dynamic> toApiPayload({bool publish = true}) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'sport_id': sportId,
      'goal_primary': goal.toLowerCase(),
      'level_target': level.toLowerCase(),
      'duration_weeks': int.tryParse(duration) ?? 0,
      'sessions_per_week': int.tryParse(frequency) ?? 0,
      'is_published': publish,
      if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty)
        'cover_image': coverImageUrl!.trim(),
      'program_blocks': blocks.asMap().entries.map((entry) {
        final index = entry.key;
        final block = entry.value;

        return {
          'name': block.title.trim().isEmpty ? 'Untitled Block' : block.title,
          'description': '',
          'order_index': index + 1,
          'week_start': block.weekStart,
          'week_end': block.weekEnd,
          'program_sessions':
              block.sessions.asMap().entries.map((sessionEntry) {
            final sessionIndex = sessionEntry.key;
            final session = sessionEntry.value;

            return {
              'name': session.title.trim().isEmpty
                  ? 'Untitled Session'
                  : session.title,
              'description': session.focus,
              'day_offset': sessionIndex,
              'estimated_duration_minutes': session.estimatedDurationMinutes,
              'session_exercises':
                  session.exercises.asMap().entries.map((exerciseEntry) {
                final exerciseIndex = exerciseEntry.key;
                final exercise = exerciseEntry.value;

                return {
                  'exercise_name': exercise.title.trim().isEmpty
                      ? 'Exercise'
                      : exercise.title,
                  'sets': exercise.sets,
                  'reps': exercise.reps,
                  'rest_seconds': exercise.restSeconds,
                  'intensity_note': exercise.intensityNote.trim().isEmpty
                      ? null
                      : exercise.intensityNote,
                  'notes':
                      exercise.notes.trim().isEmpty ? null : exercise.notes,
                  'order_index': exerciseIndex + 1,
                };
              }).toList(),
            };
          }).toList(),
        };
      }).toList(),
    };
  }
}

class ProgramBlockData {
  String title;
  int weekStart;
  int weekEnd;
  List<ProgramSessionData> sessions = [];

  ProgramBlockData({
    required this.title,
    required this.weekStart,
    required this.weekEnd,
    List<ProgramSessionData>? sessions,
  }) {
    if (sessions != null) {
      this.sessions = sessions;
    }
  }

  String get weeks => 'WEEKS $weekStart - $weekEnd';
}

class ProgramSessionData {
  String id;
  String title;
  String focus;
  int estimatedDurationMinutes;
  List<ProgramExerciseData> exercises = [];

  ProgramSessionData({
    required this.id,
    required this.title,
    required this.focus,
    this.estimatedDurationMinutes = 60,
    List<ProgramExerciseData>? exercises,
  }) {
    if (exercises != null) {
      this.exercises = exercises;
    }
  }
}

class ProgramExerciseData {
  String title;
  String icon;
  String notes;
  int sets;
  String reps;
  int restSeconds;
  String intensityNote;

  ProgramExerciseData({
    required this.title,
    this.icon = 'dumbbell',
    this.notes = '',
    this.sets = 0,
    this.reps = '0',
    this.restSeconds = 60,
    this.intensityNote = '',
  });

  String get details {
    var value = '$sets X $reps';
    if (intensityNote.trim().isNotEmpty) value += ' @ $intensityNote';
    value += ' • ${restSeconds}S REST';
    return value.toUpperCase();
  }
}

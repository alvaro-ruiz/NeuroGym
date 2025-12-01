import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:neuro_gym/screen/add_exercises.dart';
import 'package:neuro_gym/screen/active_workout_session.dart';

class RoutineDetailPage extends StatefulWidget {
  final String routineId;
  final String routineTitle;

  const RoutineDetailPage({
    super.key,
    required this.routineId,
    required this.routineTitle,
  });

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  List<Map<String, dynamic>> _routineDays = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutineDays();
  }

  Future<void> _loadRoutineDays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Cargando días de rutina: ${widget.routineId}');

      // Cargar solo los días de la rutina
      final daysResponse = await SupabaseConfig.client
          .from('routine_days')
          .select('id, day_order, title, notes, duration_minutes')
          .eq('routine_id', widget.routineId)
          .order('day_order', ascending: true);

      print('✅ Días cargados: ${daysResponse.length}');

      setState(() {
        _routineDays = List<Map<String, dynamic>>.from(daysResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar días: $e');
      setState(() {
        _errorMessage = 'Error al cargar días: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.routineTitle.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 24,
            shadows: [
              Shadow(
                color: Colors.orangeAccent.withOpacity(0.6),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Cargando días...",
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.montserrat(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _routineDays.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.orangeAccent.withOpacity(0.3),
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Esta rutina no tiene días",
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRoutineDays,
                      color: Colors.orangeAccent,
                      backgroundColor: Colors.black,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _routineDays.length,
                        itemBuilder: (context, index) {
                          final day = _routineDays[index];
                          return _buildDayCard(day);
                        },
                      ),
                    ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    return GestureDetector(
      onTap: () async {
        print('📅 Día seleccionado: ${day['id']}');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayExercisesPage(
              dayId: day['id'],
              dayTitle: day['title'] ?? 'Día ${day['day_order']}',
              routineId: widget.routineId,
            ),
          ),
        );

        // Si se agregaron ejercicios, puedes recargar aquí si es necesario
        if (result == true) {
          _loadRoutineDays();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Icon(
                _getDayIcon(day['title'] ?? ''),
                color: Colors.orangeAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 15),

            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                day['title'] ?? 'Día ${day['day_order']}',
                style: GoogleFonts.bebasNeue(
                  color: Colors.orangeAccent,
                  fontSize: 22,
                  shadows: [
                    Shadow(
                      color: Colors.orangeAccent.withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Duración
            if (day['duration_minutes'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '⏱️ ${day['duration_minutes']} min',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDayIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('pecho') || titleLower.contains('push')) {
      return Icons.fitness_center;
    } else if (titleLower.contains('espalda') || titleLower.contains('pull')) {
      return Icons.back_hand;
    } else if (titleLower.contains('pierna') || titleLower.contains('leg')) {
      return Icons.directions_run;
    } else if (titleLower.contains('brazo')) {
      return Icons.sports_martial_arts;
    } else if (titleLower.contains('hombro')) {
      return Icons.accessibility_new;
    } else {
      return Icons.calendar_today;
    }
  }
}

// Nueva pantalla para mostrar ejercicios del día
class DayExercisesPage extends StatefulWidget {
  final String dayId;
  final String dayTitle;
  final String routineId;

  const DayExercisesPage({
    super.key,
    required this.dayId,
    required this.dayTitle,
    required this.routineId,
  });

  @override
  State<DayExercisesPage> createState() => _DayExercisesPageState();
}

class _DayExercisesPageState extends State<DayExercisesPage> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Cargando ejercicios del día: ${widget.dayId}');

      final exercisesResponse = await SupabaseConfig.client
          .from('routine_exercises')
          .select('''
            id,
            exercise_order,
            sets,
            reps,
            target_weight,
            rest_seconds,
            tempo,
            notes,
            exercises (
              id,
              name,
              description,
              primary_muscle,
              equipment
            )
          ''')
          .eq('routine_day_id', widget.dayId)
          .order('exercise_order', ascending: true);

      print('✅ Ejercicios cargados: ${exercisesResponse.length}');

      setState(() {
        _exercises = List<Map<String, dynamic>>.from(exercisesResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar ejercicios: $e');
      setState(() {
        _errorMessage = 'Error al cargar ejercicios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTrainingSession(
          routineId: widget.routineId,
          routineDayId: widget.dayId,
          dayTitle: widget.dayTitle,
          exercises: _exercises,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.dayTitle.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 24,
            shadows: [
              Shadow(
                color: Colors.orangeAccent.withOpacity(0.6),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        centerTitle: true,
        // 🆕 BOTÓN AGREGAR EJERCICIOS
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExercisesToDayPage(
                    dayId: widget.dayId,
                    dayTitle: widget.dayTitle,
                  ),
                ),
              );

              if (result == true) {
                _loadExercises(); // Recargar lista de ejercicios
              }
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.orangeAccent,
              size: 28,
            ),
            tooltip: 'Agregar ejercicios',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Cargando ejercicios...",
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Lista de ejercicios
                Expanded(
                  child: _exercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: Colors.orangeAccent.withOpacity(0.3),
                                size: 80,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No hay ejercicios en este día",
                                style: GoogleFonts.montserrat(
                                  color: Colors.orangeAccent.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddExercisesToDayPage(
                                        dayId: widget.dayId,
                                        dayTitle: widget.dayTitle,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    _loadExercises();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar ejercicios'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _exercises[index];
                            return _buildExerciseCard(exercise, index);
                          },
                        ),
                ),

                // Botón fijo de iniciar entrenamiento
                if (_exercises.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.orangeAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _startWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 15,
                        shadowColor: Colors.orangeAccent.withOpacity(0.6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'INICIAR ENTRENAMIENTO',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final exerciseData = exercise['exercises'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número y nombre
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                      exerciseData['name'] ?? 'Ejercicio',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exerciseData['primary_muscle'] != null)
                      Text(
                        exerciseData['primary_muscle'].toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Colors.orangeAccent.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Detalles
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildDetailChip(
                '${exercise['sets']} series',
                Icons.repeat,
              ),
              _buildDetailChip(
                '${exercise['reps']} reps',
                Icons.fitness_center,
              ),
              if (exercise['target_weight'] != null)
                _buildDetailChip(
                  '${exercise['target_weight']} kg',
                  Icons.monitor_weight,
                ),
              if (exercise['rest_seconds'] != null)
                _buildDetailChip(
                  '${exercise['rest_seconds']}s',
                  Icons.timer,
                ),
            ],
          ),

          if (exercise['notes'] != null &&
              exercise['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              exercise['notes'],
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.orangeAccent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

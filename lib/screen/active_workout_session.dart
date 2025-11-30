import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';

class ActiveWorkoutSession extends StatefulWidget {
  final String routineId;
  final String routineDayId;
  final String dayTitle;
  final List<Map<String, dynamic>> exercises;

  const ActiveWorkoutSession({
    super.key,
    required this.routineId,
    required this.routineDayId,
    required this.dayTitle,
    required this.exercises,
  });

  @override
  State<ActiveWorkoutSession> createState() => _ActiveWorkoutSessionState();
}

class _ActiveWorkoutSessionState extends State<ActiveWorkoutSession> {
  int _currentExerciseIndex = 0;
  DateTime? _startTime;
  bool _isFinishing = false;

  // Estructura para guardar los sets completados
  final List<Map<String, dynamic>> _completedExercises = [];

  get completedSets => null;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Inicializar estructura de datos para cada ejercicio
    for (var exercise in widget.exercises) {
      _completedExercises.add({
        'exercise_id': exercise['exercises']['id'],
        'exercise_name': exercise['exercises']['name'],
        'sets': [],
      });
    }
  }

  Map<String, dynamic> get _currentExercise =>
      widget.exercises[_currentExerciseIndex];

  void _addSet(double weight, int reps, String difficulty) {
    setState(() {
      _completedExercises[_currentExerciseIndex]['sets'].add({
        'set_number':
            _completedExercises[_currentExerciseIndex]['sets'].length + 1,
        'weight': weight,
        'reps': reps,
        'difficulty': difficulty,
        'completed_at': DateTime.now().toIso8601String(),
      });
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  Future<void> _finishWorkout() async {
    // Validar que se haya completado al menos un set
    bool hasCompletedSets =
        _completedExercises.any((ex) => ex['sets'].isNotEmpty);

    if (!hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes completar al menos un set para finalizar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final finishTime = DateTime.now();

      // Filtrar solo ejercicios que tengan sets completados
      final completedExercisesWithSets =
          _completedExercises.where((ex) => ex['sets'].isNotEmpty).toList();

      print('💾 Guardando entrenamiento...');
      print('Ejercicios completados: ${completedExercisesWithSets.length}');

      // Guardar en workout_logs
      await SupabaseConfig.client.from('workout_logs').insert({
        'user_id': userId,
        'routine_id': widget.routineId,
        'routine_day_id': widget.routineDayId,
        'started_at': _startTime!.toIso8601String(),
        'finished_at': finishTime.toIso8601String(),
        'exercises_log': jsonEncode(completedExercisesWithSets),
        'perceived_effort':
            null, // Puedes agregar un selector de esfuerzo si lo deseas
        'notes': null,
      });

      print('✅ Entrenamiento guardado exitosamente');

      if (mounted) {
        // Mostrar resumen
        _showWorkoutSummary(finishTime);
      }
    } catch (e) {
      print('❌ Error al guardar entrenamiento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFinishing = false;
        });
      }
    }
  }

  void _showWorkoutSummary(DateTime finishTime) {
    final duration = finishTime.difference(_startTime!);
    final totalSets = _completedExercises.fold<int>(
      0,
      (sum, ex) => sum + (ex['sets'] as List).length,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.orangeAccent.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text(
              '¡Entrenamiento Completado!',
              style: GoogleFonts.bebasNeue(
                color: Colors.orangeAccent,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('⏱️', 'Duración', '${duration.inMinutes} minutos'),
            const SizedBox(height: 12),
            _buildSummaryRow('💪', 'Ejercicios',
                '${_completedExercises.where((ex) => ex['sets'].isNotEmpty).length}'),
            const SizedBox(height: 12),
            _buildSummaryRow('🏋️', 'Sets completados', '$totalSets'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Volver a la pantalla anterior
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'FINALIZAR',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String icon, String label, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _currentExercise;
    final exerciseData = exercise['exercises'];
    final currentCompleted = _completedExercises[_currentExerciseIndex];
    final completedSets = currentCompleted['sets'] as List;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.orangeAccent),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.orangeAccent.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                title: Text(
                  '¿Cancelar entrenamiento?',
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Perderás todo el progreso no guardado',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'CONTINUAR',
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'CANCELAR',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.dayTitle.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.orangeAccent.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ejercicio ${_currentExerciseIndex + 1} de ${widget.exercises.length}',
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${completedSets.length} sets',
                      style: GoogleFonts.montserrat(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value:
                        (_currentExerciseIndex + 1) / widget.exercises.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.orangeAccent),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info del ejercicio actual
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseData['name'],
                          style: GoogleFonts.bebasNeue(
                            color: Colors.orangeAccent,
                            fontSize: 32,
                            shadows: [
                              Shadow(
                                color: Colors.orangeAccent.withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        if (exerciseData['primary_muscle'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            exerciseData['primary_muscle']
                                .toString()
                                .toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildInfoChip(
                                '${exercise['sets']} series', Icons.repeat),
                            const SizedBox(width: 12),
                            _buildInfoChip('${exercise['reps']} reps',
                                Icons.fitness_center),
                            if (exercise['rest_seconds'] != null) ...[
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                  '${exercise['rest_seconds']}s', Icons.timer),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Sets completados
                  if (completedSets.isNotEmpty) ...[
                    Text(
                      'SETS COMPLETADOS',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...completedSets.map((set) => _buildCompletedSetCard(set)),
                    const SizedBox(height: 30),
                  ],

                  // Botón agregar set
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddSetDialog(),
                      icon: const Icon(Icons.add_circle, size: 28),
                      label: Text(
                        'AGREGAR SET',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 15,
                        shadowColor: Colors.orangeAccent.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navegación y finalizar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.orangeAccent.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentExerciseIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousExercise,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('ANTERIOR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (_currentExerciseIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        _currentExerciseIndex < widget.exercises.length - 1
                            ? _nextExercise
                            : (_isFinishing ? null : _finishWorkout),
                    icon: Icon(
                      _currentExerciseIndex < widget.exercises.length - 1
                          ? Icons.arrow_forward
                          : Icons.check_circle,
                      size: 24,
                    ),
                    label: _isFinishing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : Text(
                            _currentExerciseIndex < widget.exercises.length - 1
                                ? 'SIGUIENTE'
                                : 'FINALIZAR',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
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
          Icon(icon, size: 16, color: Colors.orangeAccent),
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

  Widget _buildCompletedSetCard(Map<String, dynamic> set) {
    Color difficultyColor;
    switch (set['difficulty']) {
      case 'easy':
        difficultyColor = Colors.green;
        break;
      case 'hard':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: difficultyColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Center(
              child: Text(
                '${set['set_number']}',
                style: GoogleFonts.montserrat(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${set['weight']} kg × ${set['reps']} reps',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  set['difficulty'] == 'easy'
                      ? 'Fácil'
                      : set['difficulty'] == 'hard'
                          ? 'Difícil'
                          : 'Medio',
                  style: GoogleFonts.montserrat(
                    color: difficultyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                completedSets.remove(set);
                // Renumerar sets
                for (int i = 0; i < completedSets.length; i++) {
                  completedSets[i]['set_number'] = i + 1;
                }
              });
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAddSetDialog() {
    final weightController = TextEditingController();
    final repsController = TextEditingController();
    String difficulty = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.orangeAccent.withOpacity(0.5),
              width: 2,
            ),
          ),
          title: Text(
            'AGREGAR SET',
            style: GoogleFonts.bebasNeue(
              color: Colors.orangeAccent,
              fontSize: 24,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.orangeAccent),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    labelStyle: TextStyle(
                      color: Colors.orangeAccent.withOpacity(0.6),
                    ),
                    filled: true,
                    fillColor: Colors.black,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.orangeAccent.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.orangeAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.orangeAccent),
                  decoration: InputDecoration(
                    labelText: 'Repeticiones',
                    labelStyle: TextStyle(
                      color: Colors.orangeAccent.withOpacity(0.6),
                    ),
                    filled: true,
                    fillColor: Colors.black,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.orangeAccent.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.orangeAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Dificultad',
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDifficultyButton(
                      'Fácil',
                      'easy',
                      Colors.green,
                      difficulty,
                      (value) => setDialogState(() => difficulty = value),
                    ),
                    _buildDifficultyButton(
                      'Medio',
                      'medium',
                      Colors.orange,
                      difficulty,
                      (value) => setDialogState(() => difficulty = value),
                    ),
                    _buildDifficultyButton(
                      'Difícil',
                      'hard',
                      Colors.red,
                      difficulty,
                      (value) => setDialogState(() => difficulty = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text.trim());
                final reps = int.tryParse(repsController.text.trim());

                if (weight != null && weight > 0 && reps != null && reps > 0) {
                  _addSet(weight, reps, difficulty);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa valores válidos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              child: Text(
                'AGREGAR',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    String label,
    String value,
    Color color,
    String currentValue,
    Function(String) onChanged,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            color: isSelected ? Colors.black : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

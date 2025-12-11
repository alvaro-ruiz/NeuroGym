// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';

/// Pantalla de Entrenamiento Activo
class ActiveTrainingSession extends StatefulWidget {
  final String routineId;
  final String routineDayId;
  final String dayTitle;
  final List<Map<String, dynamic>> exercises;

  const ActiveTrainingSession({
    super.key,
    required this.routineId,
    required this.routineDayId,
    required this.dayTitle,
    required this.exercises,
  });

  @override
  State<ActiveTrainingSession> createState() => _ActiveTrainingSessionState();
}

class _ActiveTrainingSessionState extends State<ActiveTrainingSession> {
  // Cronómetro de sesión total
  late DateTime _sessionStartTime;
  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;

  // Cronómetro de descanso
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;

  // Control de ejercicios y sets
  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;
  final List<Map<String, dynamic>> _workoutLog = [];

  // Datos del set actual
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  String _currentDifficulty = 'medium';

  // Estado general
  bool _isLoading = false;
  String? _workoutLogId;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  // INICIALIZACIÓN DE LA SESIÓN
  Future<void> _initializeSession() async {
    setState(() {
      _sessionStartTime = DateTime.now();
    });

    // Iniciar cronómetro de sesión
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionDuration = DateTime.now().difference(_sessionStartTime);
      });
    });

    // Crear registro de workout en la BD
    await _createWorkoutLog();

    // Pre-rellenar datos del primer ejercicio
    _preloadExerciseData();
  }

  Future<void> _createWorkoutLog() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await SupabaseConfig.client
          .from('workout_logs')
          .insert({
            'user_id': userId,
            'routine_id': widget.routineId,
            'routine_day_id': widget.routineDayId,
            'started_at': _sessionStartTime.toIso8601String(),
            'perceived_effort': null,
            'notes': null,
            'exercises_log': '[]',
          })
          .select()
          .single();

      setState(() {
        _workoutLogId = response['id'];
      });
    } catch (e) {
      print('❌ Error al crear workout log: $e');
    }
  }

  void _preloadExerciseData() {
    final currentExercise = _getCurrentExercise();
    if (currentExercise != null) {
      _weightController.text =
          currentExercise['target_weight']?.toString() ?? '';
      _repsController.text = currentExercise['reps']?.toString() ?? '';
    }
  }

  // GESTIÓN DE CRONÓMETROS
  void _startRestTimer() {
    final currentExercise = _getCurrentExercise();
    final restSeconds = currentExercise?['rest_seconds'] ?? 60;

    setState(() {
      _isResting = true;
      _restSecondsRemaining = restSeconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        } else {
          _stopRestTimer();
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _skipRest() {
    _stopRestTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // GESTIÓN DE SETS Y EJERCICIOS
  Map<String, dynamic>? _getCurrentExercise() {
    if (_currentExerciseIndex < widget.exercises.length) {
      return widget.exercises[_currentExerciseIndex];
    }
    return null;
  }

  int _getTotalSets() {
    final currentExercise = _getCurrentExercise();
    return currentExercise?['sets'] ?? 3;
  }

  void _completeSet() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (weight <= 0 || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa peso y repeticiones válidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Guardar set en el log
    final currentExercise = _getCurrentExercise()!;
    final exerciseLog = {
      'exercise_id': currentExercise['exercises']['id'],
      'exercise_name': currentExercise['exercises']['name'],
      'sets': [],
    };

    // Buscar si ya existe este ejercicio en el log
    final existingIndex = _workoutLog.indexWhere(
      (e) => e['exercise_id'] == currentExercise['exercises']['id'],
    );

    if (existingIndex != -1) {
      // Agregar set al ejercicio existente
      _workoutLog[existingIndex]['sets'].add({
        'set_number': _currentSetNumber,
        'weight': weight,
        'reps': reps,
        'difficulty': _currentDifficulty,
      });
    } else {
      // Crear nuevo ejercicio en el log
      exerciseLog['sets'] = [
        {
          'set_number': _currentSetNumber,
          'weight': weight,
          'reps': reps,
          'difficulty': _currentDifficulty,
        }
      ];
      _workoutLog.add(exerciseLog);
    }

    // Verificar si hay más sets
    final totalSets = _getTotalSets();
    if (_currentSetNumber < totalSets) {
      // Siguiente set del mismo ejercicio
      setState(() {
        _currentSetNumber++;
      });
      _startRestTimer();
    } else {
      // Siguiente ejercicio
      _moveToNextExercise();
    }

    // Guardar progreso en BD
    _saveProgressToDB();
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSetNumber = 1;
        _currentDifficulty = 'medium';
      });
      _preloadExerciseData();
      _stopRestTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Ejercicio completado! Siguiente: ${_getCurrentExercise()!['exercises']['name']}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Entrenamiento completado
      _finishWorkout();
    }
  }

  Future<void> _saveProgressToDB() async {
    if (_workoutLogId == null) return;

    try {
      await SupabaseConfig.client.from('workout_logs').update({
        'exercises_log': jsonEncode(_workoutLog),
      }).eq('id', _workoutLogId!);
    } catch (e) {
      print('❌ Error al guardar progreso: $e');
    }
  }

  // FINALIZACIÓN DEL ENTRENAMIENTO
  Future<void> _finishWorkout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final finishTime = DateTime.now();

      await SupabaseConfig.client.from('workout_logs').update({
        'finished_at': finishTime.toIso8601String(),
        'exercises_log': jsonEncode(_workoutLog),
      }).eq('id', _workoutLogId!);

      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      print('❌ Error al finalizar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCompletionDialog() {
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
        title: Column(
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.orangeAccent,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              '¡ENTRENAMIENTO COMPLETADO!',
              style: GoogleFonts.bebasNeue(
                color: Colors.orangeAccent,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Duración: ${_formatDuration(_sessionDuration)}',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ejercicios: ${widget.exercises.length}',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Volver con resultado
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  // UI

  @override
  Widget build(BuildContext context) {
    final currentExercise = _getCurrentExercise();

    if (currentExercise == null || _isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.orangeAccent),
          onPressed: () async {
            final confirm = await _showExitConfirmation();
            if (confirm == true && mounted) {
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
        actions: [
          // Cronómetro de sesión total
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orangeAccent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_sessionDuration),
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progreso de ejercicios
          _buildExerciseProgress(),

          // Cronómetro de descanso (si está activo)
          if (_isResting) _buildRestTimer(),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExerciseInfo(currentExercise),
                  const SizedBox(height: 30),
                  _buildSetProgress(),
                  const SizedBox(height: 30),
                  _buildInputFields(),
                  const SizedBox(height: 20),
                  _buildDifficultySelector(),
                  const SizedBox(height: 30),
                  _buildCompletedSets(currentExercise),
                ],
              ),
            ),
          ),

          // Botón de completar set
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildExerciseProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(
            color: Colors.orangeAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EJERCICIO ${_currentExerciseIndex + 1} DE ${widget.exercises.length}',
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.blue.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.hotel, color: Colors.blue, size: 40),
          const SizedBox(height: 12),
          Text(
            'DESCANSO',
            style: GoogleFonts.bebasNeue(
              color: Colors.blue,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_restSecondsRemaining seg',
            style: GoogleFonts.montserrat(
              color: Colors.blue,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipRest,
            child: Text(
              'SALTAR DESCANSO',
              style: GoogleFonts.montserrat(
                color: Colors.blue,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(Map<String, dynamic> exercise) {
    final exerciseData = exercise['exercises'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exerciseData['name'] ?? 'Ejercicio',
            style: GoogleFonts.bebasNeue(
              color: Colors.orangeAccent,
              fontSize: 28,
            ),
          ),
          if (exerciseData['primary_muscle'] != null) ...[
            const SizedBox(height: 8),
            Text(
              exerciseData['primary_muscle'].toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
          if (exercise['notes'] != null &&
              exercise['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              exercise['notes'],
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetProgress() {
    final totalSets = _getTotalSets();
    return Column(
      children: [
        Text(
          'SET $_currentSetNumber DE $totalSets',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _currentSetNumber / totalSets,
            minHeight: 20,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            'PESO (KG)',
            _weightController,
            Icons.monitor_weight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            'REPS',
            _repsController,
            Icons.repeat,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTap: () {
            controller.clear();

            /// SE BORRA AUTOMÁTICAMENTE AL HACER CLICK
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.orangeAccent),
            filled: true,
            fillColor: Colors.grey[900],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.orangeAccent.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.orangeAccent,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIFICULTAD',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDifficultyButton('easy', 'FÁCIL', Colors.green),
            const SizedBox(width: 12),
            _buildDifficultyButton('medium', 'MEDIO', Colors.orange),
            const SizedBox(width: 12),
            _buildDifficultyButton('hard', 'DIFÍCIL', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(String value, String label, Color color) {
    final isSelected = _currentDifficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentDifficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.3) : Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.orangeAccent.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isSelected ? color : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSets(Map<String, dynamic> currentExercise) {
    final completedSets = _workoutLog
        .where((e) => e['exercise_id'] == currentExercise['exercises']['id'])
        .expand((e) => e['sets'] as List)
        .toList();

    if (completedSets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETS COMPLETADOS',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...completedSets.map((set) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Set ${set['set_number']}: ${set['weight']} kg × ${set['reps']} reps',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return Container(
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
        onPressed: _isResting ? null : _completeSet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, size: 28),
            const SizedBox(width: 10),
            Text(
              'COMPLETAR SET',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
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
          '¿Salir del entrenamiento?',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tu progreso se guardará automáticamente.',
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
            child: const Text('SALIR'),
          ),
        ],
      ),
    );
  }
}

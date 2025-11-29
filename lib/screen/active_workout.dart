import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<Map<String, dynamic>> _workoutHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      print('🔍 Cargando historial de entrenamientos...');

      // Cargar historial de workout_logs
      final history = await SupabaseConfig.client
          .from('workout_logs')
          .select('''
            id,
            started_at,
            finished_at,
            perceived_effort,
            notes,
            exercises_log,
            routines (title),
            routine_days (title)
          ''')
          .eq('user_id', userId)
          .not('finished_at', 'is', null)
          .order('finished_at', ascending: false);

      print('✅ Historial cargado: ${history.length} entrenamientos');

      // Calcular estadísticas generales
      if (history.isNotEmpty) {
        double totalVolume = 0;
        int totalDuration = 0;

        for (var workout in history) {
          // Calcular volumen del exercises_log
          if (workout['exercises_log'] != null) {
            try {
              final exercisesLog = jsonDecode(workout['exercises_log']);
              for (var exercise in exercisesLog) {
                if (exercise['sets'] != null) {
                  for (var set in exercise['sets']) {
                    totalVolume += (set['weight'] ?? 0) * (set['reps'] ?? 0);
                  }
                }
              }
            } catch (e) {
              print('Error al parsear exercises_log: $e');
            }
          }

          // Calcular duración
          if (workout['started_at'] != null && workout['finished_at'] != null) {
            final start = DateTime.parse(workout['started_at']);
            final finish = DateTime.parse(workout['finished_at']);
            totalDuration += finish.difference(start).inMinutes;
          }
        }

        final totalWorkouts = history.length;
        final avgDuration =
            totalWorkouts > 0 ? totalDuration / totalWorkouts : 0;

        setState(() {
          _stats = {
            'total_workouts': totalWorkouts,
            'total_volume': totalVolume,
            'avg_duration': avgDuration,
            'last_workout': history.first['finished_at'],
          };
        });
      }

      setState(() {
        _workoutHistory = List<Map<String, dynamic>>.from(history);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar historial: $e');
      setState(() {
        _errorMessage = 'Error al cargar historial: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ayer ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} días atrás';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  int _calculateDuration(String? startedAt, String? finishedAt) {
    if (startedAt == null || finishedAt == null) return 0;
    try {
      final start = DateTime.parse(startedAt);
      final finish = DateTime.parse(finishedAt);
      return finish.difference(start).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  double _calculateVolume(String? exercisesLogJson) {
    if (exercisesLogJson == null) return 0;
    try {
      final exercisesLog = jsonDecode(exercisesLogJson);
      double volume = 0;
      for (var exercise in exercisesLog) {
        if (exercise['sets'] != null) {
          for (var set in exercise['sets']) {
            volume += (set['weight'] ?? 0) * (set['reps'] ?? 0);
          }
        }
      }
      return volume;
    } catch (e) {
      return 0;
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
          'HISTORIAL',
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.montserrat(
                              color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('REINTENTAR'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: Colors.orangeAccent,
                  backgroundColor: Colors.black,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estadísticas generales
                        if (_stats != null) _buildStatsSection(),
                        const SizedBox(height: 30),

                        // Título historial
                        Text(
                          'ENTRENAMIENTOS RECIENTES',
                          style: GoogleFonts.bebasNeue(
                            color: Colors.orangeAccent,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista de entrenamientos
                        if (_workoutHistory.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.fitness_center,
                                  color: Colors.orangeAccent.withOpacity(0.3),
                                  size: 80,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No hay entrenamientos registrados',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.orangeAccent.withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '¡Comienza tu primer entrenamiento!',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.orangeAccent.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._workoutHistory.map((workout) {
                            return _buildWorkoutCard(workout);
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                'ESTADÍSTICAS',
                style: GoogleFonts.bebasNeue(
                  color: Colors.orangeAccent,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '💪',
                  'Entrenamientos',
                  '${_stats!['total_workouts']}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '🏋️',
                  'Volumen Total',
                  '${(_stats!['total_volume']).toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '⏱️',
                  'Promedio',
                  '${(_stats!['avg_duration']).toStringAsFixed(0)} min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '📅',
                  'Último',
                  _formatDate(_stats!['last_workout']),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value,
      {double fontSize = 16}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent.withOpacity(0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final routineTitle = workout['routines']?['title'] ?? 'Entrenamiento';
    final dayTitle = workout['routine_days']?['title'] ?? '';
    final volume = _calculateVolume(workout['exercises_log']);
    final duration =
        _calculateDuration(workout['started_at'], workout['finished_at']);
    final finishedAt = workout['finished_at'];

    return GestureDetector(
      onTap: () => _showWorkoutDetail(workout),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.orangeAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routineTitle,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dayTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dayTitle,
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.orangeAccent,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem('⏱️', '$duration min'),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.orangeAccent.withOpacity(0.3),
                  ),
                  _buildDetailItem('🏋️', '${volume.toStringAsFixed(0)} kg'),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.orangeAccent.withOpacity(0.3),
                  ),
                  _buildDetailItem('📅', _formatDate(finishedAt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _showWorkoutDetail(Map<String, dynamic> workout) async {
    try {
      if (workout['exercises_log'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay datos de ejercicios'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final exercisesLog = jsonDecode(workout['exercises_log']);

      // Mostrar detalle
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DETALLE DEL ENTRENAMIENTO',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.orangeAccent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: exercisesLog.length,
                  itemBuilder: (context, index) {
                    final exercise = exercisesLog[index];
                    final sets = exercise['sets'] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['exercise_name'] ?? 'Ejercicio',
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...sets.map<Widget>((set) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${set['set_number']}',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${set['weight']} kg × ${set['reps']} reps',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _getDifficultyColor(set['difficulty'])
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getDifficultyColor(
                                            set['difficulty']),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getDifficultyText(set['difficulty']),
                                      style: GoogleFonts.montserrat(
                                        color: _getDifficultyColor(
                                            set['difficulty']),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error al mostrar detalle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyText(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'FÁCIL';
      case 'medium':
        return 'MEDIO';
      case 'hard':
        return 'DIFÍCIL';
      default:
        return '-';
    }
  }
}

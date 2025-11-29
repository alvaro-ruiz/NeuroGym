import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:neuro_gym/services/strength_standards.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'ESTADÍSTICAS',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          indicatorWeight: 3,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.orangeAccent.withOpacity(0.5),
          labelStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.fitness_center),
              text: 'HISTORIAL',
            ),
            Tab(
              icon: Icon(Icons.emoji_events),
              text: 'RANGO DE FUERZA',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WorkoutHistoryTab(),
          StrengthRankTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 1: HISTORIAL DE ENTRENAMIENTOS
// ═══════════════════════════════════════════════════════════════════════════

class WorkoutHistoryTab extends StatefulWidget {
  const WorkoutHistoryTab({super.key});

  @override
  State<WorkoutHistoryTab> createState() => _WorkoutHistoryTabState();
}

class _WorkoutHistoryTabState extends State<WorkoutHistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

      if (history.isNotEmpty) {
        double totalVolume = 0;
        int totalDuration = 0;

        for (var workout in history) {
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
    super.build(context);

    return _isLoading
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
                      if (_stats != null) _buildStatsSection(),
                      const SizedBox(height: 30),
                      Text(
                        'ENTRENAMIENTOS RECIENTES',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.orangeAccent,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                'RESUMEN',
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
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 2: RANGO DE FUERZA
// ═══════════════════════════════════════════════════════════════════════════

class StrengthRankTab extends StatefulWidget {
  const StrengthRankTab({super.key});

  @override
  State<StrengthRankTab> createState() => _StrengthRankTabState();
}

class _StrengthRankTabState extends State<StrengthRankTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  String? _errorMessage;
  double? _bodyWeight;
  Map<String, dynamic>? _rankData;
  Map<String, double> _maxLifts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      print('🏋️ Cargando datos de fuerza...');

      // Obtener último peso corporal (simplificado - asumimos 75kg si no hay datos)
      _bodyWeight = 75.0; // Valor por defecto

      // Obtener workout logs
      final workoutLogs = await SupabaseConfig.client
          .from('workout_logs')
          .select('exercises_log')
          .eq('user_id', userId)
          .not('finished_at', 'is', null);

      print('📊 Workouts encontrados: ${workoutLogs.length}');

      // Extraer máximos de cada ejercicio
      _maxLifts = await StrengthStandards.extractMaxLiftsFromLogs(workoutLogs);

      print('💪 Ejercicios con máximos: ${_maxLifts.keys.join(", ")}');

      // Calcular rango
      _rankData = StrengthStandards.calculateUserRank(
        bodyWeight: _bodyWeight!,
        maxLifts: _maxLifts,
      );

      print('🎯 Rango calculado: ${_rankData!['overall_rank']}');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _isLoading
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
                      Icon(
                        Icons.fitness_center,
                        color: Colors.orangeAccent.withOpacity(0.3),
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.montserrat(
                          color: Colors.orangeAccent.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadData,
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
                onRefresh: _loadData,
                color: Colors.orangeAccent,
                backgroundColor: Colors.black,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallRankCard(),
                      const SizedBox(height: 30),
                      _buildBodyWeightCard(),
                      const SizedBox(height: 30),
                      Text(
                        'ANÁLISIS POR EJERCICIO',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.orangeAccent,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildExerciseCards(),
                    ],
                  ),
                ),
              );
  }

  Widget _buildOverallRankCard() {
    final rank = _rankData!['overall_rank'];
    final score = _rankData!['strength_score'];
    final emoji = StrengthStandards.getRankEmoji(rank);
    final description = StrengthStandards.getRankDescription(rank);
    final color = StrengthStandards.rankColors[rank] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TU RANGO GENERAL',
            style: GoogleFonts.bebasNeue(
              color: Colors.orangeAccent,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            emoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 12),
          Text(
            rank.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              color: color,
              fontSize: 42,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.8),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              'Puntuación: ${score.toStringAsFixed(2)}/3.00',
              style: GoogleFonts.montserrat(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyWeightCard() {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.orangeAccent,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.monitor_weight,
              color: Colors.orangeAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso Corporal',
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_bodyWeight!.toStringAsFixed(1)} kg',
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Los estándares se\najustan a tu peso',
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent.withOpacity(0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExerciseCards() {
    final liftsAnalysis = _rankData!['lifts_analysis'] as Map<String, dynamic>;

    if (liftsAnalysis.isEmpty) {
      return [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.fitness_center,
                color: Colors.orangeAccent.withOpacity(0.3),
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay ejercicios principales registrados',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa entrenamientos con:\nSentadilla, Press Banca, Peso Muerto, Press Militar',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent.withOpacity(0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return liftsAnalysis.entries.map((entry) {
      final exerciseName = entry.key;
      final analysis = entry.value as Map<String, dynamic>;
      return _buildExerciseCard(exerciseName, analysis);
    }).toList();
  }

  Widget _buildExerciseCard(String exercise, Map<String, dynamic> analysis) {
    final rank = analysis['rank'];
    final color = StrengthStandards.rankColors[rank] ?? Colors.grey;
    final weight = analysis['weight'];
    final ratio = analysis['ratio'];
    final nextTarget = analysis['next_target'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(
                  StrengthStandards.getRankEmoji(rank),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rank.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Máximo',
                '${weight.toStringAsFixed(1)} kg',
                Colors.orangeAccent,
              ),
              _buildStatColumn(
                'Ratio',
                StrengthStandards.formatRatio(ratio),
                color,
              ),
              _buildStatColumn(
                'Puntuación',
                '${analysis['score'].toStringAsFixed(1)}/3.0',
                Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (nextTarget != null) ...[
            const Divider(color: Colors.orangeAccent, height: 30),
            Text(
              'Siguiente objetivo: ${nextTarget['rank']}',
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: nextTarget['progress'],
                minHeight: 20,
                backgroundColor: Colors.black,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(nextTarget['progress'] * 100).toStringAsFixed(1)}% completado',
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Meta: ${(nextTarget['target_ratio'] * _bodyWeight!).toStringAsFixed(1)} kg',
                  style: GoogleFonts.montserrat(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:neuro_gym/services/strength_standards.dart';

class StrengthRankPage extends StatefulWidget {
  const StrengthRankPage({super.key});

  @override
  State<StrengthRankPage> createState() => _StrengthRankPageState();
}

class _StrengthRankPageState extends State<StrengthRankPage> {
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

      // 1. Obtener último peso corporal
      final weightLogs = await SupabaseConfig.client
          .from('weight_logs')
          .select('weight_kg')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (weightLogs.isEmpty) {
        setState(() {
          _errorMessage =
              'Necesitas registrar tu peso corporal primero.\nVe a Control de Peso para agregarlo.';
          _isLoading = false;
        });
        return;
      }

      _bodyWeight = weightLogs.first['weight_kg'].toDouble();
      print('⚖️ Peso corporal: $_bodyWeight kg');

      // 2. Obtener workout logs
      final workoutLogs = await SupabaseConfig.client
          .from('workout_logs')
          .select('exercises_log')
          .eq('user_id', userId)
          .not('finished_at', 'is', null);

      print('📊 Workouts encontrados: ${workoutLogs.length}');

      // 3. Extraer máximos de cada ejercicio
      _maxLifts = await StrengthStandards.extractMaxLiftsFromLogs(workoutLogs);

      print('💪 Ejercicios con máximos: ${_maxLifts.keys.join(", ")}');

      // 4. Calcular rango
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
          'RANGO DE FUERZA',
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
        actions: [
          IconButton(
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.info_outline, color: Colors.orangeAccent),
          ),
        ],
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
                        const SizedBox(height: 30),
                        _buildRankLegend(),
                      ],
                    ),
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
    final standards = analysis['standards'] as Map<String, double>;

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
          // Header
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

          // Estadísticas actuales
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

          // Progreso al siguiente nivel
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

          // Estándares
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text(
              'Ver estándares completos',
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent,
                fontSize: 12,
              ),
            ),
            iconColor: Colors.orangeAccent,
            collapsedIconColor: Colors.orangeAccent.withOpacity(0.5),
            children: [
              _buildStandardRow('Novato', standards['novice']!, Colors.grey),
              _buildStandardRow(
                  'Intermedio', standards['intermediate']!, Colors.green),
              _buildStandardRow(
                  'Avanzado', standards['advanced']!, Colors.blue),
              _buildStandardRow('Élite', standards['elite']!, Colors.orange),
            ],
          ),
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

  Widget _buildStandardRow(String rank, double ratio, Color color) {
    final weight = ratio * _bodyWeight!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rank,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${weight.toStringAsFixed(1)} kg (${StrengthStandards.formatRatio(ratio)})',
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankLegend() {
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
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'SOBRE LOS RANGOS',
                style: GoogleFonts.bebasNeue(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLegendItem(
            '🌱 Novato',
            'Menos de 1 año de entrenamiento consistente',
            Colors.grey,
          ),
          _buildLegendItem(
            '💚 Intermedio',
            '1-2 años de entrenamiento regular',
            Colors.green,
          ),
          _buildLegendItem(
            '💪 Avanzado',
            '2-5 años de entrenamiento dedicado',
            Colors.blue,
          ),
          _buildLegendItem(
            '👑 Élite',
            'Nivel competitivo, 5+ años de experiencia',
            Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            '* Estándares basados en Strength Level (strengthlevel.com)\n* Los valores se ajustan según tu peso corporal',
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent.withOpacity(0.5),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.orangeAccent.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Text(
          '¿Cómo funciona?',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 22,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Tu rango se calcula comparando tus levantamientos máximos con estándares internacionales de fuerza relativa.\n\n'
            'Se tienen en cuenta:\n'
            '• Tu peso corporal actual\n'
            '• Tus máximos en ejercicios principales\n'
            '• Ratio peso levantado / peso corporal\n\n'
            'Los estándares provienen de Strength Level, una base de datos con millones de levantamientos verificados.\n\n'
            'Importante: Los rangos se ajustan según tu peso usando escalado alométrico, lo que hace la comparación justa independientemente de tu talla.',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ENTENDIDO',
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

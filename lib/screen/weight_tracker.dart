import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightTrackerPage extends StatefulWidget {
  const WeightTrackerPage({super.key});

  @override
  State<WeightTrackerPage> createState() => _WeightTrackerPageState();
}

class _WeightTrackerPageState extends State<WeightTrackerPage> {
  List<Map<String, dynamic>> _weightHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeightHistory();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🔍 Cargando historial de peso...');

      final response = await SupabaseConfig.client
          .from('weight_logs')
          .select('id, weight_kg, notes, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('✅ Registros cargados: ${response.length}');

      setState(() {
        _weightHistory = List<Map<String, dynamic>>.from(response);
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

  Future<void> _addWeight() async {
    final weight = double.tryParse(_weightController.text.trim());

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un peso válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('💾 Guardando peso: $weight kg');

      await SupabaseConfig.client.from('weight_logs').insert({
        'user_id': userId,
        'weight_kg': weight,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Peso guardado exitosamente');

      _weightController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Peso registrado!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
        _loadWeightHistory();
      }
    } catch (e) {
      print('❌ Error al guardar peso: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWeight(String id) async {
    try {
      await SupabaseConfig.client.from('weight_logs').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro eliminado'),
            backgroundColor: Colors.green,
          ),
        );

        _loadWeightHistory();
      }
    } catch (e) {
      print('❌ Error al eliminar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddWeightDialog() {
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
          'REGISTRAR PESO',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.orangeAccent),
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                labelStyle: TextStyle(
                  color: Colors.orangeAccent.withOpacity(0.6),
                ),
                hintText: 'Ej: 75.5',
                hintStyle: TextStyle(
                  color: Colors.orangeAccent.withOpacity(0.3),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _weightController.clear();
              Navigator.pop(context);
            },
            child: Text(
              'CANCELAR',
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addWeight,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'GUARDAR',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          'CONTROL DE PESO',
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
            onPressed: _showAddWeightDialog,
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.orangeAccent,
              size: 28,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orangeAccent,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadWeightHistory,
              color: Colors.orangeAccent,
              backgroundColor: Colors.black,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_weightHistory.isNotEmpty) ...[
                      _buildStatsCards(),
                      const SizedBox(height: 30),
                    ],
                    if (_weightHistory.length >= 2) ...[
                      Text(
                        'PROGRESO',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.orangeAccent,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChart(),
                      const SizedBox(height: 30),
                    ],
                    Text(
                      'HISTORIAL',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_weightHistory.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.monitor_weight,
                              color: Colors.orangeAccent.withOpacity(0.3),
                              size: 80,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No hay registros aún',
                              style: GoogleFonts.montserrat(
                                color: Colors.orangeAccent.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _showAddWeightDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar primer registro'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._weightHistory.map((record) {
                        return _buildWeightCard(record);
                      }),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWeightDialog,
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(
          'REGISTRAR',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final currentWeight = _weightHistory.first['weight_kg'];
    final oldestWeight = _weightHistory.last['weight_kg'];
    final difference = currentWeight - oldestWeight;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'ACTUAL',
            '${currentWeight.toStringAsFixed(1)} kg',
            Icons.monitor_weight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'CAMBIO',
            '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(1)} kg',
            difference >= 0 ? Icons.trending_up : Icons.trending_down,
            color: difference >= 0 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? Colors.orangeAccent).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.orangeAccent).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? Colors.orangeAccent,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: (color ?? Colors.orangeAccent).withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: color ?? Colors.orangeAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final sortedData = List<Map<String, dynamic>>.from(_weightHistory)
      ..sort((a, b) => DateTime.parse(a['created_at'])
          .compareTo(DateTime.parse(b['created_at'])));

    final chartData = sortedData.length > 10
        ? sortedData.sublist(sortedData.length - 10)
        : sortedData;

    final spots = chartData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['weight_kg'] as num).toDouble(),
      );
    }).toList();

    final minWeight = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxWeight = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.orangeAccent.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= chartData.length) return const Text('');
                  final date =
                      DateTime.parse(chartData[value.toInt()]['created_at']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: minWeight - 2,
          maxY: maxWeight + 2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orangeAccent,
                    strokeWidth: 2,
                    strokeColor: Colors.black,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['created_at']);
    final weight = record['weight_kg'];

    final currentIndex = _weightHistory.indexOf(record);
    String? difference;
    Color? diffColor;

    if (currentIndex < _weightHistory.length - 1) {
      final previousWeight = _weightHistory[currentIndex + 1]['weight_kg'];
      final diff = weight - previousWeight;
      difference = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg';
      diffColor = diff >= 0 ? Colors.green : Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_weight,
              color: Colors.orangeAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${weight.toStringAsFixed(1)} kg',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (difference != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: diffColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          difference,
                          style: GoogleFonts.montserrat(
                            color: diffColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
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
                    '¿Eliminar registro?',
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    '¿Estás seguro de eliminar este registro?',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'CANCELAR',
                        style: GoogleFonts.montserrat(
                          color: Colors.orangeAccent.withOpacity(0.6),
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
                        'ELIMINAR',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                _deleteWeight(record['id']);
              }
            },
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

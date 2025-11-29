import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/services/routine_recomender.dart';
import 'package:neuro_gym/screen/routine_detail.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final TextEditingController _goalController = TextEditingController();
  int _experienceLevel = 2; // 1=principiante, 2=intermedio, 3=avanzado
  int _daysPerWeek = 3;
  final List<String> _selectedMuscles = [];

  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  final List<String> _muscleGroups = [
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Abdomen',
  ];

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final goal = _goalController.text.trim().isEmpty
          ? 'rutina completa de gimnasio'
          : _goalController.text.trim();

      final muscles =
          _selectedMuscles.isEmpty ? ['cuerpo completo'] : _selectedMuscles;

      print('🎯 Buscando recomendaciones...');
      print('Goal: $goal');
      print('Level: $_experienceLevel');
      print('Days: $_daysPerWeek');
      print('Muscles: $muscles');

      final recommendations =
          await RoutineRecommenderService.getRecommendations(
        userGoal: goal,
        experienceLevel: _experienceLevel,
        preferredMuscles: muscles,
        daysPerWeek: _daysPerWeek,
        limit: 10,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
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
          'RECOMENDACIONES IA',
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
      body: Column(
        children: [
          // Formulario de preferencias
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono y descripción
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orangeAccent.withOpacity(0.6),
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
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.orangeAccent,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Encuentra tu rutina perfecta',
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Objetivo
                  Text(
                    'TU OBJETIVO',
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _goalController,
                    style: const TextStyle(color: Colors.orangeAccent),
                    decoration: InputDecoration(
                      hintText: 'Ej: ganar masa muscular, definir, fuerza...',
                      hintStyle: TextStyle(
                        color: Colors.orangeAccent.withOpacity(0.4),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Nivel de experiencia
                  Text(
                    'NIVEL DE EXPERIENCIA',
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildLevelButton('Principiante', 1),
                      const SizedBox(width: 10),
                      _buildLevelButton('Intermedio', 2),
                      const SizedBox(width: 10),
                      _buildLevelButton('Avanzado', 3),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Días por semana
                  Text(
                    'DÍAS POR SEMANA',
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < 6 ? 8 : 0,
                          ),
                          child: _buildDayButton(day),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 25),

                  // Grupos musculares
                  Text(
                    'GRUPOS MUSCULARES (OPCIONAL)',
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _muscleGroups.map((muscle) {
                      final isSelected = _selectedMuscles.contains(muscle);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMuscles.remove(muscle);
                            } else {
                              _selectedMuscles.add(muscle);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.orangeAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            muscle,
                            style: GoogleFonts.montserrat(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.orangeAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Resultados
                  if (_hasSearched) ...[
                    const Divider(
                      color: Colors.orangeAccent,
                      thickness: 1,
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECOMENDACIONES',
                          style: GoogleFonts.bebasNeue(
                            color: Colors.orangeAccent,
                            fontSize: 22,
                          ),
                        ),
                        if (_recommendations.isNotEmpty)
                          Text(
                            '${_recommendations.length} rutinas',
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_isLoading)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Analizando con IA...',
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.montserrat(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else if (_hasSearched && _recommendations.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.orangeAccent.withOpacity(0.3),
                            size: 60,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'No se encontraron rutinas',
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._recommendations.map((routine) {
                      return _buildRoutineCard(routine);
                    }),
                ],
              ),
            ),
          ),

          // Botón buscar
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
              onPressed: _isLoading ? null : _getRecommendations,
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
                  const Icon(Icons.psychology, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'BUSCAR RUTINAS',
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

  Widget _buildLevelButton(String label, int level) {
    final isSelected = _experienceLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _experienceLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orangeAccent : Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.orangeAccent
                  : Colors.orangeAccent.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.black : Colors.orangeAccent,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDayButton(int day) {
    final isSelected = _daysPerWeek == day;
    return GestureDetector(
      onTap: () => setState(() => _daysPerWeek = day),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.orangeAccent
                : Colors.orangeAccent.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            '$day',
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.black : Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineCard(Map<String, dynamic> routine) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineDetailPage(
              routineId: routine['id'],
              routineTitle: routine['title'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.4),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine['title'],
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orangeAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 14,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${routine['match_percentage']}%',
                        style: GoogleFonts.montserrat(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (routine['description'] != null &&
                routine['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                routine['description'],
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

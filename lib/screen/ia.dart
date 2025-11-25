import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/services/routine_recomender.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:http/http.dart' as http;

class AIRoutineGeneratorDialog extends StatefulWidget {
  const AIRoutineGeneratorDialog({super.key});

  @override
  State<AIRoutineGeneratorDialog> createState() =>
      _AIRoutineGeneratorDialogState();
}

class _AIRoutineGeneratorDialogState extends State<AIRoutineGeneratorDialog> {
  int _currentStep = 0;
  bool _isGenerating = false;

  // Respuestas del usuario
  String _goal = '';
  int _experienceLevel = 2;
  int _daysPerWeek = 3;
  List<String> _selectedMuscles = [];
  String _routineName = '';

  final List<String> _muscleGroups = [
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Abdomen',
  ];

  final List<String> _goalSuggestions = [
    'Ganar masa muscular',
    'Definir y tonificar',
    'Aumentar fuerza',
    'Perder peso',
    'Mejorar resistencia',
  ];

  /// Verifica la conexión a internet
  Future<bool> _checkInternetConnection() async {
    try {
      print('🌐 Verificando conexión a internet...');
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ Conexión a internet OK');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Sin conexión a internet: $e');
      return false;
    }
  }

  /// Verifica la conexión con Hugging Face
  Future<bool> _checkHuggingFaceConnection() async {
    try {
      print('🤖 Verificando conexión con Hugging Face...');
      return await RoutineRecommenderService.testConnection();
    } catch (e) {
      print('❌ Error al conectar con Hugging Face: $e');
      return false;
    }
  }

  Future<void> _generateRoutine() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // 1. Verificar conexión a internet
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        throw Exception('No hay conexión a internet.\n'
            'Por favor verifica tu conexión WiFi o datos móviles.');
      }

      // 2. Verificar conexión con Hugging Face
      final hasHuggingFace = await _checkHuggingFaceConnection();
      if (!hasHuggingFace) {
        throw Exception('No se puede conectar con el servidor de IA.\n'
            'Verifica que tu API key sea válida o intenta más tarde.');
      }

      print('🤖 Generando recomendaciones con IA...');

      // 3. Obtener recomendaciones del servicio IA
      final recommendations =
          await RoutineRecommenderService.getRecommendations(
        userGoal: _goal.isEmpty ? 'rutina completa de gimnasio' : _goal,
        experienceLevel: _experienceLevel,
        preferredMuscles:
            _selectedMuscles.isEmpty ? ['cuerpo completo'] : _selectedMuscles,
        daysPerWeek: _daysPerWeek,
        limit: 1,
      );

      if (recommendations.isEmpty) {
        throw Exception('No se encontraron rutinas recomendadas');
      }

      final bestMatch = recommendations.first;

      // 4. Obtener el ID del usuario actual
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      print('📋 Cargando días de la rutina recomendada...');

      // 5. Cargar los días de la rutina recomendada
      final routineDays = await SupabaseConfig.client
          .from('routine_days')
          .select('''
            id,
            day_order,
            title,
            notes,
            duration_minutes
          ''')
          .eq('routine_id', bestMatch['id'])
          .order('day_order', ascending: true);

      print('✅ Encontrados ${routineDays.length} días');

      // 6. Crear nueva rutina con nombre personalizado
      final newRoutineTitle =
          _routineName.isEmpty ? '${bestMatch['title']} (IA)' : _routineName;

      print('💾 Creando nueva rutina: $newRoutineTitle');

      final newRoutine = await SupabaseConfig.client
          .from('routines')
          .insert({
            'title': newRoutineTitle,
            'description':
                'Rutina generada por IA basada en tus preferencias: $_goal',
            'owner_user_id': userId,
            'is_public': false,
          })
          .select()
          .single();

      print('✅ Nueva rutina creada: ${newRoutine['id']}');

      // 7. Copiar los días de la rutina
      int daysCopied = 0;
      int exercisesCopied = 0;

      for (var day in routineDays) {
        print('📅 Copiando día ${day['day_order']}: ${day['title']}');

        final newDay = await SupabaseConfig.client
            .from('routine_days')
            .insert({
              'routine_id': newRoutine['id'],
              'day_order': day['day_order'],
              'title': day['title'],
              'notes': day['notes'],
              'duration_minutes': day['duration_minutes'],
            })
            .select()
            .single();

        daysCopied++;

        // 8. Copiar los ejercicios de cada día
        final exercises = await SupabaseConfig.client
            .from('routine_exercises')
            .select('''
              exercise_id,
              exercise_order,
              sets,
              reps,
              target_weight,
              rest_seconds,
              tempo,
              notes
            ''')
            .eq('routine_day_id', day['id'])
            .order('exercise_order', ascending: true);

        print('  💪 Copiando ${exercises.length} ejercicios');

        for (var exercise in exercises) {
          await SupabaseConfig.client.from('routine_exercises').insert({
            'routine_day_id': newDay['id'],
            'exercise_id': exercise['exercise_id'],
            'exercise_order': exercise['exercise_order'],
            'sets': exercise['sets'],
            'reps': exercise['reps'],
            'target_weight': exercise['target_weight'],
            'rest_seconds': exercise['rest_seconds'],
            'tempo': exercise['tempo'],
            'notes': exercise['notes'],
          });
          exercisesCopied++;
        }
      }

      print('🎉 Rutina completada:');
      print('  - Días copiados: $daysCopied');
      print('  - Ejercicios copiados: $exercisesCopied');

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ¡Rutina "$newRoutineTitle" creada!\n'
              '$daysCopied días con $exercisesCopied ejercicios',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Retornar true para indicar que se creó una rutina
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error al generar rutina: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al generar rutina:\n${e.toString()}',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          // Header
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
                Row(
                  children: [
                    const Icon(Icons.psychology,
                        color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'GENERAR RUTINA CON IA',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.orangeAccent),
                ),
              ],
            ),
          ),

          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? Colors.orangeAccent
                          : Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: _isGenerating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Generando tu rutina perfecta...',
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Esto puede tardar unos segundos',
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStep(),
                  ),
          ),

          // Navigation buttons
          if (!_isGenerating)
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
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent,
                          side: const BorderSide(color: Colors.orangeAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'ATRÁS',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 4) {
                          setState(() {
                            _currentStep++;
                          });
                        } else {
                          _generateRoutine();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep < 4 ? 'SIGUIENTE' : 'GENERAR RUTINA',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
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

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildGoalStep();
      case 1:
        return _buildExperienceStep();
      case 2:
        return _buildDaysStep();
      case 3:
        return _buildMusclesStep();
      case 4:
        return _buildNameStep();
      default:
        return Container();
    }
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuál es tu objetivo principal?',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Esto nos ayudará a personalizar tu rutina',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        ..._goalSuggestions.map((goal) {
          return GestureDetector(
            onTap: () => setState(() => _goal = goal),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _goal == goal ? Colors.orangeAccent : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _goal == goal
                      ? Colors.orangeAccent
                      : Colors.orangeAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                goal,
                style: GoogleFonts.montserrat(
                  color: _goal == goal ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => _goal = value),
          style: const TextStyle(color: Colors.orangeAccent),
          decoration: InputDecoration(
            hintText: 'O escribe tu propio objetivo...',
            hintStyle: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.4),
            ),
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

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuál es tu nivel de experiencia?',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 30),
        _buildLevelCard(1, 'Principiante', '🌱', 'Menos de 1 año entrenando'),
        _buildLevelCard(2, 'Intermedio', '💪', '1-2 años de experiencia'),
        _buildLevelCard(3, 'Avanzado', '🏆', 'Más de 2 años entrenando'),
      ],
    );
  }

  Widget _buildLevelCard(int level, String title, String emoji, String desc) {
    final isSelected = _experienceLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _experienceLevel = level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.orangeAccent
                : Colors.orangeAccent.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.montserrat(
                      color: isSelected
                          ? Colors.black.withOpacity(0.7)
                          : Colors.orangeAccent.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuántos días puedes entrenar?',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 30),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = _daysPerWeek == day;
            return GestureDetector(
              onTap: () => setState(() => _daysPerWeek = day),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orangeAccent : Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.orangeAccent
                        : Colors.orangeAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: GoogleFonts.montserrat(
                      color: isSelected ? Colors.black : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMusclesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué músculos quieres trabajar?',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Selecciona todos los que quieras (opcional)',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
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
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orangeAccent : Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.orangeAccent
                        : Colors.orangeAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  muscle,
                  style: GoogleFonts.montserrat(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo quieres llamar tu rutina?',
          style: GoogleFonts.bebasNeue(
            color: Colors.orangeAccent,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Dale un nombre único (opcional)',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          onChanged: (value) => setState(() => _routineName = value),
          style: const TextStyle(color: Colors.orangeAccent),
          decoration: InputDecoration(
            hintText: 'Ej: Mi Rutina de Volumen 2025',
            hintStyle: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.4),
            ),
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
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Resumen',
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryItem(
                  'Objetivo', _goal.isEmpty ? 'Rutina completa' : _goal),
              _buildSummaryItem(
                'Nivel',
                _experienceLevel == 1
                    ? 'Principiante'
                    : _experienceLevel == 2
                        ? 'Intermedio'
                        : 'Avanzado',
              ),
              _buildSummaryItem('Días por semana', '$_daysPerWeek días'),
              _buildSummaryItem(
                'Músculos',
                _selectedMuscles.isEmpty
                    ? 'Cuerpo completo'
                    : _selectedMuscles.join(', '),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

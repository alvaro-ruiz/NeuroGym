import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:neuro_gym/screen/ia.dart';

class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({super.key});

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final bool _isPublic = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _days = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addDay() {
    setState(() {
      _days.add({
        'title': '',
        'notes': '',
        'duration_minutes': 60,
        'controller_title': TextEditingController(),
        'controller_notes': TextEditingController(),
      });
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days[index]['controller_title']?.dispose();
      _days[index]['controller_notes']?.dispose();
      _days.removeAt(index);
    });
  }

  Future<void> _createRoutine() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (title.isEmpty) {
        setState(() {
          _errorMessage = 'El título es obligatorio';
          _isLoading = false;
        });
        return;
      }

      if (_days.isEmpty) {
        setState(() {
          _errorMessage = 'Debes agregar al menos un día';
          _isLoading = false;
        });
        return;
      }

      for (var i = 0; i < _days.length; i++) {
        final dayTitle = _days[i]['controller_title'].text.trim();
        if (dayTitle.isEmpty) {
          setState(() {
            _errorMessage = 'El día ${i + 1} necesita un título';
            _isLoading = false;
          });
          return;
        }
      }

      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final routineResponse = await SupabaseConfig.client
          .from('routines')
          .insert({
            'title': title,
            'description': description,
            'owner_user_id': userId,
            'is_public': _isPublic,
          })
          .select()
          .single();

      for (var i = 0; i < _days.length; i++) {
        final day = _days[i];
        final dayTitle = day['controller_title'].text.trim();
        final dayNotes = day['controller_notes'].text.trim();
        final duration = day['duration_minutes'];

        await SupabaseConfig.client.from('routine_days').insert({
          'routine_id': routineResponse['id'],
          'day_order': i + 1,
          'title': dayTitle,
          'notes': dayNotes.isEmpty ? null : dayNotes,
          'duration_minutes': duration,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Rutina creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error al crear rutina: $e');
      setState(() {
        _errorMessage = 'Error al crear rutina: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAIGenerator() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIRoutineGeneratorDialog(),
    );

    if (result == true && mounted) {
      // La rutina se creó con IA, volver a la pantalla anterior
      Navigator.pop(context, true);
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
          icon: const Icon(Icons.close, color: Colors.orangeAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CREAR RUTINA',
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
        // BOTÓN DE IA EN APPBAR
        actions: [
          IconButton(
            onPressed: _openAIGenerator,
            icon: const Icon(
              Icons.psychology,
              color: Colors.orangeAccent,
              size: 28,
            ),
            tooltip: 'Generar con IA',
          ),
        ],
      ),
      body: Column(
        children: [
          // BANNER DE IA
          GestureDetector(
            onTap: _openAIGenerator,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.3),
                    Colors.blue.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purple,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENERA TU RUTINA CON IA',
                          style: GoogleFonts.bebasNeue(
                            color: Colors.purple,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crea una rutina personalizada en segundos',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.purple,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _buildTextField(
                    'NOMBRE DE LA RUTINA',
                    'Ej: Full Body 3x',
                    _titleController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'DESCRIPCIÓN (OPCIONAL)',
                    'Describe tu rutina...',
                    _descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DÍAS DE ENTRENAMIENTO',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.orangeAccent,
                          fontSize: 22,
                        ),
                      ),
                      IconButton(
                        onPressed: _addDay,
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.orangeAccent,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_days.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.orangeAccent.withOpacity(0.3),
                              size: 60,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'No hay días agregados',
                              style: GoogleFonts.montserrat(
                                color: Colors.orangeAccent.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _addDay,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar primer día'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(_days.length, (index) {
                      return _buildDayCard(index);
                    }),
                ],
              ),
            ),
          ),

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
              onPressed: _isLoading ? null : _createRoutine,
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
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'CREAR RUTINA',
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

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.orangeAccent),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.4),
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
      ],
    );
  }

  Widget _buildDayCard(int index) {
    final day = _days[index];

    return Container(
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
              Container(
                width: 40,
                height: 40,
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
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DÍA ${index + 1}',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.orangeAccent,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeDay(index),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: day['controller_title'],
            style: const TextStyle(color: Colors.orangeAccent),
            decoration: InputDecoration(
              labelText: 'Nombre del día',
              labelStyle: TextStyle(
                color: Colors.orangeAccent.withOpacity(0.6),
                fontSize: 12,
              ),
              hintText: 'Ej: Pecho y Tríceps',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: day['controller_notes'],
            maxLines: 2,
            style: const TextStyle(color: Colors.orangeAccent),
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              labelStyle: TextStyle(
                color: Colors.orangeAccent.withOpacity(0.6),
                fontSize: 12,
              ),
              hintText: 'Enfoque, objetivos...',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.orangeAccent.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Duración: ',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: day['duration_minutes'].toDouble(),
                  min: 30,
                  max: 120,
                  divisions: 9,
                  activeColor: Colors.orangeAccent,
                  inactiveColor: Colors.orangeAccent.withOpacity(0.2),
                  label: '${day['duration_minutes']} min',
                  onChanged: (value) {
                    setState(() {
                      day['duration_minutes'] = value.toInt();
                    });
                  },
                ),
              ),
              Text(
                '${day['duration_minutes']} min',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

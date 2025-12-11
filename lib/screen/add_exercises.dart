import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';

class AddExercisesToDayPage extends StatefulWidget {
  final String dayId;
  final String dayTitle;

  const AddExercisesToDayPage({
    super.key,
    required this.dayId,
    required this.dayTitle,
  });

  @override
  State<AddExercisesToDayPage> createState() => _AddExercisesToDayPageState();
}

class _AddExercisesToDayPageState extends State<AddExercisesToDayPage> {
  List<Map<String, dynamic>> _availableExercises = [];
  final List<Map<String, dynamic>> _selectedExercises = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

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
      final response = await SupabaseConfig.client
          .from('exercises')
          .select(
              'id, name, description, primary_muscle, equipment, difficulty')
          .order('name', ascending: true);
      setState(() {
        _availableExercises = List<Map<String, dynamic>>.from(response);
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

  void _addExercise(Map<String, dynamic> exercise) {
    setState(() {
      _selectedExercises.add({
        'exercise_id': exercise['id'],
        'exercise_name': exercise['name'],
        'primary_muscle': exercise['primary_muscle'],
        'sets': 3,
        'reps': '10',
        'target_weight': null,
        'rest_seconds': 60,
        'tempo': null,
        'notes': '',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise['name']} agregado'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  Future<void> _saveExercises() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos un ejercicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      for (var i = 0; i < _selectedExercises.length; i++) {
        final exercise = _selectedExercises[i];

        await SupabaseConfig.client.from('routine_exercises').insert({
          'routine_day_id': widget.dayId,
          'exercise_id': exercise['exercise_id'],
          'exercise_order': i + 1,
          'sets': exercise['sets'],
          'reps': exercise['reps'],
          'target_weight': exercise['target_weight'],
          'rest_seconds': exercise['rest_seconds'],
          'tempo':
              exercise['tempo']?.isEmpty == true ? null : exercise['tempo'],
          'notes':
              exercise['notes']?.isEmpty == true ? null : exercise['notes'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Ejercicios guardados exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error al guardar ejercicios: $e');
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
          _isSaving = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredExercises {
    if (_searchQuery.isEmpty) return _availableExercises;

    return _availableExercises.where((exercise) {
      final name = exercise['name']?.toString().toLowerCase() ?? '';
      final muscle = exercise['primary_muscle']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || muscle.contains(query);
    }).toList();
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
          'AGREGAR EJERCICIOS',
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.dayTitle.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedExercises.length} ejercicios',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.orangeAccent),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle: TextStyle(
                  color: Colors.orangeAccent.withOpacity(0.4),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.orangeAccent,
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  )
                : _filteredExercises.isEmpty
                    ? Center(
                        child: Text(
                          'No hay ejercicios disponibles',
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return _buildExerciseItem(exercise);
                        },
                      ),
          ),
          if (_selectedExercises.isNotEmpty)
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
              child: ElevatedButton(
                onPressed: () {
                  _showSelectedExercises();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.list, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'VER Y CONFIGURAR (${_selectedExercises.length})',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildExerciseItem(Map<String, dynamic> exercise) {
    final isSelected = _selectedExercises.any(
      (e) => e['exercise_id'] == exercise['id'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.orangeAccent
              : Colors.orangeAccent.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: isSelected ? null : () => _addExercise(exercise),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.orangeAccent
                : Colors.orangeAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? Icons.check : Icons.fitness_center,
            color: isSelected ? Colors.black : Colors.orangeAccent,
          ),
        ),
        title: Text(
          exercise['name'] ?? 'Sin nombre',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          exercise['primary_muscle']?.toString().toUpperCase() ?? '',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: Colors.orangeAccent,
              )
            : Icon(
                Icons.add_circle_outline,
                color: Colors.orangeAccent.withOpacity(0.5),
              ),
      ),
    );
  }

  void _showSelectedExercises() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                      'CONFIGURAR EJERCICIOS',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedExercises.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _selectedExercises.removeAt(oldIndex);
                      _selectedExercises.insert(newIndex, item);
                    });
                    setModalState(() {});
                  },
                  itemBuilder: (context, index) {
                    return _buildConfigExerciseCard(index, setModalState);
                  },
                ),
              ),
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
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                          _saveExercises();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
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
                            const Icon(Icons.save, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'GUARDAR EJERCICIOS',
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
        ),
      ),
    );
  }

  Widget _buildConfigExerciseCard(int index, StateSetter setModalState) {
    final exercise = _selectedExercises[index];

    return Container(
      key: ValueKey(exercise['exercise_id']),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.drag_indicator,
                color: Colors.orangeAccent.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['exercise_name'],
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      exercise['primary_muscle']?.toString().toUpperCase() ??
                          '',
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _removeExercise(index);
                  });
                  setModalState(() {});
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  'Series',
                  exercise['sets'],
                  (value) {
                    setState(() {
                      exercise['sets'] = value;
                    });
                    setModalState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextInput(
                  'Reps',
                  exercise['reps'],
                  (value) {
                    setState(() {
                      exercise['reps'] = value;
                    });
                    setModalState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  'Peso (kg)',
                  exercise['target_weight'],
                  (value) {
                    setState(() {
                      exercise['target_weight'] = value;
                    });
                    setModalState(() {});
                  },
                  nullable: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberInput(
                  'Descanso (s)',
                  exercise['rest_seconds'],
                  (value) {
                    setState(() {
                      exercise['rest_seconds'] = value;
                    });
                    setModalState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(
    String label,
    int? value,
    Function(int) onChanged, {
    bool nullable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (value != null && value > (nullable ? 0 : 1)) {
                    onChanged(value - 1);
                  }
                },
                icon: const Icon(Icons.remove, size: 16),
                color: Colors.orangeAccent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                value?.toString() ?? '0',
                style: GoogleFonts.montserrat(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                onPressed: () {
                  onChanged((value ?? 0) + 1);
                },
                icon: const Icon(Icons.add, size: 16),
                color: Colors.orangeAccent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.orangeAccent),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
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
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

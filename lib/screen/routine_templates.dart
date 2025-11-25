import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoutineTemplates {
  static List<Map<String, dynamic>> getAllTemplates() {
    return [
      fullBody3xWeek(),
      pushPullLegs(),
      upperLowerSplit(),
      broSplit(),
    ];
  }

  // PLANTILLA 1: Full Body 3x Semana (Principiantes)
  static Map<String, dynamic> fullBody3xWeek() {
    return {
      'title': 'Full Body 3x Semana',
      'description':
          'Rutina completa para principiantes. Entrena todo el cuerpo 3 veces por semana.',
      'level': 'Principiante',
      'icon': Icons.accessibility_new,
      'color': Colors.green,
      'days': [
        {
          'title': 'Día A - Full Body',
          'duration_minutes': 60,
          'notes': 'Enfócate en la técnica correcta',
          'exercises': [
            {'name': 'Sentadilla', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Press Banca', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Remo con Barra', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Press Militar', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Curl de Bíceps', 'sets': 3, 'reps': '12-15', 'rest': 60},
            {'name': 'Press Francés', 'sets': 3, 'reps': '12-15', 'rest': 60},
          ],
        },
        {
          'title': 'Día B - Full Body',
          'duration_minutes': 60,
          'notes': 'Variante con ejercicios diferentes',
          'exercises': [
            {'name': 'Peso Muerto', 'sets': 3, 'reps': '8-10', 'rest': 120},
            {'name': 'Press Banca', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Dominadas', 'sets': 3, 'reps': '8-10', 'rest': 90},
            {
              'name': 'Elevaciones Laterales',
              'sets': 3,
              'reps': '12-15',
              'rest': 60
            },
            {'name': 'Zancadas', 'sets': 3, 'reps': '10-12', 'rest': 60},
          ],
        },
        {
          'title': 'Día C - Full Body',
          'duration_minutes': 60,
          'notes': 'Último día de la semana, mantén la intensidad',
          'exercises': [
            {'name': 'Sentadilla', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Press Banca', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Remo con Barra', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Press Militar', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {'name': 'Curl de Bíceps', 'sets': 3, 'reps': '12-15', 'rest': 60},
          ],
        },
      ],
    };
  }

  // PLANTILLA 2: Push/Pull/Legs (Intermedio)
  static Map<String, dynamic> pushPullLegs() {
    return {
      'title': 'Push/Pull/Legs',
      'description':
          'División clásica. Empuje, tirón y piernas en días separados.',
      'level': 'Intermedio',
      'icon': Icons.fitness_center,
      'color': Colors.blue,
      'days': [
        {
          'title': 'Push - Empuje',
          'duration_minutes': 70,
          'notes': 'Pecho, hombros y tríceps',
          'exercises': [
            {'name': 'Press Banca', 'sets': 4, 'reps': '8-10', 'rest': 120},
            {'name': 'Press Militar', 'sets': 4, 'reps': '8-10', 'rest': 90},
            {'name': 'Press Francés', 'sets': 3, 'reps': '10-12', 'rest': 90},
            {
              'name': 'Elevaciones Laterales',
              'sets': 3,
              'reps': '12-15',
              'rest': 60
            },
          ],
        },
        {
          'title': 'Pull - Tirón',
          'duration_minutes': 70,
          'notes': 'Espalda y bíceps',
          'exercises': [
            {'name': 'Peso Muerto', 'sets': 4, 'reps': '6-8', 'rest': 180},
            {'name': 'Dominadas', 'sets': 4, 'reps': '8-10', 'rest': 120},
            {'name': 'Remo con Barra', 'sets': 4, 'reps': '8-10', 'rest': 90},
            {'name': 'Curl de Bíceps', 'sets': 3, 'reps': '10-12', 'rest': 60},
          ],
        },
        {
          'title': 'Legs - Piernas',
          'duration_minutes': 75,
          'notes': 'Día de piernas completo',
          'exercises': [
            {'name': 'Sentadilla', 'sets': 4, 'reps': '8-10', 'rest': 180},
            {'name': 'Peso Muerto', 'sets': 4, 'reps': '8-10', 'rest': 150},
            {'name': 'Zancadas', 'sets': 3, 'reps': '10-12', 'rest': 90},
          ],
        },
      ],
    };
  }

  // PLANTILLA 3: Upper/Lower Split (Intermedio)
  static Map<String, dynamic> upperLowerSplit() {
    return {
      'title': 'Upper/Lower Split',
      'description': 'Divide cuerpo superior e inferior. 4 días por semana.',
      'level': 'Intermedio',
      'icon': Icons.swap_vert,
      'color': Colors.purple,
      'days': [
        {
          'title': 'Upper A - Superior',
          'duration_minutes': 70,
          'notes': 'Énfasis en fuerza',
          'exercises': [
            {'name': 'Press Banca', 'sets': 4, 'reps': '6-8', 'rest': 180},
            {'name': 'Remo con Barra', 'sets': 4, 'reps': '6-8', 'rest': 150},
            {'name': 'Press Militar', 'sets': 3, 'reps': '8-10', 'rest': 120},
            {'name': 'Dominadas', 'sets': 3, 'reps': '8-10', 'rest': 120},
            {'name': 'Curl de Bíceps', 'sets': 3, 'reps': '10-12', 'rest': 60},
            {'name': 'Press Francés', 'sets': 3, 'reps': '10-12', 'rest': 60},
          ],
        },
        {
          'title': 'Lower A - Inferior',
          'duration_minutes': 70,
          'notes': 'Enfoque en fuerza de piernas',
          'exercises': [
            {'name': 'Sentadilla', 'sets': 4, 'reps': '6-8', 'rest': 180},
            {'name': 'Peso Muerto', 'sets': 4, 'reps': '6-8', 'rest': 180},
            {'name': 'Zancadas', 'sets': 3, 'reps': '10-12', 'rest': 90},
          ],
        },
        {
          'title': 'Upper B - Superior',
          'duration_minutes': 70,
          'notes': 'Énfasis en hipertrofia',
          'exercises': [
            {'name': 'Press Banca', 'sets': 4, 'reps': '10-12', 'rest': 90},
            {'name': 'Remo con Barra', 'sets': 4, 'reps': '10-12', 'rest': 90},
            {'name': 'Press Militar', 'sets': 3, 'reps': '12-15', 'rest': 60},
            {
              'name': 'Elevaciones Laterales',
              'sets': 3,
              'reps': '12-15',
              'rest': 60
            },
            {'name': 'Curl de Bíceps', 'sets': 3, 'reps': '12-15', 'rest': 60},
          ],
        },
        {
          'title': 'Lower B - Inferior',
          'duration_minutes': 70,
          'notes': 'Mayor volumen de entrenamiento',
          'exercises': [
            {'name': 'Sentadilla', 'sets': 4, 'reps': '10-12', 'rest': 120},
            {'name': 'Peso Muerto', 'sets': 3, 'reps': '10-12', 'rest': 120},
            {'name': 'Zancadas', 'sets': 4, 'reps': '12-15', 'rest': 90},
          ],
        },
      ],
    };
  }

  // PLANTILLA 4: Bro Split (Avanzado)
  static Map<String, dynamic> broSplit() {
    return {
      'title': 'Bro Split',
      'description': 'Un grupo muscular por día. 5 días de entrenamiento.',
      'level': 'Avanzado',
      'icon': Icons.sports_martial_arts,
      'color': Colors.red,
      'days': [
        {
          'title': 'Lunes - Pecho',
          'duration_minutes': 75,
          'notes': 'Día internacional del pecho',
          'exercises': [
            {'name': 'Press Banca', 'sets': 5, 'reps': '6-8', 'rest': 180},
            {'name': 'Press Banca', 'sets': 4, 'reps': '10-12', 'rest': 90},
          ],
        },
        {
          'title': 'Martes - Espalda',
          'duration_minutes': 80,
          'notes': 'Espalda ancha y fuerte',
          'exercises': [
            {'name': 'Peso Muerto', 'sets': 5, 'reps': '5-6', 'rest': 240},
            {'name': 'Dominadas', 'sets': 4, 'reps': '8-10', 'rest': 120},
            {'name': 'Remo con Barra', 'sets': 4, 'reps': '8-10', 'rest': 90},
          ],
        },
        {
          'title': 'Miércoles - Hombros',
          'duration_minutes': 60,
          'notes': 'Hombros 3D',
          'exercises': [
            {'name': 'Press Militar', 'sets': 5, 'reps': '6-8', 'rest': 150},
            {
              'name': 'Elevaciones Laterales',
              'sets': 4,
              'reps': '12-15',
              'rest': 60
            },
          ],
        },
        {
          'title': 'Jueves - Piernas',
          'duration_minutes': 90,
          'notes': 'Nunca te saltes el leg day',
          'exercises': [
            {'name': 'Sentadilla', 'sets': 5, 'reps': '6-8', 'rest': 240},
            {'name': 'Peso Muerto', 'sets': 4, 'reps': '8-10', 'rest': 180},
            {'name': 'Zancadas', 'sets': 4, 'reps': '10-12', 'rest': 90},
          ],
        },
        {
          'title': 'Viernes - Brazos',
          'duration_minutes': 60,
          'notes': 'Pump de fin de semana',
          'exercises': [
            {'name': 'Curl de Bíceps', 'sets': 4, 'reps': '10-12', 'rest': 60},
            {'name': 'Press Francés', 'sets': 4, 'reps': '10-12', 'rest': 60},
            {'name': 'Curl de Bíceps', 'sets': 3, 'reps': '12-15', 'rest': 60},
          ],
        },
      ],
    };
  }
}

// Widget para mostrar selector de plantillas
class TemplateSelector extends StatelessWidget {
  final Function(Map<String, dynamic>) onTemplateSelected;

  const TemplateSelector({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = RoutineTemplates.getAllTemplates();

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
                Text(
                  'SELECCIONA UNA PLANTILLA',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.orangeAccent,
                    fontSize: 22,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.orangeAccent),
                ),
              ],
            ),
          ),

          // Lista de plantillas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(context, template);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, Map<String, dynamic> template) {
    final level = template['level'] as String;
    final color = template['color'] as Color;
    final icon = template['icon'] as IconData;
    final dayCount = (template['days'] as List).length;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTemplateSelected(template);
      },
      child: Container(
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
              color: color.withOpacity(0.3),
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['title'],
                        style: GoogleFonts.bebasNeue(
                          color: color,
                          fontSize: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color, width: 1),
                        ),
                        child: Text(
                          level.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              template['description'],
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: color.withOpacity(0.7), size: 18),
                const SizedBox(width: 8),
                Text(
                  '$dayCount días de entrenamiento',
                  style: GoogleFonts.montserrat(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: color, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

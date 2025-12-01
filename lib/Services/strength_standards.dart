import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:flutter/material.dart';

/// Servicio para calcular rankings de fuerza usando procedimiento almacenado
class StrengthService {
  // Colores de rangos
  static const Map<String, Color> rankColors = {
    'Novato': Color(0xFF9E9E9E), // Gris
    'Intermedio': Color(0xFF4CAF50), // Verde
    'Avanzado': Color(0xFF2196F3), // Azul
    'Élite': Color(0xFFFF9800), // Naranja/Oro
  };

  /// Obtiene el ranking completo del usuario usando el procedimiento SQL
  static Future<Map<String, dynamic>> getUserStrengthRank(String userId) async {
    try {
      print('🏋️ Calculando ranking de fuerza para usuario: $userId');

      // 1. Obtener ranking general
      final overallResult = await SupabaseConfig.client
          .rpc('get_overall_strength_rank', params: {'p_user_id': userId});

      if (overallResult == null || overallResult.isEmpty) {
        return {
          'overall_rank': 'Sin datos',
          'rank_index': 0,
          'strength_score': 0.0,
          'valid_lifts': 0,
          'body_weight': 75.0,
          'lifts_analysis': {},
        };
      }

      final overall = overallResult[0];

      // 2. Obtener análisis por ejercicio
      final liftsResult = await SupabaseConfig.client.rpc(
        'calculate_strength_rank',
        params: {
          'p_user_id': userId,
          'p_body_weight': overall['body_weight'],
        },
      );

      // Convertir a Map para fácil acceso
      Map<String, dynamic> liftsAnalysis = {};
      if (liftsResult != null) {
        for (var lift in liftsResult) {
          liftsAnalysis[lift['exercise_name']] = {
            'exercise': lift['exercise_name'],
            'weight': lift['max_weight'],
            'ratio': lift['ratio'],
            'rank': lift['rank'],
            'score': lift['score'],
            'next_target': lift['next_rank'] != null
                ? {
                    'rank': lift['next_rank'],
                    'target_weight': lift['next_target_weight'],
                    'progress': lift['progress'],
                  }
                : null,
          };
        }
      }

      return {
        'overall_rank': overall['overall_rank'],
        'rank_index': overall['rank_index'],
        'strength_score': overall['strength_score'],
        'valid_lifts': overall['valid_lifts'],
        'body_weight': overall['body_weight'],
        'lifts_analysis': liftsAnalysis,
      };
    } catch (e) {
      print('❌ Error al obtener ranking: $e');
      rethrow;
    }
  }

  /// Obtiene solo el ranking de un ejercicio específico
  static Future<Map<String, dynamic>?> getExerciseRank(
    String userId,
    String exerciseName,
  ) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'calculate_strength_rank',
        params: {'p_user_id': userId},
      );

      if (result == null) return null;

      for (var lift in result) {
        if (lift['exercise_name'].toLowerCase() ==
            exerciseName.toLowerCase()) {
          return {
            'exercise': lift['exercise_name'],
            'weight': lift['max_weight'],
            'ratio': lift['ratio'],
            'rank': lift['rank'],
            'score': lift['score'],
            'next_target': lift['next_rank'] != null
                ? {
                    'rank': lift['next_rank'],
                    'target_weight': lift['next_target_weight'],
                    'progress': lift['progress'],
                  }
                : null,
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener ranking de ejercicio: $e');
      return null;
    }
  }

  /// Obtiene emoji del rango
  static String getRankEmoji(String rank) {
    switch (rank) {
      case 'Élite':
        return '👑';
      case 'Avanzado':
        return '💪';
      case 'Intermedio':
        return '💚';
      case 'Novato':
        return '🌱';
      default:
        return '❓';
    }
  }

  /// Obtiene descripción del rango
  static String getRankDescription(String rank) {
    switch (rank) {
      case 'Élite':
        return 'Fuerza excepcional. Nivel competitivo avanzado.';
      case 'Avanzado':
        return 'Fuerza impresionante. Años de entrenamiento consistente.';
      case 'Intermedio':
        return 'Buen nivel de fuerza. Entrenamiento regular efectivo.';
      case 'Novato':
        return 'Comenzando el viaje. ¡Sigue entrenando!';
      default:
        return 'Completa entrenamientos para obtener tu clasificación.';
    }
  }

  /// Formatea el ratio de fuerza
  static String formatRatio(double ratio) {
    return '${ratio.toStringAsFixed(2)}x';
  }

  /// Lista de ejercicios principales para seguimiento
  static const List<String> mainLifts = [
    'Sentadilla',
    'Press Banca',
    'Peso Muerto',
    'Press Militar',
  ];

  /// Verifica si un ejercicio es principal
  static bool isMainLift(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    return lowerName.contains('sentadilla') ||
        lowerName.contains('squat') ||
        lowerName.contains('press banca') ||
        lowerName.contains('bench') ||
        lowerName.contains('peso muerto') ||
        lowerName.contains('deadlift') ||
        lowerName.contains('press militar') ||
        lowerName.contains('overhead') ||
        lowerName.contains('military');
  }

  /// Obtiene el color del rango
  static Color getRankColor(String rank) {
    return rankColors[rank] ?? Colors.grey;
  }

  /// Obtiene sugerencias para mejorar
  static List<String> getImprovementTips(String rank) {
    switch (rank) {
      case 'Novato':
        return [
          'Enfócate en la técnica correcta antes que en el peso',
          'Sé consistente: entrena 3-4 veces por semana',
          'Come suficiente proteína (1.6-2g por kg de peso)',
          'Descansa adecuadamente entre sesiones',
          'Sigue una progresión lineal simple',
        ];
      case 'Intermedio':
        return [
          'Incorpora periodización en tu entrenamiento',
          'Varía el rango de repeticiones (5-15 reps)',
          'Trabaja en tus puntos débiles específicos',
          'Considera un deload cada 4-6 semanas',
          'Optimiza tu recuperación y nutrición',
        ];
      case 'Avanzado':
        return [
          'Implementa bloques de especialización',
          'Usa técnicas avanzadas (clusters, rest-pause)',
          'Monitorea tu fatiga cuidadosamente',
          'Considera trabajar con un coach',
          'Perfecciona cada aspecto de tu técnica',
        ];
      case 'Élite':
        return [
          'Mantén la consistencia a largo plazo',
          'Previene lesiones con trabajo preventivo',
          'Especialízate en tus mejores levantamientos',
          'Considera competir si te interesa',
          '¡Sigue siendo una inspiración!',
        ];
      default:
        return ['Completa entrenamientos para obtener sugerencias'];
    }
  }

  /// Calcula el tiempo estimado para alcanzar el siguiente rango
  static String estimateTimeToNextRank(double currentProgress) {
    // Estimación muy aproximada basada en progreso actual
    if (currentProgress >= 0.9) {
      return '1-2 meses';
    } else if (currentProgress >= 0.7) {
      return '2-4 meses';
    } else if (currentProgress >= 0.5) {
      return '4-6 meses';
    } else if (currentProgress >= 0.3) {
      return '6-12 meses';
    } else {
      return '12+ meses';
    }
  }
}
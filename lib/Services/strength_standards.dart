import 'dart:math';
// Necesitas importar esto para jsonDecode
import 'dart:convert';
import 'package:flutter/material.dart';

/// Sistema de rangos basado en Strength Level Standards
/// Fuente: https://strengthlevel.com/strength-standards
class StrengthStandards {
  // Ejercicios principales para clasificación
  static const List<String> mainLifts = [
    'Sentadilla',
    'Press Banca',
    'Peso Muerto',
    'Press Militar',
  ];

  // Rangos: Novato, Intermedio, Avanzado, Élite
  static const List<String> ranks = [
    'Novato',
    'Intermedio',
    'Avanzado',
    'Élite'
  ];

  static const Map<String, Color> rankColors = {
    'Novato': Color(0xFF9E9E9E), // Gris
    'Intermedio': Color(0xFF4CAF50), // Verde
    'Avanzado': Color(0xFF2196F3), // Azul
    'Élite': Color(0xFFFF9800), // Naranja/Oro
  };

  /// Calcula el rango de un usuario basado en peso corporal y levantamientos
  static Map<String, dynamic> calculateUserRank({
    required double bodyWeight, // kg
    required Map<String, double> maxLifts, // ejercicio -> peso máximo en kg
  }) {
    if (bodyWeight <= 0) {
      return {
        'overall_rank': 'Sin datos',
        'rank_index': 0,
        'lifts_analysis': {},
        'strength_score': 0.0,
      };
    }

    Map<String, Map<String, dynamic>> liftsAnalysis = {};
    double totalScore = 0;
    int validLifts = 0;

    for (var exercise in mainLifts) {
      // Buscar el ejercicio en los levantamientos del usuario (case insensitive)
      double? weight;
      for (var entry in maxLifts.entries) {
        if (entry.key.toLowerCase().contains(exercise.toLowerCase()) ||
            exercise.toLowerCase().contains(entry.key.toLowerCase())) {
          weight = entry.value;
          break;
        }
      }

      if (weight != null && weight > 0) {
        final analysis = _analyzeExercise(exercise, bodyWeight, weight);
        liftsAnalysis[exercise] = analysis;
        totalScore += analysis['score'];
        validLifts++;
      }
    }

    // Calcular rango general
    final avgScore = validLifts > 0 ? totalScore / validLifts : 0.0;
    final overallRank = _scoreToRank(avgScore);

    return {
      'overall_rank': overallRank,
      'rank_index': ranks.indexOf(overallRank),
      'lifts_analysis': liftsAnalysis,
      'strength_score': avgScore,
      'valid_lifts': validLifts,
    };
  }

  /// Analiza un ejercicio específico
  static Map<String, dynamic> _analyzeExercise(
    String exercise,
    double bodyWeight,
    double liftedWeight,
  ) {
    final standards = _getStandards(exercise, bodyWeight);
    final ratio = liftedWeight / bodyWeight;

    // Calcular score (0-3) basado en estándares
    double score;
    String rank;

    if (ratio >= standards['elite']!) {
      score = 3.0;
      rank = 'Élite';
    } else if (ratio >= standards['advanced']!) {
      score = 2.0 +
          (ratio - standards['advanced']!) /
              (standards['elite']! - standards['advanced']!);
      rank = 'Avanzado';
    } else if (ratio >= standards['intermediate']!) {
      score = 1.0 +
          (ratio - standards['intermediate']!) /
              (standards['advanced']! - standards['intermediate']!);
      rank = 'Intermedio';
    } else {
      score = (ratio / standards['intermediate']!).clamp(0.0, 1.0);
      rank = 'Novato';
    }

    return {
      'exercise': exercise,
      'weight': liftedWeight,
      'ratio': ratio,
      'rank': rank,
      'score': score,
      'standards': standards,
      'next_target': _getNextTarget(ratio, standards),
    };
  }

  /// Obtiene estándares de fuerza para un ejercicio
  /// Basado en Strength Level (promedios para hombre de 75kg)
  /// Valores expresados como múltiplos del peso corporal
  static Map<String, double> _getStandards(String exercise, double bodyWeight) {
    // Fórmulas de regresión basadas en datos de strengthlevel.com
    // Ajustadas para peso corporal usando coeficiente de Allometric Scaling
    final bwFactor = pow(bodyWeight / 75.0, 0.66).toDouble();

    switch (exercise.toLowerCase()) {
      case 'sentadilla':
        return {
          'novice': 0.78 * bwFactor,
          'intermediate': 1.42 * bwFactor,
          'advanced': 2.05 * bwFactor,
          'elite': 2.72 * bwFactor,
        };

      case 'press banca':
      case 'bench press':
        return {
          'novice': 0.53 * bwFactor,
          'intermediate': 0.97 * bwFactor,
          'advanced': 1.45 * bwFactor,
          'elite': 1.96 * bwFactor,
        };

      case 'peso muerto':
      case 'deadlift':
        return {
          'novice': 0.97 * bwFactor,
          'intermediate': 1.74 * bwFactor,
          'advanced': 2.51 * bwFactor,
          'elite': 3.31 * bwFactor,
        };

      case 'press militar':
      case 'overhead press':
        return {
          'novice': 0.35 * bwFactor,
          'intermediate': 0.65 * bwFactor,
          'advanced': 0.97 * bwFactor,
          'elite': 1.32 * bwFactor,
        };

      default:
        // Estándar genérico
        return {
          'novice': 0.5 * bwFactor,
          'intermediate': 1.0 * bwFactor,
          'advanced': 1.5 * bwFactor,
          'elite': 2.0 * bwFactor,
        };
    }
  }

  /// Convierte score a rango
  static String _scoreToRank(double score) {
    if (score >= 3.0) return 'Élite';
    if (score >= 2.0) return 'Avanzado';
    if (score >= 1.0) return 'Intermedio';
    return 'Novato';
  }

  /// Calcula el siguiente objetivo
  static Map<String, dynamic>? _getNextTarget(
    double currentRatio,
    Map<String, double> standards,
  ) {
    if (currentRatio < standards['intermediate']!) {
      return {
        'rank': 'Intermedio',
        'target_ratio': standards['intermediate'],
        'progress': currentRatio / standards['intermediate']!,
      };
    } else if (currentRatio < standards['advanced']!) {
      return {
        'rank': 'Avanzado',
        'target_ratio': standards['advanced'],
        'progress': (currentRatio - standards['intermediate']!) /
            (standards['advanced']! - standards['intermediate']!),
      };
    } else if (currentRatio < standards['elite']!) {
      return {
        'rank': 'Élite',
        'target_ratio': standards['elite'],
        'progress': (currentRatio - standards['advanced']!) /
            (standards['elite']! - standards['advanced']!),
      };
    }
    return null; // Ya es élite
  }

  /// Extrae el peso máximo de cada ejercicio desde workout_logs
  static Future<Map<String, double>> extractMaxLiftsFromLogs(
    List<Map<String, dynamic>> workoutLogs,
  ) async {
    Map<String, double> maxLifts = {};

    for (var workout in workoutLogs) {
      if (workout['exercises_log'] != null) {
        try {
          final exercisesLog = jsonDecode(workout['exercises_log']);

          for (var exercise in exercisesLog) {
            final exerciseName = exercise['exercise_name'] ?? '';
            if (exerciseName.isEmpty) continue;

            final sets = exercise['sets'] ?? [];
            for (var set in sets) {
              final weight = (set['weight'] ?? 0).toDouble();
              if (weight > 0) {
                if (!maxLifts.containsKey(exerciseName) ||
                    weight > maxLifts[exerciseName]!) {
                  maxLifts[exerciseName] = weight;
                }
              }
            }
          }
        } catch (e) {
          print('Error parseando exercises_log: $e');
        }
      }
    }

    return maxLifts;
  }

  /// Obtiene el emoji del rango
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

  /// Calcula peso objetivo para siguiente rango
  static double calculateTargetWeight(
    double bodyWeight,
    String exercise,
    String currentRank,
  ) {
    final standards = _getStandards(exercise, bodyWeight);
    String nextRank;

    switch (currentRank) {
      case 'Novato':
        nextRank = 'intermediate';
        break;
      case 'Intermedio':
        nextRank = 'advanced';
        break;
      case 'Avanzado':
        nextRank = 'elite';
        break;
      default:
        return 0;
    }

    return standards[nextRank]! * bodyWeight;
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:neuro_gym/bd/supabase_config.dart';

class RoutineRecommenderService {
  // API Key de Hugging Face
  static const String _apiKey = '';
  static const String _modelId = 'sentence-transformers/all-MiniLM-L6-v2';
  static const String _apiUrl =
      'https://api-inference.huggingface.co/pipeline/feature-extraction/$_modelId';

  /// Prueba la conexión con Hugging Face (útil para diagnosticar) lkpofk
  static Future<bool> testConnection() async {
    try {
      print('🧪 Probando conexión con Hugging Face...');

      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': 'test',
          'options': {'wait_for_model': true}
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al conectar con Hugging Face');
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Conexión exitosa con Hugging Face');
        return true;
      } else if (response.statusCode == 503) {
        print('⏳ Modelo cargándose... (503)');
        return true; // El modelo está disponible, solo necesita cargarse
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error de conexión: $e');
      return false;
    }
  }

  /// Genera recomendaciones basadas en preferencias del usuario
  static Future<List<Map<String, dynamic>>> getRecommendations({
    required String userGoal,
    required int experienceLevel,
    required List<String> preferredMuscles,
    required int daysPerWeek,
    int limit = 5,
  }) async {
    try {
      print('🤖 Generando recomendaciones para: $userGoal');

      // 1. Construir query semántico basado en preferencias
      final query = _buildSemanticQuery(
        userGoal,
        experienceLevel,
        preferredMuscles,
        daysPerWeek,
      );

      print('🔍 Query generado: "$query"');

      // 2. Generar embedding del query
      final queryEmbedding = await _getEmbedding(query);

      // 3. Obtener todas las rutinas con embeddings
      final routines = await _getRoutinesWithEmbeddings();

      if (routines.isEmpty) {
        print('⚠️ No hay rutinas con embeddings. Generando...');
        await generateAllRoutineEmbeddings();
        return getRecommendations(
          userGoal: userGoal,
          experienceLevel: experienceLevel,
          preferredMuscles: preferredMuscles,
          daysPerWeek: daysPerWeek,
          limit: limit,
        );
      }

      // 4. Calcular similitudes
      final scored = routines.map((routine) {
        final routineEmbedding = List<double>.from(
          jsonDecode(routine['embedding']),
        );
        final similarity = _cosineSimilarity(queryEmbedding, routineEmbedding);

        return {
          ...routine,
          'similarity_score': similarity,
          'match_percentage': (similarity * 100).toStringAsFixed(1),
        };
      }).toList();

      // 5. Ordenar por similitud
      scored.sort((a, b) => (b['similarity_score'] as double)
          .compareTo(a['similarity_score'] as double));

      // 6. Aplicar filtros adicionales
      final filtered = scored.where((routine) {
        return true; // Por ahora aceptamos todas
      }).toList();

      final top = filtered.take(limit).toList();

      print('🎯 Top ${top.length} recomendaciones:');
      for (var i = 0; i < top.length; i++) {
        print(
            '  ${i + 1}. ${top[i]['title']} - Match: ${top[i]['match_percentage']}%');
      }

      return top;
    } catch (e) {
      print('❌ Error al generar recomendaciones: $e');
      rethrow;
    }
  }

  /// Recomienda rutinas similares a una existente
  static Future<List<Map<String, dynamic>>> getSimilarRoutines(
    String routineId,
    int limit,
  ) async {
    try {
      print('🔎 Buscando rutinas similares a: $routineId');

      final baseRoutine = await SupabaseConfig.client
          .from('routines')
          .select()
          .eq('id', routineId)
          .single();

      if (baseRoutine['embedding'] == null) {
        throw Exception('La rutina no tiene embedding generado');
      }

      final baseEmbedding = List<double>.from(
        jsonDecode(baseRoutine['embedding']),
      );

      final allRoutines = await SupabaseConfig.client
          .from('routines')
          .select()
          .neq('id', routineId)
          .not('embedding', 'is', null);

      final scored = allRoutines.map((routine) {
        final routineEmbedding = List<double>.from(
          jsonDecode(routine['embedding']),
        );
        final similarity = _cosineSimilarity(baseEmbedding, routineEmbedding);

        return {
          ...routine,
          'similarity_score': similarity,
          'match_percentage': (similarity * 100).toStringAsFixed(1),
        };
      }).toList();

      scored.sort((a, b) => (b['similarity_score'] as double)
          .compareTo(a['similarity_score'] as double));

      return scored.take(limit).toList();
    } catch (e) {
      print('❌ Error al buscar rutinas similares: $e');
      rethrow;
    }
  }

  /// Genera embeddings para todas las rutinas en la BD
  static Future<void> generateAllRoutineEmbeddings() async {
    try {
      print('🔄 Generando embeddings para todas las rutinas...');

      final routines = await SupabaseConfig.client
          .from('routines')
          .select('id, title, description');

      print('📊 Encontradas ${routines.length} rutinas');

      int processed = 0;
      int errors = 0;

      for (var routine in routines) {
        try {
          final text = _buildRoutineDescription(routine);

          print('⏳ Procesando: ${routine['title']}');
          final embedding = await _getEmbedding(text);

          await SupabaseConfig.client.from('routines').update({
            'embedding': jsonEncode(embedding),
          }).eq('id', routine['id']);

          processed++;
          print('✅ [$processed/${routines.length}] ${routine['title']}');

          // Pausa para no saturar la API
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          errors++;
          print('⚠️ Error en rutina ${routine['id']}: $e');
        }
      }

      print('🎉 Embeddings generados: $processed/${routines.length}');
      if (errors > 0) {
        print('⚠️ Errores encontrados: $errors');
      }
    } catch (e) {
      print('❌ Error al generar embeddings: $e');
      rethrow;
    }
  }

  /// Construye query semántico basado en preferencias
  static String _buildSemanticQuery(
    String userGoal,
    int experienceLevel,
    List<String> preferredMuscles,
    int daysPerWeek,
  ) {
    final level = experienceLevel == 1
        ? 'principiante'
        : experienceLevel == 2
            ? 'intermedio'
            : 'avanzado';

    final muscles = preferredMuscles.join(', ');

    return '$userGoal rutina de $level $daysPerWeek días por semana enfocada en $muscles';
  }

  /// Construye descripción de rutina para embedding
  static String _buildRoutineDescription(Map<String, dynamic> routine) {
    final title = routine['title'] ?? '';
    final description = routine['description'] ?? '';
    return '$title $description';
  }

  /// Genera embedding usando Hugging Face API (con reintentos y mejor manejo)
  static Future<List<double>> _getEmbedding(String text) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        print('🔄 Intento ${attempt + 1}/$maxRetries de generar embedding...');

        final response = await http
            .post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'inputs': text,
            'options': {'wait_for_model': true}
          }),
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout: La API tardó demasiado en responder');
          },
        );

        print('📡 Status Code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final dynamic result = jsonDecode(response.body);

          List<double> embedding;
          if (result is List && result.isNotEmpty) {
            if (result[0] is List) {
              embedding = List<double>.from(result[0].map((e) => e.toDouble()));
            } else {
              embedding = List<double>.from(result.map((e) => e.toDouble()));
            }
          } else {
            throw Exception('Formato de respuesta inesperado: $result');
          }

          print('✅ Embedding generado (${embedding.length} dimensiones)');
          return embedding;
        } else if (response.statusCode == 503) {
          print('⏳ Modelo cargándose (503), esperando 10 segundos...');
          await Future.delayed(const Duration(seconds: 10));
          attempt++;
          continue;
        } else if (response.statusCode == 401) {
          throw Exception(
              'API Key inválida. Verifica tu token en https://huggingface.co/settings/tokens');
        } else {
          throw Exception(
            'Error ${response.statusCode}: ${response.body}',
          );
        }
      } catch (e) {
        attempt++;
        print('❌ Error en intento $attempt: $e');

        if (attempt >= maxRetries) {
          throw Exception(
              'No se pudo conectar a Hugging Face después de $maxRetries intentos.\n'
              'Error: $e\n'
              'Verifica:\n'
              '1. Tu conexión a internet\n'
              '2. Que la API key sea válida\n'
              '3. Los permisos de internet en AndroidManifest.xml');
        }

        // Espera progresiva entre reintentos
        await Future.delayed(Duration(seconds: attempt * 3));
      }
    }

    throw Exception('Error desconocido al generar embedding');
  }

  /// Obtiene rutinas con embeddings de Supabase
  static Future<List<Map<String, dynamic>>> _getRoutinesWithEmbeddings() async {
    try {
      final routines = await SupabaseConfig.client
          .from('routines')
          .select('id, title, description, embedding, is_public, owner_user_id')
          .not('embedding', 'is', null);

      return List<Map<String, dynamic>>.from(routines);
    } catch (e) {
      print('❌ Error al cargar rutinas: $e');
      return [];
    }
  }

  /// Calcula similitud coseno entre dos embeddings
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw Exception('Los embeddings deben tener la misma dimensión');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}

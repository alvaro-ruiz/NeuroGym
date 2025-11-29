import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoutineRecommenderService {
  // API Key para GROQ
  static final _groqApiKey = dotenv.env['IA_API_KEY'];

  static const String _groqModel = "llama-3.1-8b-instant";
  static const String _groqUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  /// Generar rutina con GROQ
  static Future<String> generateAIBasedRoutine({
    required String userGoal,
    required int experienceLevel,
    required List<String> preferredMuscles,
    required int daysPerWeek,
  }) async {
    try {
      print("🤖 Solicitando plan personalizado a Groq...");

      final level = experienceLevel == 1
          ? 'principiante'
          : experienceLevel == 2
              ? 'intermedio'
              : 'avanzado';

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": _groqModel,
          "temperature": 0.7,
          "messages": [
            {
              "role": "system",
              "content":
                  "Eres un entrenador personal experto. Siempre responde con rutinas claras, realistas y seguras."
            },
            {
              "role": "user",
              "content":
                  "Crea una rutina de entrenamiento de $daysPerWeek días.\nObjetivo: $userGoal\nExperiencia: $level\nMúsculos preferidos: ${preferredMuscles.join(", ")}.\nIncluye sets, repeticiones, descansos y recomendaciones."
            }
          ],
        }),
      );

      print("📥 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json["choices"][0]["message"]["content"];
        print("🟢 Respuesta generada por Groq:\n$text");
        return text;
      } else {
        print("❌ Error desde Groq: ${response.body}");
        return "⚠ Error en Groq API: ${response.statusCode}";
      }
    } catch (e) {
      print("💥 Excepción en generateAIBasedRoutine: $e");
      return "🚨 Error inesperado: $e";
    }
  }

  /// =====================================
  /// TU SISTEMA ORIGINAL (NO MODIFICADO)
  /// =====================================
  static Future<bool> testConnection() async {
    try {
      print('🧪 Probando conexión con Groq...');
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "model": _groqModel,
          "messages": [
            {"role": "user", "content": "ping"}
          ]
        }),
      );

      print("📡 Código: ${response.statusCode}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error al conectar: $e");
      return false;
    }
  }

  /// ===============================
  /// 🎯 Modificación en este método
  /// ===============================
  static Future<List<Map<String, dynamic>>> getRecommendations({
    required String userGoal,
    required int experienceLevel,
    required List<String> preferredMuscles,
    required int daysPerWeek,
    int limit = 5,
  }) async {
    final results = <Map<String, dynamic>>[];

    try {
      print("📌 Obteniendo recomendaciones basadas en similitud...");

      final semanticResults = await _getRoutinesWithEmbeddings();

      if (semanticResults.isEmpty) {
        print(
            "⚠ No hay coincidencias en base de datos. Usando IA directamente...");
      }

      /// 🔥 NEW: Llamada a IA Groq para personalización
      final aiPlan = await generateAIBasedRoutine(
        userGoal: userGoal,
        experienceLevel: experienceLevel,
        preferredMuscles: preferredMuscles,
        daysPerWeek: daysPerWeek,
      );

      results.add({
        'id': 'ai-generated',
        'title': 'Plan Personalizado con IA',
        'description': aiPlan,
        'similarity_score': 1.0,
        'ai_generated': true
      });

      return results;
    } catch (e) {
      print("❌ Error en getRecommendations: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _getRoutinesWithEmbeddings() async {
    try {
      final routines = await SupabaseConfig.client
          .from('routines')
          .select('id, title, description, embedding')
          .not('embedding', 'is', null);
      return List<Map<String, dynamic>>.from(routines);
    } catch (e) {
      print("❌ Error al cargar rutinas: $e");
      return [];
    }
  }
}

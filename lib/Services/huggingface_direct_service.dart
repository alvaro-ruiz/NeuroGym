import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// 🤖 Servicio para conectar DIRECTAMENTE con HuggingFace API
///
/// ⚠️ ADVERTENCIA: Este servicio expone el token en el código
/// Solo usar para prototipos y desarrollo local
class HuggingFaceDirectService {
  // ============================================
  // CONFIGURACIÓN
  // ============================================

  /// 🔑 Token de HuggingFace
  static final _apiKey = dotenv.env['HUGGINGFACE_API_KEY'];

  /// 🌐 URL base de la API
  static const String _baseUrl = 'https://api-inference.huggingface.co';

  /// 🧠 Modelo para embeddings
  static const String _modelId = 'sentence-transformers/all-MiniLM-L6-v2';

  /// ⏱️ Timeout para peticiones
  static const Duration _timeout = Duration(seconds: 30);

  // ============================================
  // MÉTODO PRINCIPAL: OBTENER EMBEDDING
  // ============================================

  /// Obtiene el embedding de un texto usando HuggingFace directamente
  static Future<List<double>> getEmbedding(String text) async {
    if (text.isEmpty) {
      throw Exception('El texto no puede estar vacío');
    }

    if (text.length > 5000) {
      throw Exception('El texto no puede exceder 5000 caracteres');
    }

    print(
        '📤 [DIRECT] Enviando texto a HuggingFace: "${text.substring(0, min(50, text.length))}..."');

    try {
      // Construir URL del endpoint
      final url = Uri.parse('$_baseUrl/pipeline/feature-extraction/$_modelId');

      print('🌐 [DIRECT] URL: $url');

      // Preparar headers
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

      // Preparar body
      final body = jsonEncode({
        'inputs': text,
        'options': {
          'wait_for_model': true,
        }
      });

      // Hacer petición HTTP POST
      final response = await http
          .post(
        url,
        headers: headers,
        body: body,
      )
          .timeout(
        _timeout,
        onTimeout: () {
          throw Exception(
              'Timeout: La petición tardó más de ${_timeout.inSeconds} segundos');
        },
      );

      print('📡 [DIRECT] Status code: ${response.statusCode}');

      // Manejar respuestas
      if (response.statusCode == 200) {
        return _parseEmbedding(response.body);
      } else if (response.statusCode == 503) {
        throw Exception('El modelo se está cargando. '
            'Espera 10-20 segundos e intenta de nuevo.');
      } else if (response.statusCode == 401) {
        throw Exception('Error de autenticación. Token inválido.');
      } else if (response.statusCode == 429) {
        throw Exception('Límite de peticiones excedido. '
            'Espera unos minutos.');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception('No hay conexión a internet. '
            'Verifica tu conexión WiFi o datos móviles.');
      }
      rethrow;
    }
  }

  // ============================================
  // PARSEAR RESPUESTA
  // ============================================

  static List<double> _parseEmbedding(String responseBody) {
    try {
      print('🔍 [DIRECT] Parseando respuesta...');

      final dynamic decoded = jsonDecode(responseBody);

      List<double> embedding;

      if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
        embedding =
            List<double>.from(decoded[0].map((e) => (e as num).toDouble()));
      } else if (decoded is List) {
        embedding =
            List<double>.from(decoded.map((e) => (e as num).toDouble()));
      } else {
        throw Exception('Formato de respuesta inesperado');
      }

      print('✅ [DIRECT] Embedding parseado: ${embedding.length} dimensiones');

      if (embedding.isEmpty) {
        throw Exception('El embedding está vacío');
      }

      return embedding;
    } catch (e) {
      throw Exception('Error al parsear embedding: $e');
    }
  }

  // ============================================
  // OBTENER MÚLTIPLES EMBEDDINGS
  // ============================================

  static Future<List<List<double>>> getMultipleEmbeddings(
      List<String> texts) async {
    print('📚 [DIRECT] Obteniendo ${texts.length} embeddings...');

    final List<List<double>> embeddings = [];

    for (int i = 0; i < texts.length; i++) {
      print('📄 [DIRECT] Procesando texto ${i + 1}/${texts.length}...');

      try {
        final embedding = await getEmbedding(texts[i]);
        embeddings.add(embedding);

        // Pausa para no saturar la API
        if (i < texts.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('❌ [DIRECT] Error en texto ${i + 1}: $e');
        rethrow;
      }
    }

    print('✅ [DIRECT] ${embeddings.length} embeddings obtenidos');
    return embeddings;
  }

  // ============================================
  // SIMILITUD COSENO
  // ============================================

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw Exception('Los embeddings deben tener la misma longitud '
          '(a: ${a.length}, b: ${b.length})');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    final similarity = dotProduct / (sqrt(normA) * sqrt(normB));
    return similarity.clamp(0.0, 1.0);
  }

  // ============================================
  // TEST DE CONEXIÓN
  // ============================================

  static Future<bool> testConnection() async {
    try {
      print('🧪 [DIRECT] Probando conexión con HuggingFace...');

      await getEmbedding('test');

      print('✅ [DIRECT] Conexión exitosa');
      return true;
    } catch (e) {
      print('❌ [DIRECT] Error de conexión: $e');
      return false;
    }
  }
}

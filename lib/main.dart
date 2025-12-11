import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'screen/login.dart';
import 'screen/routines.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseConfig.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // Usar AuthWrapper para verificar sesión automáticamente
      home: AuthWrapper(),
    );
  }
}

/// Widget que verifica si hay sesión activa y redirige automáticamente
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _setupAuthListener();
  }

  /// Verificar si hay sesión activa al iniciar
  Future<void> _checkAuthStatus() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      setState(() {
        _isAuthenticated = session != null;
        _isLoading = false;
      });
      print(session != null
          ? '✅ Sesión activa detectada: ${session.user.email}'
          : '❌ No hay sesión activa');
    } catch (e) {
      print('❌ Error al verificar sesión: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  /// Escuchar cambios en el estado de autenticación
  void _setupAuthListener() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        setState(() {
          _isAuthenticated = session != null;
        });
      }
      print(session != null
          ? '🔄 Sesión actualizada: ${session.user.email}'
          : '🔄 Sesión cerrada');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar splash screen mientras se verifica la sesión
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o ícono de tu app
              Icon(
                Icons.bolt,
                color: Colors.orangeAccent,
                size: 80,
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(
                color: Colors.orangeAccent,
              ),
              SizedBox(height: 20),
              Text(
                'NEUROGYM',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Navegar según el estado de autenticación
    return _isAuthenticated
        ? const NeuroGymRoutinesPage()
        : const NeuroGymLoginPage();
  }
}

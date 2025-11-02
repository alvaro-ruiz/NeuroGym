import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register.dart';
import 'routines.dart';

class NeuroGymLoginPage extends StatefulWidget {
  const NeuroGymLoginPage({super.key});

  @override
  State<NeuroGymLoginPage> createState() => _NeuroGymLoginPageState();
}

class _NeuroGymLoginPageState extends State<NeuroGymLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Validaciones básicas
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor completa todos los campos';
          _isLoading = false;
        });
        return;
      }

      // Autenticación con Supabase
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Si el login es exitoso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Login exitoso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Navegar a la pantalla de rutinas
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NeuroGymRoutinesPage(),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono superior
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.orangeAccent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                Text(
                  "NEUROGYM",
                  style: GoogleFonts.bebasNeue(
                    color: Colors.orangeAccent,
                    fontSize: 42,
                    shadows: [
                      Shadow(
                        color: Colors.orangeAccent.withOpacity(0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "INICIAR SESIÓN",
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),

                // Mensaje de error
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

                // Campos
                _buildTextField(
                  "EMAIL",
                  "usuario@neurogym.com",
                  _emailController,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "CONTRASEÑA",
                  "********",
                  _passwordController,
                  obscure: true,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 30),

                // Botón
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shadowColor: Colors.orangeAccent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.orangeAccent),
                            ),
                          )
                        : Text(
                            "ACCEDER",
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.orangeAccent.withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const NeuroGymRegisterPage(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child);
                              },
                            ),
                          );
                        },
                  child: Text(
                    "¿No tienes cuenta? Crear una nueva",
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          style: const TextStyle(color: Colors.orangeAccent),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.6),
            ),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.orangeAccent.withOpacity(0.6)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.orangeAccent.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.orangeAccent, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

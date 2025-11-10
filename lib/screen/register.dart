import 'package:flutter/material.dart';
import "package:google_fonts/google_fonts.dart";
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class NeuroGymRegisterPage extends StatefulWidget {
  const NeuroGymRegisterPage({super.key});

  @override
  State<NeuroGymRegisterPage> createState() => _NeuroGymRegisterPageState();
}

class _NeuroGymRegisterPageState extends State<NeuroGymRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      // Validaciones básicas
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor completa todos los campos';
          _isLoading = false;
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _errorMessage = 'Las contraseñas no coinciden';
          _isLoading = false;
        });
        return;
      }

      if (password.length < 6) {
        setState(() {
          _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
          _isLoading = false;
        });
        return;
      }

      // Registro con Supabase
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
        },
        emailRedirectTo: null, // No redirigir al confirmar email
      );

      // 📋 Imprime los datos traídos de la BD en consola
      print('✅ Registro exitoso');
      print('Usuario ID: ${response.user?.id}');
      print('Email: ${response.user?.email}');
      print('Nombre: ${response.user?.userMetadata?['full_name']}');
      print('Respuesta completa: $response');

      // Guardar datos adicionales en la tabla 'users_profiles'
      if (response.user != null) {
        try {
          await SupabaseConfig.client.from('users_profiles').insert({
            'auth_user_id': response.user!.id,
            'display_name': name,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('✅ Perfil de usuario creado en users_profiles');
        } catch (e) {
          print('⚠️ No se pudo crear perfil: $e');
          // Continúa sin error, el usuario ya está creado en Authentication
        }
      }

      // Si el registro es exitoso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ya puedes iniciar sesión'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al login después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NeuroGymLoginPage()),
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
      print('❌ Error completo: $e');
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono superior
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
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
                  "CREAR NUEVO USUARIO",
                  style: GoogleFonts.montserrat(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),

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

                // Campos de texto
                _buildTextField(
                  "NOMBRE COMPLETO",
                  "Nombre Usuario",
                  _nameController,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                _buildTextField(
                  "CONFIRMAR CONTRASEÑA",
                  "********",
                  _confirmPasswordController,
                  obscure: true,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 30),

                // Botón
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
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
                        horizontal: 40, vertical: 14),
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
                            "CREAR CUENTA",
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
                                  const NeuroGymLoginPage(),
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
                    "¿Ya tienes cuenta? Inicia sesión",
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

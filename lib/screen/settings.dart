import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:neuro_gym/screen/login.dart';
import 'package:neuro_gym/screen/weight_tracker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      print('🔍 Cargando perfil del usuario: $userId');

      final response = await SupabaseConfig.client
          .from('users_profiles')
          .select(
              'id, auth_user_id, display_name, avatar_url, bio, goal, created_at')
          .eq('auth_user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _userProfile = response;
          _nameController.text = response['display_name'] ?? '';
          _bioController.text = response['bio'] ?? '';
        });
      }

      print('✅ Perfil cargado');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar perfil: $e');
      setState(() {
        _errorMessage = 'Error al cargar perfil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final displayName = _nameController.text.trim();
      final bio = _bioController.text.trim();

      if (displayName.isEmpty) {
        throw Exception('El nombre no puede estar vacío');
      }

      print('💾 Actualizando perfil...');

      await SupabaseConfig.client.from('users_profiles').update({
        'display_name': displayName,
        'bio': bio.isEmpty ? null : bio,
      }).eq('auth_user_id', userId);

      print('✅ Perfil actualizado');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        _loadUserProfile();
      }
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.orangeAccent.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Text(
          '¿Cerrar Sesión?',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.montserrat(
                color: Colors.orangeAccent.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'CERRAR SESIÓN',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      print('👋 Cerrando sesión...');

      await SupabaseConfig.client.auth.signOut();

      print('✅ Sesión cerrada');

      if (mounted) {
        // Limpiar el stack de navegación y volver al login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const NeuroGymLoginPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail =
        SupabaseConfig.client.auth.currentUser?.email ?? 'No disponible';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AJUSTES',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orangeAccent,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y email
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orangeAccent.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.orangeAccent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orangeAccent.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.orangeAccent,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          userEmail,
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sección de perfil
                  Text(
                    'PERFIL',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.orangeAccent,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'NOMBRE',
                    'Tu nombre completo',
                    _nameController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    'BIO (OPCIONAL)',
                    'Cuéntanos sobre ti...',
                    _bioController,
                    Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // Botón de actualizar perfil
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 15,
                      shadowColor: Colors.orangeAccent.withOpacity(0.6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'GUARDAR CAMBIOS',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sección de opciones
                  Text(
                    'OPCIONES',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.orangeAccent,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildOptionCard(
                    'Control de Peso',
                    'Registra y sigue tu progreso',
                    Icons.monitor_weight,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeightTrackerPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Botón de cerrar sesión
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'CERRAR SESIÓN',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info de la app
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'NEUROGYM',
                          style: GoogleFonts.bebasNeue(
                            color: Colors.orangeAccent.withOpacity(0.3),
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Versión 1.0.0',
                          style: GoogleFonts.montserrat(
                            color: Colors.orangeAccent.withOpacity(0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.orangeAccent),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.4),
            ),
            prefixIcon: Icon(icon, color: Colors.orangeAccent),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.orangeAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.orangeAccent.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

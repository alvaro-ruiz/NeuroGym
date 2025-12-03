import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:neuro_gym/screen/routine_detail.dart';
import 'package:neuro_gym/screen/creation_rutine.dart';
import 'package:neuro_gym/screen/user_search.dart';
import 'package:neuro_gym/screen/workout_history.dart';

class NeuroGymRoutinesPage extends StatefulWidget {
  const NeuroGymRoutinesPage({super.key});

  @override
  State<NeuroGymRoutinesPage> createState() => _NeuroGymRoutinesPageState();
}

class _NeuroGymRoutinesPageState extends State<NeuroGymRoutinesPage> {
  List<Map<String, dynamic>> _routines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🔍 Cargando rutinas para usuario: $userId');

      final response = await SupabaseConfig.client
          .from('routines')
          .select('id, title, description, created_at')
          .eq('owner_user_id', userId)
          .order('created_at', ascending: false);

      print('✅ Rutinas cargadas: ${response.length}');

      setState(() {
        _routines = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar rutinas: $e');
      setState(() {
        _errorMessage = 'Error al cargar rutinas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoutine(String routineId, String routineTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.orangeAccent.withOpacity(0.5),
            width: 1,
          ),
        ),
        title: Text(
          '¿Eliminar rutina?',
          style: GoogleFonts.montserrat(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "$routineTitle"?\n\n'
          'Esta acción eliminará:\n'
          '• Todos los días de la rutina\n'
          '• Todos los ejercicios\n'
          '• Historial de entrenamientos\n\n'
          'Esto NO se puede deshacer.',
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
              'ELIMINAR TODO',
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
      print('🗑️ Iniciando eliminación de rutina: $routineId');

      // PASO 1: Eliminar workout_logs (PRIMERO, porque referencia a routine_id)
      print('1️⃣ Eliminando workout_logs...');
      await SupabaseConfig.client
          .from('workout_logs')
          .delete()
          .eq('routine_id', routineId);
      print('✅ Workout logs eliminados');

      // PASO 2: Obtener todos los días de la rutina
      print('2️⃣ Obteniendo días de la rutina...');
      final days = await SupabaseConfig.client
          .from('routine_days')
          .select('id')
          .eq('routine_id', routineId);
      print('✅ Días encontrados: ${days.length}');

      // PASO 3: Para cada día, eliminar sus ejercicios
      print('3️⃣ Eliminando ejercicios de cada día...');
      for (var day in days) {
        final dayId = day['id'];

        await SupabaseConfig.client
            .from('routine_exercises')
            .delete()
            .eq('routine_day_id', dayId);

        print('   ✓ Ejercicios del día $dayId eliminados');
      }

      // PASO 4: Eliminar todos los días
      print('4️⃣ Eliminando días de la rutina...');
      await SupabaseConfig.client
          .from('routine_days')
          .delete()
          .eq('routine_id', routineId);
      print('✅ Días eliminados');

      // PASO 5: Finalmente, eliminar la rutina
      print('5️⃣ Eliminando rutina de la tabla routines...');
      final deleteResult = await SupabaseConfig.client
          .from('routines')
          .delete()
          .eq('id', routineId)
          .select(); // Añadir .select() para obtener confirmación

      print('✅ Rutina eliminada. Resultado: $deleteResult');

      // VERIFICACIÓN: Comprobar que ya no existe
      final verification = await SupabaseConfig.client
          .from('routines')
          .select('id, title')
          .eq('id', routineId)
          .maybeSingle(); // Usar maybeSingle() para evitar error si no existe

      if (verification != null) {
        print('⚠️ ADVERTENCIA: La rutina todavía existe: $verification');
        throw Exception('La rutina no se pudo eliminar completamente');
      } else {
        print('✅ VERIFICADO: La rutina ha sido eliminada correctamente');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rutina "$routineTitle" eliminada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Recargar la lista
        await _loadRoutines();
      }
    } catch (e) {
      print('❌ Error al eliminar rutina: $e');
      print('❌ Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );

        // Recargar la lista de todos modos para ver el estado actual
        await _loadRoutines();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header con avatar
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Ir a perfil o cerrar sesión
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.orangeAccent,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Cargando rutinas...",
                            style: GoogleFonts.montserrat(
                              color: Colors.orangeAccent.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 60,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _errorMessage!,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadRoutines,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    side: const BorderSide(
                                      color: Colors.orangeAccent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    "Reintentar",
                                    style: GoogleFonts.montserrat(
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRoutines,
                          color: Colors.orangeAccent,
                          backgroundColor: Colors.black,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título Rutinas
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "RUTINAS",
                                      style: GoogleFonts.bebasNeue(
                                        color: Colors.orangeAccent,
                                        fontSize: 38,
                                        shadows: [
                                          Shadow(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.6),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CreateRoutinePage(),
                                          ),
                                        );
                                        // Si se creó una rutina, recargar la lista
                                        if (result == true) {
                                          _loadRoutines();
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.orangeAccent,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Lista de rutinas
                                if (_routines.isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          color: Colors.orangeAccent
                                              .withOpacity(0.3),
                                          size: 80,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          "No tienes rutinas aún",
                                          style: GoogleFonts.montserrat(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.6),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Crea tu primera rutina",
                                          style: GoogleFonts.montserrat(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.4),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._routines.map((routine) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 15),
                                      child: _buildRoutineCard(
                                        routine['title'] ?? 'Sin título',
                                        routine['description'] ?? '',
                                        routine['id'],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
            ),

            // Bottom Navigation Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.black,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.orangeAccent,
                unselectedItemColor: Colors.orangeAccent.withOpacity(0.5),
                currentIndex: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: (index) async {
                  if (index == 1) {
                    // Stats
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StatsPage()));
                  }
                  if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserSearchPage(),
                      ),
                    );
                    return;
                  }

                  if (index == 3) {
                    // Botón de la pesa - Crear rutina
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateRoutinePage(),
                      ),
                    );
                    if (result == true) {
                      _loadRoutines();
                    }
                  }

                  if (index == 3) {
                    // Botón de la pesa - Crear rutina
                    final result = await Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateRoutinePage(),
                      ),
                    );
                    if (result == true) {
                      _loadRoutines();
                    }
                  }
                  // Aquí puedes agregar navegación para los otros botones
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home, size: 30),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.show_chart, size: 30),
                    label: 'Stats',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view, size: 30),
                    label: 'Grid',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center, size: 30),
                    label: 'Fitness',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings, size: 30),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard(String title, String description, String routineId) {
    return GestureDetector(
      onTap: () {
        print('📋 Rutina seleccionada: $routineId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineDetailPage(
              routineId: routineId,
              routineTitle: title,
            ),
          ),
        );
      },
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
              color: Colors.orangeAccent.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent.withOpacity(0.6),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // 🗑️ NUEVO: Botón de eliminar
            IconButton(
              onPressed: () => _deleteRoutine(routineId, title),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
              tooltip: 'Eliminar rutina',
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

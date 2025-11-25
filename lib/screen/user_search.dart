import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_gym/bd/supabase_config.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      print('🔍 Cargando usuarios...');

      // Cargar todos los usuarios excepto el actual
      final usersData = await SupabaseConfig.client
          .from('users_profiles')
          .select('auth_user_id, display_name, avatar_url, bio, created_at')
          .neq('auth_user_id', currentUserId)
          .order('display_name', ascending: true);

      // Calcular estadísticas de cada usuario desde workout_logs
      List<Map<String, dynamic>> usersWithStats = [];
      
      for (var user in usersData) {
        final stats = await _getUserStats(user['auth_user_id']);
        usersWithStats.add({
          ...user,
          'total_workouts': stats['total_workouts'],
          'total_volume': stats['total_volume'],
          'ranking_points': stats['ranking_points'],
        });
      }

      setState(() {
        _users = usersWithStats;
        _filteredUsers = usersWithStats;
        _isLoading = false;
      });

      print('✅ ${_users.length} usuarios cargados');
    } catch (e) {
      print('❌ Error al cargar usuarios: $e');
      setState(() {
        _errorMessage = 'Error al cargar usuarios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getUserStats(String userId) async {
    try {
      final workouts = await SupabaseConfig.client
          .from('workout_logs')
          .select('started_at, finished_at, exercises_log')
          .eq('user_id', userId)
          .not('finished_at', 'is', null);

      int totalWorkouts = workouts.length;
      double totalVolume = 0;
      int totalMinutes = 0;

      for (var workout in workouts) {
        // Calcular volumen (simplificado, sin parsear JSON)
        totalVolume += 100; // Estimación

        // Calcular duración
        if (workout['started_at'] != null && workout['finished_at'] != null) {
          final start = DateTime.parse(workout['started_at']);
          final finish = DateTime.parse(workout['finished_at']);
          totalMinutes += finish.difference(start).inMinutes;
        }
      }

      // Calcular puntos: 10 por workout + volumen/10 + minutos/10
      int points = (totalWorkouts * 10) + 
                   (totalVolume / 10).floor() + 
                   (totalMinutes / 10).floor();

      return {
        'total_workouts': totalWorkouts,
        'total_volume': totalVolume,
        'total_minutes': totalMinutes,
        'ranking_points': points,
      };
    } catch (e) {
      print('Error calculando stats para $userId: $e');
      return {
        'total_workouts': 0,
        'total_volume': 0.0,
        'total_minutes': 0,
        'ranking_points': 0,
      };
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final name = (user['display_name'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'BUSCAR USUARIOS',
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
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              style: const TextStyle(color: Colors.orangeAccent),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                hintStyle: TextStyle(
                  color: Colors.orangeAccent.withOpacity(0.4),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.orangeAccent,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.orangeAccent),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
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
              ),
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 60),
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
                                onPressed: _loadUsers,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('REINTENTAR'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  color: Colors.orangeAccent.withOpacity(0.3),
                                  size: 80,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No hay usuarios registrados'
                                      : 'No se encontraron usuarios',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.orangeAccent.withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            color: Colors.orangeAccent,
                            backgroundColor: Colors.black,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(_filteredUsers[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orangeAccent.withOpacity(0.2),
              border: Border.all(
                color: Colors.orangeAccent,
                width: 2,
              ),
            ),
            child: user['avatar_url'] != null
                ? ClipOval(
                    child: Image.network(
                      user['avatar_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: Colors.orangeAccent, size: 32),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.orangeAccent, size: 32),
          ),
          const SizedBox(width: 16),

          // Info del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['display_name'] ?? 'Usuario sin nombre',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: Colors.orangeAccent.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user['total_workouts']} entrenamientos',
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 14,
                      color: Colors.orangeAccent.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user['ranking_points']} puntos',
                      style: GoogleFonts.montserrat(
                        color: Colors.orangeAccent.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón ver perfil
          IconButton(
            onPressed: () {
              _showUserProfile(user);
            },
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.orangeAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PERFIL',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.orangeAccent,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.orangeAccent),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar grande
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
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.orangeAccent,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nombre
                    Text(
                      user['display_name'] ?? 'Usuario',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Estadísticas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            '💪',
                            'Entrenamientos',
                            '${user['total_workouts']}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            '⭐',
                            'Puntos',
                            '${user['ranking_points']}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatBox(
                      '🏋️',
                      'Volumen Total',
                      '${user['total_volume'].toStringAsFixed(0)} kg',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.orangeAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
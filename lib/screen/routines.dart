import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeuroGymRoutinesPage extends StatelessWidget {
  const NeuroGymRoutinesPage({super.key});

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
                  Container(
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
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título Rutinas
                    Text(
                      "RUTINAS",
                      style: GoogleFonts.bebasNeue(
                        color: Colors.orangeAccent,
                        fontSize: 38,
                        shadows: [
                          Shadow(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Lista de entrenamientos
                    _buildTrainingCard("Entrenamiento", "Piernas"),
                    const SizedBox(height: 15),
                    _buildTrainingCard("Entrenamiento", "Pecho y Tríceps"),
                    const SizedBox(height: 15),
                    _buildTrainingCard("Entrenamiento", "Espalda y Bíceps"),
                  ],
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

  Widget _buildTrainingCard(String title, String subtitle) {
    return Container(
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
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
    );
  }
}
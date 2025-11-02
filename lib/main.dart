import 'package:flutter/material.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'screen/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  // Prueba de conexión
  try {
    final users =
        await SupabaseConfig.client.from('usuarios').select().limit(1);
    print('✅ Conexión OK: $users');
  } catch (e) {
    print('❌ Error de conexión: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NeuroGymLoginPage(),
    );
  }
}

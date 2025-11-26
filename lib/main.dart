import 'package:flutter/material.dart';
import 'package:neuro_gym/bd/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screen/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init(); // 🔗 conexión Supabase
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

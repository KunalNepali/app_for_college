import 'package:flutter/material.dart';
import 'package:quiz_app_supabase/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yhwwxjlayuckweydroju.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlod3d4amxheXVja3dleWRyb2p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNzUwNTEsImV4cCI6MjA5Mjk1MTA1MX0.wJkXVXRb7QbJLSyOnITZp0bl_D6zsWIuBp-C4XQlNTs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarThemeData(centerTitle: true, elevation: 0),
      ),
      home: SplashScreen(),
    );
  }
}

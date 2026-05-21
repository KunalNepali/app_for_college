import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app_supabase/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dpmizbywepdkpmscgtat.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwbWl6Ynl3ZXBka3Btc2NndGF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzODA2NDAsImV4cCI6MjA5Mzk1NjY0MH0.XU2LzFXsksHOf9PDFPPkIBnolSy9Q1sIJaD2Sw53hDQ',
  );

  runApp(const ProviderScope(child: MyApp()));
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
        appBarTheme: const AppBarThemeData(centerTitle: true, elevation: 0),
      ),
      home: const SplashScreen(),
    );
  }
}

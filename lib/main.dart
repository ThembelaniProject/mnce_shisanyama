import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MnceShisanyamaApp());
}

class MnceShisanyamaApp extends StatelessWidget {
  const MnceShisanyamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mnce Shisanyama',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
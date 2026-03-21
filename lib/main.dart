import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/auth/login_screen.dart';
import 'package:pawnder_app/screens/auth/onboarding_screen.dart';
import 'package:pawnder_app/screens/auth/register_screen.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';

void main() {
  runApp(const PawnderApp());
}

class PawnderApp extends StatelessWidget {
  const PawnderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawnder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: OnboardingScreen.routeName,
      routes: {
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
      },
    );
  }
}



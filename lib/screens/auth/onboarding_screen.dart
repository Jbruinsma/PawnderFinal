import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawnder_app/screens/auth/login_screen.dart';
import 'package:pawnder_app/screens/auth/register_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/auth_scaffold.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class OnboardingScreen extends StatelessWidget {
  static const String routeName = '/';

  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.seaBlue,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 42, 30, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME TO\nPAWNDER',
                        style: GoogleFonts.lilitaOne(
                          fontSize: 54,
                          height: 0.98,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/images/animals.jpg',
                          width: double.infinity,
                          height: 226,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ImageFallback();
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Create new connections with the\nperfect pet, and find the furry\nsoulmate you've been missing!",
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.35,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RegisterScreen.routeName,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.seaBlue,
                            shape: const StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LETS GET STARTED!',
                                style: GoogleFonts.lilitaOne(
                                  color: AppColors.seaBlue,
                                  fontSize: 38,
                                  height: 0.95,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.pets,
                                size: 28,
                                color: AppColors.ink,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            LoginScreen.routeName,
                          ),
                          child: const Text(
                            'Already have an account? Click here!',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

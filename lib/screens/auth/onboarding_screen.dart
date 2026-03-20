import 'package:flutter/material.dart';
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
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME TO\nPAWNDER',
                        style: AppTextStyles.heroTitle,
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/images/animals.jpg',
                          width: double.infinity,
                          height: 216,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ImageFallback();
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Create new connections with the\nperfect pet, and find the furry\nsoulmate you've been missing!",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: FilledButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RegisterScreen.routeName,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDCE5ED),
                            foregroundColor: AppColors.seaBlue,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'LETS GET STARTED!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            LoginScreen.routeName,
                          ),
                          child: const Text(
                            'Already have an account? Click here!',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
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

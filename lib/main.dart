import 'package:flutter/material.dart';

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
      },
    );
  }
}

class AppColors {
  static const Color blush = Color(0xFFE7C6CB);
  static const Color seaBlue = Color(0xFF0E889C);
  static const Color powderBlue = Color(0xFFDCE2E9);
  static const Color lineGray = Color(0xFFB0B8C1);
  static const Color bodyText = Color(0xFF7E8792);
  static const Color inputSurface = Color(0xFFF1F5F8);
  static const Color inputBorder = Color(0xFFCCD5DE);
  static const Color iconSurface = Color(0xFFE5EEF4);

  const AppColors._();
}

class AppTextStyles {
  static const TextStyle heroTitle = TextStyle(
    fontSize: 48,
    height: 1.05,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.2,
    color: Colors.white,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    color: AppColors.seaBlue,
  );

  static const TextStyle helper = TextStyle(
    fontSize: 12,
    color: AppColors.bodyText,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static const TextStyle field = TextStyle(
    fontSize: 17,
    color: AppColors.bodyText,
    fontWeight: FontWeight.w600,
  );

  const AppTextStyles._();
}

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
                            return const _ImageFallback();
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 216,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB4D8DE), Color(0xFFF2CCA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.pets,
          size: 88,
          color: AppColors.seaBlue,
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AuthCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('GET STARTED', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 42),
                    const AuthInput(
                      hintText: 'Full Name',
                      icon: Icons.person_2_outlined,
                    ),
                    const SizedBox(height: 16),
                    const AuthInput(
                      hintText: 'Email',
                      icon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 16),
                    const AuthInput(
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    const AuthInput(
                      hintText: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 38),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.seaBlue,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'CREATE ACCOUNT',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          LoginScreen.routeName,
                        ),
                        child: const Text(
                          'Already have an account? Click here!',
                          style: AppTextStyles.helper,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AuthCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('WELCOME BACK!', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 58),
                    const AuthInput(
                      hintText: 'Email',
                      icon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 22),
                    const AuthInput(
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (_) {},
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: AppColors.lineGray),
                        ),
                        const Text('Remember me', style: AppTextStyles.helper),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.seaBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.seaBlue,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('LOG IN', style: AppTextStyles.button),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          RegisterScreen.routeName,
                        ),
                        child: const Text(
                          "Don't have an account? Create one",
                          style: AppTextStyles.helper,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(child: child),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.powderBlue,
      ),
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 26),
      child: child,
    );
  }
}

class AuthInput extends StatelessWidget {
  final String hintText;
  final IconData? icon;
  final bool obscureText;

  const AuthInput({
    super.key,
    required this.hintText,
    this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder, width: 1.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.iconSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 17,
                color: AppColors.seaBlue,
              ),
            ),
          if (icon != null) const SizedBox(width: 10),
          Expanded(
            child: TextField(
              obscureText: obscureText,
              style: AppTextStyles.field,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: AppTextStyles.field.copyWith(
                  color: const Color(0xFF8A95A1),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

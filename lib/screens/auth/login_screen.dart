import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/auth/forgot_password_screen.dart';
import 'package:pawnder_app/screens/auth/register_screen.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/auth_card.dart';
import 'package:pawnder_app/widgets/auth_input.dart';
import 'package:pawnder_app/widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;

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
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: AppColors.lineGray),
                        ),
                        const Text('Remember me', style: AppTextStyles.helper),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
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
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          HomeScreen.routeName,
                        ),
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



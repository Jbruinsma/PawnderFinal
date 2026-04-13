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
                    Center(
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'WELCOME BACK!',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 43,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                            color: AppColors.seaBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          side: const BorderSide(color: AppColors.lineGray),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.lineGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                              fontSize: 11,
                              color: AppColors.seaBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              HomeScreen.routeName,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.seaBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'LOG IN',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          RegisterScreen.routeName,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Don't have an account? Create one",
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

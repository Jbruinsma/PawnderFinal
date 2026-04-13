import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/auth/login_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/auth_card.dart';
import 'package:pawnder_app/widgets/auth_input.dart';
import 'package:pawnder_app/widgets/auth_scaffold.dart';

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
                    Center(
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'GET STARTED',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                            color: AppColors.seaBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const AuthInput(
                      hintText: 'Full Name',
                    ),
                    const SizedBox(height: 14),
                    const AuthInput(
                      hintText: 'Email',
                      icon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 14),
                    const AuthInput(
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    const AuthInput(
                      hintText: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.seaBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'CREATE ACCOUNT',
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
                          LoginScreen.routeName,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Already have an account? Click here!',
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

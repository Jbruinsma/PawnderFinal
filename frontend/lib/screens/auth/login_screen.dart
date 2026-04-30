import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/auth/onboarding_screen.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
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
  final _authService = AuthService();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('Email/Username and password are required.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authService.login(identifier: identifier, password: password);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_authService.messageForError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      child: AuthCard(
        showHeaderImage: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 600;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Row(
                  children: [
                    if (isWide)
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: const AuthBrandHeader(
                            title: 'Welcome back',
                            subtitle: 'Join your neighborhood pet network and start posting alerts.',
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 40 : 20,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isWide) ...[
                              const AuthBrandHeader(
                                title: 'Welcome back',
                                subtitle: 'Log back in below',
                              ),
                              const SizedBox(height: 24),
                            ],
                            _buildLabel(theme, 'Email or Username'),
                            const SizedBox(height: 8),
                            AuthInput(
                              controller: _identifierController,
                              hintText: '',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _buildLabel(theme, 'Password'),
                            const SizedBox(height: 8),
                            AuthInput(
                              controller: _passwordController,
                              hintText: '',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: _isSubmitting ? null : _submitLogin,
                                child: _isSubmitting
                                    ? _buildLoadingIndicator(theme)
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Continue'),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 18),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                OnboardingScreen.routeName,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurfaceVariant,
                              ),
                              child: const Text(
                                "Don't have an account? Create one",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }
}
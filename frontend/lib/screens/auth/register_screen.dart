import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/auth/login_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/widgets/auth_card.dart';
import 'package:pawnder_app/widgets/auth_input.dart';
import 'package:pawnder_app/widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Full name, email, and password are required.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authService.register(fullName: fullName, email: email, password: password);
      if (!mounted) return;
      _showMessage('Account created successfully!');
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_authService.messageForError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

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
                    const AuthBrandHeader(
                      title: 'Create your Pawnder account',
                      subtitle: 'Join your neighborhood pet network and start posting alerts.',
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Full Name'),
                    const SizedBox(height: 8),
                    AuthInput(
                      controller: _fullNameController,
                      hintText: '',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    AuthInput(
                      controller: _emailController,
                      hintText: '',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    AuthInput(
                      controller: _passwordController,
                      hintText: '',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    AuthInput(
                      controller: _confirmPasswordController,
                      hintText: '',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF50C878),
                          foregroundColor: const Color(0xFF121212),
                        ),
                        onPressed: _isSubmitting ? null : _submitRegister,
                        child: _isSubmitting
                            ? _buildLoadingIndicator()
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, LoginScreen.routeName),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5E4E2)),
                      child: const Text(
                        'Already have an account? Log in',
                        maxLines: 1,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Color(0xFFE5E4E2), fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF121212)),
    );
  }
}
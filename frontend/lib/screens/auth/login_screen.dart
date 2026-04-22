import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/auth/forgot_password_screen.dart';
import 'package:pawnder_app/screens/auth/register_screen.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';
import 'package:pawnder_app/services/api_service.dart';
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
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.postPublic('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      final token = response.data['access_token'];
      if (token != null) {
        await ApiService.saveToken(token);
        if (mounted) {
          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        }
      }
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const Center(
                      child: FittedBox(
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
                    AuthInput(
                      hintText: 'Email',
                      icon: Icons.mail_outline,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    AuthInput(
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value ?? false),
                          visualDensity: const VisualDensity(
                              horizontal: -4, vertical: -4),
                          side: const BorderSide(color: AppColors.lineGray),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text('Remember me',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.lineGray,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ForgotPasswordScreen()),
                          ),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.seaBlue,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 52),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.seaBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('LOG IN',
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            height: 1,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5)),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, RegisterScreen.routeName),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("Don't have an account? Create one",
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600)),
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
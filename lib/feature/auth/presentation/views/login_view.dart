import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/feature/auth/domain/entities/login_credential_entity.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_event.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _manualLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final credential = LoginCredentialEntity(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    context.read<AuthBloc>().add(
          LoginWithEmailPasswordEvent(credential: credential),
        );
  }

  Future<void> _googleLogin() async {
    context.read<AuthBloc>().add(LoginWithGoogleEvent());
  }

  Future<void> _anonymousLogin() async {
    context.read<AuthBloc>().add(LoginAsGuestEvent());
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      labelStyle: theme.inputDecorationTheme.labelStyle,
      hintStyle: theme.inputDecorationTheme.hintStyle,
      prefixIconColor: theme.inputDecorationTheme.prefixIconColor,
      suffixIconColor: theme.inputDecorationTheme.suffixIconColor,
      enabledBorder: theme.inputDecorationTheme.enabledBorder,
      focusedBorder: theme.inputDecorationTheme.focusedBorder,
      errorBorder: theme.inputDecorationTheme.errorBorder,
      focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
      contentPadding: theme.inputDecorationTheme.contentPadding,
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.home,
            (route) => false,
          );
        }

        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final bool isLoading = state is AuthLoading;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final isDark = theme.brightness == Brightness.dark;

        final mutedTextColor = isDark
            ? colorScheme.onSurface.withOpacity(0.70)
            : colorScheme.onSurface.withOpacity(0.60);

        final dividerColor = isDark
            ? colorScheme.onSurface.withOpacity(0.16)
            : colorScheme.onSurface.withOpacity(0.14);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.onSurface.withOpacity(0.10)
                          : colorScheme.onSurface.withOpacity(0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 62,
                          color: colorScheme.primary,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Welcome Back',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Login to continue managing your money',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: mutedTextColor,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 30),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading,
                          style: TextStyle(color: colorScheme.onSurface),
                          cursorColor: colorScheme.primary,
                          decoration: _inputDecoration(
                            context: context,
                            label: 'Email Address',
                            prefixIcon: Icons.email_outlined,
                          ),
                          textInputAction: .next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }

                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          enabled: !isLoading,
                          style: TextStyle(color: colorScheme.onSurface),
                          cursorColor: colorScheme.primary,
                          decoration: _inputDecoration(
                            context: context,
                            label: 'Password',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                          onEditingComplete: isLoading ? null : _manualLogin,
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _manualLogin,
                            child: isLoading
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          children: [
                            Expanded(child: Divider(color: dividerColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'OR',
                                style: textTheme.bodySmall?.copyWith(
                                  color: mutedTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: dividerColor)),
                          ],
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : _googleLogin,
                            icon: const Icon(Icons.g_mobiledata, size: 32),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : _anonymousLogin,
                            icon: const Icon(Icons.person_outline),
                            label: const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don’t have an account?",
                              style: textTheme.bodyMedium?.copyWith(
                                color: mutedTextColor,
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        Routes.register,
                                      );
                                    },
                              child: const Text(
                                'Register',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
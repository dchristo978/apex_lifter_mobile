import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    try {
      await context.read<AuthProvider>().login(
            email: _email.text.trim(),
            password: _password.text,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).cannotConnect);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Soft maroon glow behind the frosted glass so the blur has something
          // to catch, matching the glassmorphism used inside the app.
          const _AuroraBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Logo(),
                      const SizedBox(height: 16),
                      Text(
                        'APEX LIFTER',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.login,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                      ),
                      const SizedBox(height: 36),
                      _GlassField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        label: l10n.email,
                        icon: Icons.alternate_email,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? l10n.invalidEmail
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _GlassField(
                        controller: _password,
                        obscureText: _obscure,
                        label: l10n.password,
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.passwordRequired
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 18, color: scheme.error),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_error!,
                                  style: TextStyle(color: scheme.error)),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(
                                  l10n.login,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(l10n.noAccountRegister),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rounded app icon with a soft maroon halo.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB03A48).withValues(alpha: 0.45),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 104,
            height: 104,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// A frosted-glass text field matching the app's glassmorphism panels.
class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
              floatingLabelStyle: TextStyle(color: scheme.primary),
              prefixIcon: Icon(icon, color: scheme.onSurfaceVariant),
              suffixIcon: suffix,
              filled: false,
              // The glass container draws the border; keep the field borderless
              // except for a subtle focus/error highlight.
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.error, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}

/// Two soft radial maroon glows on the black background — gives the frosted
/// fields something to refract.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.1,
            colors: [Color(0xFF3A1015), Color(0xFF000000)],
            stops: [0.0, 0.7],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.9, 0.9),
              radius: 0.9,
              colors: [Color(0x33800000), Color(0x00000000)],
              stops: [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

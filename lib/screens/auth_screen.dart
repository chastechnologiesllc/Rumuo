import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Front-end-only authentication surface. Wire the buttons to the auth service
/// when the backend is ready; the navigation entry remains intentionally scoped
/// to Profile.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSignUp
            ? 'Account creation will be available soon.'
            : 'Login will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProviderMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign in will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppTheme.textColor(context);
    final muted = AppTheme.textMuted(context);
    final surface = AppTheme.surfaceColor(context);
    final divider = AppTheme.dividerColor(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back to Profile',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RumuoSplashMark(),
                const SizedBox(height: 24),
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Save your progress and make Rumuo yours.'
                      : 'Sign in to continue your Rumuo journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 30),
                _FieldLabel(label: 'Email address', color: text),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(context, 'you@example.com', Icons.mail_outline_rounded),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your email address';
                    if (!value.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Password', color: text),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitEmail(),
                  decoration: _inputDecoration(context, 'At least 8 characters', Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                      // The closed eye is the affordance while the password is
                      // hidden. Pressing it reveals the value and switches to
                      // the open eye, matching common password-field behavior.
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your password';
                    if (_isSignUp && value.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                if (!_isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showProviderMessage('Password reset'),
                      child: Text('Forgot password?', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _submitEmail,
                    child: Text(_isSignUp ? 'Create account' : 'Log in', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(child: Divider(color: divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('OR', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ),
                    Expanded(child: Divider(color: divider)),
                  ],
                ),
                const SizedBox(height: 24),
                _ProviderButton(
                  backgroundColor: surface,
                  borderColor: divider,
                  leading: const _GoogleMark(),
                  label: 'Continue with Google',
                  onPressed: () => _showProviderMessage('Google'),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  backgroundColor: surface,
                  borderColor: divider,
                  leading: _AppleMark(color: text),
                  label: 'Continue with Apple',
                  labelColor: text,
                  onPressed: () => _showProviderMessage('Apple'),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSignUp ? 'Already have an account?' : 'New to Rumuo?', style: TextStyle(color: muted)),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(_isSignUp ? 'Log in' : 'Sign up', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'By continuing, you agree to Rumuo’s Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 11, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppTheme.surfaceColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.dividerColor(context))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.dividerColor(context))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.gold, width: 1.5)),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Widget leading;
  final String label;
  final Color? labelColor;
  final VoidCallback onPressed;

  const _ProviderButton({required this.backgroundColor, required this.borderColor, required this.leading, required this.label, this.labelColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: SizedBox(width: 28, height: 28, child: Center(child: leading)),
        label: Text(label, style: TextStyle(color: labelColor ?? AppTheme.textColor(context), fontSize: 15, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _FieldLabel({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700));
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icons/google_g_mark.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Google',
      );
}

class _AppleMark extends StatelessWidget {
  final Color color;

  const _AppleMark({required this.color});

  @override
  Widget build(BuildContext context) => Icon(
        Icons.apple,
        color: color,
        size: 28,
        semanticLabel: 'Apple',
      );
}

class _RumuoSplashMark extends StatelessWidget {
  const _RumuoSplashMark();

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/icons/rumuo_native_launch.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          semanticLabel: 'Rumuo',
        ),
      );
}

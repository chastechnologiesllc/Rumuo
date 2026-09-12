import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/rumuo_mark.dart';

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
                const RumuoMark(size: 56, borderRadius: 18),
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
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                  leading: Icon(Icons.apple, color: text, size: 22),
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
        icon: leading,
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

/// The four-colour Google G mark, drawn locally so the auth screen does not
/// depend on a remote image or an additional icon package.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(22, 22), painter: _GoogleMarkPainter());
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * .36;
    final stroke = size.width * .18;
    final segments = <(Color, double, double)>[
      (const Color(0xFF4285F4), -0.42, 1.42),
      (const Color(0xFF34A853), 1.00, 0.62),
      (const Color(0xFFFBBC05), 1.62, 0.80),
      (const Color(0xFFEA4335), 2.42, 1.31),
    ];
    for (final segment in segments) {
      final paint = Paint();
      paint.color = segment.$1;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = stroke;
      paint.strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), segment.$2, segment.$3, false, paint);
    }
    final blue = Paint();
    blue.color = const Color(0xFF4285F4);
    blue.style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * .5, size.height * .42, size.width * .42, stroke), blue);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

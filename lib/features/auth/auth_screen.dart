import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = false;

  // Sign In fields
  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();
  bool _signInObscure = true;

  // Sign Up fields
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirm = TextEditingController();
  bool _signUpObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirm.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _signInEmail.text.trim();
    final password = _signInPassword.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields.');
      return;
    }
    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).signIn(
          email: email,
          password: password,
        );
    if (mounted) setState(() => _loading = false);
    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      _showSnack(error ?? 'Sign in failed.');
    }
  }

  Future<void> _handleSignUp() async {
    final name = _signUpName.text.trim();
    final email = _signUpEmail.text.trim();
    final password = _signUpPassword.text;
    final confirm = _signUpConfirm.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).signUp(
          email: email,
          password: password,
          displayName: name,
        );
    if (mounted) setState(() => _loading = false);
    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      _showSnack(error ?? 'Sign up failed.');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _signInEmail.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email above, then tap Forgot Password.');
      return;
    }
    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).resetPassword(email);
    if (mounted) setState(() => _loading = false);
    if (success && mounted) {
      _showSnack('Password reset email sent! Check your inbox.');
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      _showSnack(error ?? 'Failed to send reset email.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final cardWidth = screenW > 500 ? 420.0 : screenW * 0.9;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF6F0), Color(0xFFEDE0D0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo & Branding ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
                      ),
                      border: Border.all(color: BrandColors.gold, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.gold.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_stories, color: BrandColors.goldLight, size: 28),
                        Text('R',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: BrandColors.gold,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rhema Study Bible',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: BrandColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your personal Bible companion',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: BrandColors.brownMid,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Auth Card ──
                  SizedBox(
                    width: cardWidth,
                    child: Card(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tab selector
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: BrandColors.gold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: const Color(0xFF3E2723),
                                unselectedLabelColor: BrandColors.brownMid,
                                labelStyle: GoogleFonts.lora(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                                unselectedLabelStyle:
                                    GoogleFonts.lora(fontSize: 15),
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tab content
                            SizedBox(
                              height: _tabController.index == 1 ? 340 : 260,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildSignIn(theme),
                                  _buildSignUp(theme),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Skip option
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Continue without account',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: BrandColors.brownMid,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(
          controller: _signInEmail,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _inputField(
          controller: _signInPassword,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: _signInObscure,
          toggleObscure: () => setState(() => _signInObscure = !_signInObscure),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading ? null : _handleForgotPassword,
            child: Text('Forgot Password?',
                style: GoogleFonts.lora(fontSize: 12, color: BrandColors.gold)),
          ),
        ),
        const SizedBox(height: 8),
        _primaryButton('Sign In', _handleSignIn),
      ],
    );
  }

  Widget _buildSignUp(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(
          controller: _signUpName,
          label: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _signUpEmail,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _signUpPassword,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: _signUpObscure,
          toggleObscure: () => setState(() => _signUpObscure = !_signUpObscure),
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _signUpConfirm,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscure: _signUpObscure,
        ),
        const SizedBox(height: 16),
        _primaryButton('Create Account', _handleSignUp),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.lora(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lora(fontSize: 14, color: BrandColors.brownMid),
        prefixIcon: Icon(icon, size: 20, color: BrandColors.brownMid),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: BrandColors.brownMid,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFAF6F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BrandColors.gold.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BrandColors.gold.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.gold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.gold,
          foregroundColor: const Color(0xFF3E2723),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text,
                style: GoogleFonts.lora(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

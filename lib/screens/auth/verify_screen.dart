import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class VerifyScreen extends StatefulWidget {
  final String emailLink;

  const VerifyScreen({super.key, required this.emailLink});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = true;
  bool _needsName = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyLink();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _verifyLink() async {
    try {
      final credential = await _authService.signInWithEmailLink(widget.emailLink);
      final user = credential.user!;

      // Check if this is a first-time user (no display name set).
      if (user.displayName == null || user.displayName!.isEmpty) {
        setState(() {
          _isVerifying = false;
          _needsName = true;
        });
      } else {
        // Returning user — go straight to home.
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _authService.updateUserName(_nameController.text.trim());
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isVerifying
                    ? _buildVerifying()
                    : _error != null
                        ? _buildError()
                        : _needsName
                            ? _buildNameForm()
                            : _buildVerifying(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifying() {
    return Column(
      key: const ValueKey('verifying'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏖️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 20),
        const Text(
          'Signing you in...',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      key: const ValueKey('error'),
      padding: const EdgeInsets.all(24),
      decoration: GlassDecoration(borderRadius: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.negative.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.negative,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign-in failed',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameForm() {
    return Container(
      key: const ValueKey('name_form'),
      padding: const EdgeInsets.all(24),
      decoration: GlassDecoration(borderRadius: 24, highlight: true),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: const Text('👋', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome aboard!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'What should your friends call you?',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Your name',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.textTertiary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitName,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Let\'s go! 🚀',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

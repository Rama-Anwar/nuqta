import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:invoice_ai/helper/get_current_user_profile.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nav.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login_at', DateTime.now().toIso8601String());
      final profile = await getCurrentUserProfile();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        profile?.isOwner == true ? AppRoutes.dash : AppRoutes.receipts,
      );
    } on FirebaseAuthException catch (e) {
      String message = l10n.loginFailed;

      if (e.code == 'user-not-found') {
        message = l10n.noUserFoundForEmail;
      } else if (e.code == 'wrong-password') {
        message = l10n.wrongPassword;
      } else if (e.code == 'invalid-email') {
        message = l10n.invalidEmail;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on InactiveOrganizationException {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_subscriptionExpiredMessage(context))),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWrong)));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _subscriptionExpiredMessage(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'اشتراكك منتهي، يرجى تجديد الاشتراك للاستمرار باستخدام Invoice AI.'
        : 'Your subscription has expired. Please renew your subscription to continue using Invoice AI.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppPalette.backgroundScaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BrandHeader(l10n: l10n),
                  const SizedBox(height: 24),
                  _LoginCard(
                    l10n: l10n,
                    formKey: _formKey,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    isLoading: _isLoading,
                    onSubmit: _handleLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final AppLocalizations l10n;

  const _BrandHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LogoMark(),
        const SizedBox(height: 20),
        Text(
          l10n.invoiceAppTitle,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        border: Border.all(color: AppPalette.borderLowContrast),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.document_scanner_rounded,
        size: 36,
        color: AppPalette.primaryContainer,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final Future<void> Function() onSubmit;

  const _LoginCard({
    required this.l10n,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppPalette.surfaceCard,
        border: Border.all(color: AppPalette.borderLowContrast),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                _FieldLabel(text: l10n.username),
                _LoginTextField(
                  controller: usernameController,
                  hintText: 'admin',
                  keyboardType: TextInputType.text,
                  obscureText: false,
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return l10n.usernameRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_FieldLabel(text: l10n.securePassword)],
                ),
                _LoginTextField(
                  controller: passwordController,
                  hintText: '............',
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  validator: (value) {
                    if ((value ?? '').isEmpty) return l10n.passwordRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primaryContainer,
                      foregroundColor: AppPalette.textPrimary,
                      disabledBackgroundColor: AppPalette.primaryContainer
                          .withValues(alpha: 0.7),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppPalette.textPrimary,
                            ),
                          )
                        : Text(
                            l10n.loginToConsole,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: AppPalette.borderLowContrast),
          const SizedBox(height: 18),
          Text(
            l10n.securedByInfrastructure,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppPalette.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppPalette.textMuted,
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?) validator;

  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.obscureText,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: AppPalette.textPrimary, fontSize: 16),
      decoration: const InputDecoration(hintText: '').copyWith(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppPalette.surfaceContainerHighest),
        filled: true,
        fillColor: AppPalette.backgroundScaffold,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppPalette.borderLowContrast, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppPalette.primaryContainer, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppPalette.errorMuted, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppPalette.errorMuted, width: 2),
        ),
      ),
    );
  }
}

class AppPalette {
  static const Color backgroundScaffold = Color(0xFF1A1D20);
  static const Color surfaceCard = Color(0xFF2B3035);
  static const Color borderLowContrast = Color(0xFF3E444A);
  static const Color textPrimary = Color(0xFFDEE2E6);
  static const Color textMuted = Color(0xFFBDC1C6);
  static const Color surfaceContainerHighest = Color(0xFF313539);
  static const Color primaryContainer = Color(0xFFEE671C);
  static const Color errorMuted = Color(0xFFE07A5F);
}

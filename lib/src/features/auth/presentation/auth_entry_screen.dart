import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen>
  with TickerProviderStateMixin {
  late final TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _isSubmitting = false;
  late final AnimationController _launchController;
  late final Animation<double> _launchAnimation;
  bool _showLaunchOverlay = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _showLaunchOverlay = false);
        }
      });
    _launchAnimation = CurvedAnimation(parent: _launchController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _launchController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
    await ref.read(authControllerProvider.notifier).login(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text,
          );
      // show launch overlay animation (fills bar then allows gate to navigate)
      if (mounted) {
        setState(() {
          _showLaunchOverlay = true;
        });
        _launchController.forward(from: 0);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
    await ref.read(authControllerProvider.notifier).register(
      name: _registerNameController.text.trim(),
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
          );
      if (mounted) {
        setState(() {
          _showLaunchOverlay = true;
        });
        _launchController.forward(from: 0);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          if (_showLaunchOverlay) _LaunchOverlay(animation: _launchAnimation),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Center(
                        child: SizedBox(
                          width: isWide ? 470 : double.infinity,
                          child: _AuthCard(
                            tabController: _tabController,
                            isSubmitting: _isSubmitting,
                            loginFormKey: _loginFormKey,
                            registerFormKey: _registerFormKey,
                            loginEmailController: _loginEmailController,
                            loginPasswordController: _loginPasswordController,
                            registerNameController: _registerNameController,
                            registerEmailController: _registerEmailController,
                            registerPasswordController: _registerPasswordController,
                            onLogin: _submitLogin,
                            onRegister: _submitRegister,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF000000),
            Color(0xFF0A0A0A),
            Color(0xFF141414),
            Color(0xFF222222),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(top: -80, left: -70, child: _GlowOrb(size: 220, color: Color(0x33FFFFFF))),
          Positioned(top: 90, right: -90, child: _GlowOrb(size: 280, color: Color(0x22FFFFFF))),
          Positioned(bottom: -120, left: 40, child: _GlowOrb(size: 340, color: Color(0x33FFFFFF))),
          Positioned(bottom: 110, right: 28, child: _GlowOrb(size: 180, color: Color(0x44FFFFFF))),
        ],
      ),
    );
  }
}



class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.tabController,
    required this.isSubmitting,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.registerNameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.onLogin,
    required this.onRegister,
  });

  final TabController tabController;
  final bool isSubmitting;
  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController registerNameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final Future<void> Function() onLogin;
  final Future<void> Function() onRegister;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 42,
                offset: const Offset(0, 26),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Sukran',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_outlined, color: Color(0xFFFAFAFA), size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rol seç, giriş yap veya yeni hesap oluştur. Ekran sade, ama hissi güçlü.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAFAFA), Color(0xFFBDBDBD)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelColor: const Color(0xFF111111),
                  unselectedLabelColor: Colors.white70,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Giriş Yap'),
                    Tab(text: 'Kayıt Ol'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 392,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _AuthForm(
                      formKey: loginFormKey,
                      emailController: loginEmailController,
                      passwordController: loginPasswordController,
                      nameController: null,
                      isSubmitting: isSubmitting,
                      submitLabel: 'Giriş Yap',
                      hintText: 'Mevcut hesabınla devam et.',
                      showNameField: false,
                      onSubmit: onLogin,
                    ),
                    _AuthForm(
                      formKey: registerFormKey,
                      emailController: registerEmailController,
                      passwordController: registerPasswordController,
                      nameController: registerNameController,
                      isSubmitting: isSubmitting,
                      submitLabel: 'Hesap Oluştur',
                      hintText: 'Yeni hesap oluştur.',
                      showNameField: true,
                      onSubmit: onRegister,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.isSubmitting,
    required this.submitLabel,
    required this.hintText,
    required this.showNameField,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? nameController;
  final bool isSubmitting;
  final String submitLabel;
  final String hintText;
  final bool showNameField;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HintPill(text: hintText),
          if (showNameField) ...[
            const SizedBox(height: 14),
            _AuthField(
              controller: nameController!,
              label: 'Ad Soyad',
              icon: Icons.badge_outlined,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Ad soyad gerekli' : null,
            ),
          ],
          const SizedBox(height: 14),
          _AuthField(
            controller: emailController,
            label: 'E-posta',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'E-posta gerekli' : null,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) =>
                value == null || value.length < 6 ? 'En az 6 karakter' : null,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    await onSubmit();
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFFFAFAFA),
              foregroundColor: const Color(0xFF111111),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
          const SizedBox(height: 12),
          Text(
            'Devam ederek uygulamaya giriş yaparsınız.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: Colors.white70,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFAFAFA), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF9A9A9A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF9A9A9A), width: 1.2),
        ),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFAFAFA).withValues(alpha: 0.22)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFEDEDED),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}




class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _LaunchOverlay extends StatelessWidget {
  const _LaunchOverlay({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          color: Colors.black.withValues(alpha: 0.60),
          child: Center(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          children: [
                            Text('Sukran', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: animation.value,
                              color: const Color(0xFFFAFAFA),
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: animation.value.clamp(0.0, 1.0),
                              child: Text(
                                animation.value < 0.98 ? 'Yükleniyor...' : 'Hazır!',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.70)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

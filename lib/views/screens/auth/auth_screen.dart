import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../viewmodels/session_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_backdrop.dart';
import '../../shared/widgets/snapback_logo.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (context) =>
          AuthViewModel(session: context.read<SessionViewModel>()),
      child: const _AuthBody(),
    );
  }
}

class _AuthBody extends StatefulWidget {
  const _AuthBody();

  @override
  State<_AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<_AuthBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final isLogin = vm.mode == AuthMode.login;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: NeonBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: context.rPad(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo + title
                    Column(
                      children: [
                        SnapbackLogo(size: context.rGap(72)),
                        SizedBox(height: context.rGap(14)),
                        Text(
                          'SNAPback',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.deepGreen,
                                letterSpacing: -1,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.rGap(6)),
                        Text(
                          'Earn healthy shopping rewards',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    SizedBox(height: context.rGap(36)),

                    // Auth card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.08),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  isLogin ? 'Welcome back' : 'Create account',
                                  key: ValueKey(isLogin),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              SizedBox(height: context.rGap(20)),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email address',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: cs.primary.withValues(alpha: 0.9),
                                  ),
                                  filled: true,
                                  fillColor: cs.surface.withValues(alpha: 0.7),
                                ),
                              ),
                              SizedBox(height: context.rGap(14)),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Enter your password';
                                  if (!isLogin && v.length < 6) {
                                    return 'Use at least 6 characters';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(vm),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: cs.primary.withValues(alpha: 0.9),
                                  ),
                                  filled: true,
                                  fillColor: cs.surface.withValues(alpha: 0.7),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),

                              if (vm.errorMessage != null) ...[
                                SizedBox(height: context.rGap(10)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lossRed.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppTheme.lossRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          vm.errorMessage!,
                                          style: const TextStyle(
                                            color: AppTheme.lossRed,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              SizedBox(height: context.rGap(20)),

                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [cs.primary, AppTheme.neonBlue],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.25),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: vm.isBusy
                                      ? null
                                      : () => _submit(vm),
                                  child: vm.isBusy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          isLogin
                                              ? 'Sign In'
                                              : 'Create Account',
                                        ),
                                ),
                              ),

                              SizedBox(height: context.rGap(10)),

                              Align(
                                child: TextButton(
                                  onPressed: vm.isBusy ? null : vm.toggleMode,
                                  child: Text(
                                    isLogin
                                        ? "Don't have an account? Sign up"
                                        : 'Already have an account? Sign in',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(AuthViewModel vm) {
    if (!_formKey.currentState!.validate()) return;
    vm.submit(email: _emailCtrl.text, password: _passCtrl.text);
  }
}

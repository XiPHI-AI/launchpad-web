import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;

import '../../core/auth/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _heroImageUrl =
      'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=2940&auto=format&fit=crop';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authNotifierProvider.notifier).clearError();

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    // GoRouter redirect handles navigation on success (auth state change → /)
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF081018),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _heroImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF081018)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xC90A1520),
                  Color(0xB81A3040),
                  Color(0xE60D1722),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isCompact ? Alignment.topCenter : Alignment.centerLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0E1824).withValues(alpha: isCompact ? 0.55 : 0.18),
                  const Color(0xFF0E1824).withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 20 : 40,
                  vertical: isCompact ? 24 : 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isCompact ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 40,
                          offset: Offset(0, 24),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: isCompact
                          ? _buildCompactLayout(context, authState, colorScheme, textTheme)
                          : _buildWideLayout(context, authState, colorScheme, textTheme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    AuthState authState,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 32, 48),
            child: _buildBrandPanel(textTheme),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: _buildFormCard(context, authState, colorScheme, textTheme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    AuthState authState,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildBrandPanel(textTheme, compact: true),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildFormCard(context, authState, colorScheme, textTheme),
        ),
      ],
    );
  }

  Widget _buildBrandPanel(TextTheme textTheme, {bool compact = false}) {
    final statTextStyle = textTheme.bodySmall?.copyWith(
      color: Colors.white70,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Prospectz.ai for the innovation economy',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 24 : 36),
            Text(
              'Private access to the J.P. Morgan startup banking experience.',
              style: textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontSize: compact ? 30 : 46,
                height: 1.05,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'Sign in to continue into the guided founder journey, relationship hub, and banker workspace. The visual language mirrors the main site so the handoff feels seamless.',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 24 : 48),
        if (compact)
          Column(
            children: [
              _buildStatChip('Founder journey', 'Voice-guided onboarding', statTextStyle, isFullWidth: true),
              const SizedBox(height: 12),
              _buildStatChip('Relationship hub', 'Context carried across sessions', statTextStyle, isFullWidth: true),
              const SizedBox(height: 12),
              _buildStatChip('Banker mode', 'Protected internal workspace', statTextStyle, isFullWidth: true),
            ],
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatChip('Founder journey', 'Voice-guided onboarding', statTextStyle),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatChip('Relationship hub', 'Context carried across sessions', statTextStyle),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatChip('Banker mode', 'Protected internal workspace', statTextStyle),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(String title, String body, TextStyle? bodyStyle, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: bodyStyle),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    AuthState authState,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final fieldTextStyle = textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
    final fieldHintStyle = textTheme.titleMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.38),
      fontWeight: FontWeight.w400,
    );
    final fieldLabelStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.68),
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppThemeTokens.buttonPrimary,
                    Color(0xFF0E5E76),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331A7B99),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome back',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to enter the protected Prospectz.ai workspace.',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.74),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              style: fieldTextStyle,
              cursorColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'admin@prospectz.ai',
                labelStyle: fieldLabelStyle,
                hintStyle: fieldHintStyle,
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppThemeTokens.buttonPrimary,
                    width: 1.6,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required.';
                }
                if (!v.contains('@')) return 'Enter a valid email.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: fieldTextStyle,
              cursorColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                labelStyle: fieldLabelStyle,
                hintStyle: fieldHintStyle,
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppThemeTokens.buttonPrimary,
                    width: 1.6,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required.';
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: authState.isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppThemeTokens.buttonPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Access is restricted to provisioned accounts. If you need credentials or a role update, contact '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  html.window.open('mailto:hello@intelligencelabz.ai', '_self');
                                },
                                child: const Text(
                                  'hello@intelligencelabz.ai',
                                  style: TextStyle(
                                    color: AppThemeTokens.buttonPrimary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

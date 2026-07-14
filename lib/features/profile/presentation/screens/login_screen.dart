import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/strings_es.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_router.dart';
import '../providers/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.privacy);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn.instance
          .authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null || !mounted) return;

      final repo = ref.read(profileRepositoryProvider);
      final result = await repo.isProfileComplete(user.uid);
      if (!mounted) return;

      final isComplete = result.fold(
        (_) => false,
        (v) => v,
      );
      if (isComplete) {
        context.go(AppRoutes.evaluate);
      }
      // If not complete, OnboardingScreen rebuilds via ref.watch and shows the form
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('ApiException: 16')) {
        // Usuario canceló — no es un error, no mostrar nada
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(e))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/icon/icon.png',
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'PostulaAI',
                style: tt.displayMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu asistente de búsqueda laboral con IA',
                style: tt.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              if (_loading)
                CircularProgressIndicator(color: cs.primary)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.surface,
                      foregroundColor: const Color(
                        0xFF1F2937,
                      ),
                      elevation: 1,
                      shadowColor: Colors.black26,
                      side: BorderSide(
                        color: cs.outlineVariant,
                      ),
                    ),
                    icon: Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: cs.onSurfaceVariant,
                    ),
                    label: Text(
                      StringsEs.loginGoogle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    onPressed: _signInWithGoogle,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Al continuar aceptás los ',
                    ),
                    TextSpan(
                      text: StringsEs.legalTerminosTitulo,
                      style: TextStyle(
                        color: cs.primary,
                        decoration:
                            TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                      recognizer: _termsRecognizer,
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: StringsEs.legalPrivacidadTitulo,
                      style: TextStyle(
                        color: cs.primary,
                        decoration:
                            TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                      recognizer: _privacyRecognizer,
                    ),
                    const TextSpan(text: '.'),
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

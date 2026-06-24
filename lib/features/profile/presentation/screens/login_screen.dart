import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser =
          await GoogleSignIn.instance.authenticate();
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

      final isComplete =
          result.fold((_) => false, (v) => v);
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
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.work_outline_rounded,
                  size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text('PostulaAI',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('Tu asistente de búsqueda laboral',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white
                          .withValues(alpha: 0.85))),
              const SizedBox(height: 64),
              if (_loading)
                const CircularProgressIndicator(
                    color: Colors.white)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          const Color(0xFF1F2937),
                    ),
                    icon: const Icon(Icons.g_mobiledata,
                        size: 24),
                    label: const Text(StringsEs.loginGoogle,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    onPressed: _signInWithGoogle,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Al continuar aceptás los términos de uso y la política de privacidad.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white
                        .withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:postula_ai/core/router/app_router.dart';
import 'package:postula_ai/main.dart';

void main() {
  testWidgets('PostulaAIApp builds without throwing', (tester) async {
    final fakeRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('smoke-test')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(fakeRouter)],
        child: const PostulaAIApp(),
      ),
    );

    // App shell (theme, MaterialApp.router) built successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

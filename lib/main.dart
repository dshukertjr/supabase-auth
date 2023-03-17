import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://nlbsnpoablmsxwkdbmer.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYyOTE5ODEwMiwiZXhwIjoxOTQ0Nzc0MTAyfQ.XZWLzz95pyU9msumQNsZKNBXfyss-g214iTVAwyQLPA',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const PasswordResetPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
    );
  }
}

/// Page that user lands when they don't remember their password.
///
/// They can enter their password and it will send an email containing a magic link
/// that will trigger a `passwordRecovery`.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            decoration: const InputDecoration(label: Text('Email')),
            controller: _emailController,
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text;
              await supabase.auth.resetPasswordForEmail(email,
                  redirectTo: 'io.supabase.newlink://callback/reset');
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check your inbox')));
            },
            child: const Text('Send password reset email'),
          ),
        ],
      ),
    );
  }
}

/// Page to
class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Password')),
      body: ListView(
        children: [
          TextFormField(
            decoration: const InputDecoration(label: Text('New Password')),
            controller: _newPasswordController,
          ),
          ElevatedButton(
            onPressed: () async {
              final password = _newPasswordController.text;
              await supabase.auth
                  .updateUser(UserAttributes(password: password));
              if (mounted) context.go('/');
            },
            child: const Text('Send password reset email'),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ElevatedButton(
            onPressed: () async {
              final googleUser = await GoogleSignIn().signIn();

              // Obtain the auth details from the request
              final googleAuth = await googleUser?.authentication;

              final idToken = googleAuth?.idToken;

              if (idToken == null) {
                return;
              }

              final payload = Jwt.parseJwt(idToken);

              final hashedNonce = payload['nonce'] as String;

              // final hashedNonce = sha256.convert(utf8.encode(nonce)).toString();

              final res = await supabase.auth.signInWithIdToken(
                provider: Provider.google,
                idToken: idToken,
                nonce: hashedNonce,
              );
            },
            child: const Text('Google login'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nonce = const Uuid().v4();
              final hashedNonce = sha256.convert(utf8.encode(nonce)).toString();

              const String clientId = 'com.app';

              final AuthorizationCredentialAppleID credential =
                  await SignInWithApple.getAppleIDCredential(
                scopes: [
                  AppleIDAuthorizationScopes.email,
                ],
                nonce: hashedNonce,
              );

              final idToken = credential.identityToken;
              if (idToken == null) {
                return;
              }

              await supabase.auth.signInWithIdToken(
                provider: Provider.apple,
                idToken: idToken,
                nonce: nonce,
              );
            },
            child: const Text('Apple login'),
          ),
          ElevatedButton(
            onPressed: () {
              context.go('/forgot-password');
            },
            child: const Text('Forgot password'),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as apple;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://mdembiczgqmbdobqwitc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kZW1iaWN6Z3FtYmRvYnF3aXRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzkxMDA0MDcsImV4cCI6MTk5NDY3NjQwN30.TWBOSGcW29IZNBjatdKTpT8qtC34smxefVXzM7aumCY',
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((event) {
      setState(() {
        _user = event.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          TextButton(
            style: const ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(Colors.white)),
            onPressed: () => supabase.auth.signOut(),
            child: const Text('sign out'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Current User: ${_user?.toJson()}'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              const rawNonce = 'nonce';
              final hashedNonce =
                  sha256.convert(utf8.encode(rawNonce)).toString();

              const appAuth = FlutterAppAuth();

              const clientId =
                  '428843675299-oo4u5ihk1g8n5ipb8ieis1mb66q3h64g.apps.googleusercontent.com';

              const bundleId = 'com.example.authflow';
              const redirectUrl = '$bundleId:/google_auth';

              const discoveryUrl =
                  'https://accounts.google.com/.well-known/openid-configuration';

              final result = await appAuth.authorize(
                AuthorizationRequest(
                  clientId,
                  redirectUrl,
                  discoveryUrl: discoveryUrl,
                  nonce: hashedNonce,
                  scopes: [
                    'openid',
                    'email',
                  ],
                ),
              );

              if (result == null) {
                return;
              }

              final tokenResult = await appAuth.token(
                TokenRequest(
                  clientId,
                  redirectUrl,
                  authorizationCode: result.authorizationCode,
                  discoveryUrl: discoveryUrl,
                  codeVerifier: result.codeVerifier,
                  nonce: rawNonce,
                  scopes: [
                    'openid',
                    'email',
                  ],
                ),
              );

              final idToken = tokenResult?.idToken;

              if (idToken == null) {
                return;
              }

              final payload = Jwt.parseJwt(idToken);

              print(payload);

              final res = await supabase.auth.signInWithIdToken(
                provider: Provider.google,
                idToken: idToken,
                nonce: rawNonce,
              );

              print(res.session.toString());
            },
            child: const Text('Google login'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rawNonce = const Uuid().v4();
              final hashedNonce =
                  sha256.convert(utf8.encode(rawNonce)).toString();

              final apple.AuthorizationCredentialAppleID credential =
                  await apple.SignInWithApple.getAppleIDCredential(
                scopes: [],
                nonce: hashedNonce,
              );

              final idToken = credential.identityToken;
              if (idToken == null) {
                return;
              }

              final payload = Jwt.parseJwt(idToken);

              print(payload);

              final res = await supabase.auth.signInWithIdToken(
                provider: Provider.apple,
                idToken: idToken,
                nonce: rawNonce,
              );
              print(res);
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

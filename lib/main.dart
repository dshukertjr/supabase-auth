import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'supabaseUrl',
    anonKey: 'supabaseKey',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
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
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/forgot-password');
          },
          child: const Text('Forgot password'),
        ),
      ),
    );
  }
}

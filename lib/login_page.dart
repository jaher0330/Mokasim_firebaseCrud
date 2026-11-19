import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'home_page.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;

  // FORGOT PASSWORD dialog (NEW)
  Future<void> _showForgotPasswordDialog() async {
    final resetCtrl = TextEditingController(text: emailCtrl.text.trim());
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: resetCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Enter your email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetCtrl.text.trim();
              if (email.isEmpty) return;
              final error = await auth.resetPassword(email);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    error ??
                        "Password reset email sent. Please check your inbox.",
                  ),
                ),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login - Mokasim")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Email Login ---
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              // FORGOT PASSWORD link (NEW)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text("Forgot your password?"),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login with Email"),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await auth.signInWithEmail(
                    emailCtrl.text.trim(),
                    passwordCtrl.text,
                  );
                  setState(() => loading = false);

                  if (!context.mounted) return;
                  if (user != null) {
                    if (!user.emailVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please verify your email before logging in.",
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => HomePage()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Invalid email or password"),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    final user = await auth.signInWithGoogle();
                    if (!context.mounted) return;
                    if (user != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => HomePage()),
                      );
                    }
                  } on Exception catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.toString().contains('sign_in_failed')
                              ? 'Google sign-in is not configured correctly. Add the app SHA-1/SHA-256 and download google-services.json again.'
                              : 'Google sign-in failed. Please try again.',
                        ),
                      ),
                    );
                  } finally {
                    if (context.mounted) {
                      setState(() => loading = false);
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                child: const Text("Don't have an account? Register"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

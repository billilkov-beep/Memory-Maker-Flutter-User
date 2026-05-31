import 'package:flutter/material.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'admin@memorymaker.com');
  final _password = TextEditingController(text: 'Test@123456');
  final _name = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  bool _signup = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_signup) {
        await RepositoryProvider.instance.signUp(email: _email.text, password: _password.text, name: _name.text.trim().isEmpty ? _email.text.split('@').first : _name.text.trim());
        showMmSnack(context, 'Account created. Please confirm your email if confirmation is enabled.');
      } else {
        await RepositoryProvider.instance.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      showMmSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty) return showMmSnack(context, 'Enter your email first.', error: true);
    try {
      await RepositoryProvider.instance.sendPasswordReset(_email.text);
      showMmSnack(context, 'Password reset email sent if this account exists.');
    } catch (e) {
      showMmSnack(context, 'Could not send reset email. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MmGradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 18),
              Center(child: Image.asset('assets/images/logo.png', height: 104)),
              const SizedBox(height: 24),
              MmCard(
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(_signup ? 'Create your MemoryMaker account' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: MmColors.ink)),
                  const SizedBox(height: 8),
                  const Text('Private event galleries, QR sharing, uploads, notifications and support in one clean app.', style: TextStyle(color: MmColors.muted)),
                  const SizedBox(height: 20),
                  if (_signup) ...[
                    TextField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _showPassword = !_showPassword)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _loading ? null : _submit, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_signup ? Icons.person_add_alt_1 : Icons.login), label: Text(_signup ? 'Create Account' : 'Log In')),
                  const SizedBox(height: 10),
                  TextButton(onPressed: _reset, child: const Text('Forgot password? Send reset email')),
                  TextButton(onPressed: () => setState(() => _signup = !_signup), child: Text(_signup ? 'Already have an account? Log in' : 'New user? Create account')),
                  const Divider(height: 28),
                  const Text('Demo login: admin@memorymaker.com / Test@123456', textAlign: TextAlign.center, style: TextStyle(color: MmColors.muted, fontSize: 12)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

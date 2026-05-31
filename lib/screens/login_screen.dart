import 'package:flutter/gestures.dart';
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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _showPassword = false;
  bool _loading = false;
  bool _signup = false;
  bool _acceptedLegal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 760));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    final lower = msg.toLowerCase();
    if (lower.contains('socket') || lower.contains('host lookup') || lower.contains('failed host lookup') || lower.contains('clientexception')) {
      return 'Could not connect to Memory Maker. Please check your internet connection and try again.';
    }
    if (lower.contains('invalid login') || lower.contains('invalid_credentials')) {
      return 'Login failed. Please check your email and password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email address before logging in.';
    }
    if (lower.contains('password')) {
      return 'Please check your password and try again.';
    }
    if (lower.contains('supabase') || lower.contains('url')) {
      return 'We could not connect right now. Please try again in a moment.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) return showMmSnack(context, 'Please enter a valid email address.', error: true);
    if (password.length < 6) return showMmSnack(context, 'Password must be at least 6 characters.', error: true);
    if (_signup && !_acceptedLegal) return showMmSnack(context, 'Please accept the Privacy Policy and Terms & Conditions to continue.', error: true);
    setState(() => _loading = true);
    try {
      if (_signup) {
        await RepositoryProvider.instance.signUp(email: email, password: password, name: _name.text.trim().isEmpty ? email.split('@').first : _name.text.trim());
        showMmSnack(context, 'Account created. Please check your email to confirm your account.');
        setState(() {
          _signup = false;
          _acceptedLegal = false;
        });
      } else {
        await RepositoryProvider.instance.signIn(email, password);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
      }
    } catch (e) {
      showMmSnack(context, _friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return showMmSnack(context, 'Enter your email address first.', error: true);
    try {
      await RepositoryProvider.instance.sendPasswordReset(email);
      showMmSnack(context, 'Password reset email sent if this account exists.');
    } catch (e) {
      showMmSnack(context, _friendlyError(e), error: true);
    }
  }

  void _showLegalSheet(String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .82,
        minChildSize: .45,
        maxChildSize: .94,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 44, height: 5, decoration: BoxDecoration(color: MmColors.blush, borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 10, 8),
                child: Row(children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ]),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
                  children: [
                    Text(body, style: const TextStyle(height: 1.45, color: MmColors.muted)),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: () => Navigator.pop(context), child: const Text('I understand')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _privacyText => '''Privacy Policy\n\nMemory Maker is a private event memory platform for collecting, managing, and viewing event photos, videos, messages, QR links, support requests, and account information.\n\nInformation we collect may include your name, email address, profile details, event information, uploaded media, captions, device/browser information, login activity, and support messages.\n\nWe use this information to provide secure account access, event galleries, uploads, notifications, support, service improvement, fraud prevention, and legal compliance.\n\nEvent hosts control access to private events and may approve, reject, or remove uploaded memories. Please upload only content you have permission to share.\n\nWe use trusted service providers for hosting, authentication, database storage, email delivery, analytics, and security. We do not sell personal information.\n\nUsers in Canada and the United States may request access, correction, deletion, or account support by contacting Memory Maker support. Some records may be retained when required for security, legal, billing, or operational reasons.\n\nBy creating an account, you agree that your data may be processed in the United States, Canada, or other locations where our service providers operate, subject to reasonable safeguards.\n\nThis beta policy is provided for public release readiness and should be reviewed by qualified legal counsel before full commercial launch.''';

  String get _termsText => '''Terms & Conditions\n\nBy creating a Memory Maker account, you agree to use the app lawfully, respectfully, and only for events or galleries you are authorized to access.\n\nYou are responsible for the photos, videos, messages, captions, and other content you upload. Do not upload unlawful, harmful, abusive, private, copyrighted, or sensitive content unless you have proper rights and consent.\n\nMemory Maker may remove content, restrict access, or suspend accounts when content violates these terms, privacy expectations, event rules, or applicable law.\n\nPrivate event galleries are controlled by the event host/admin. Uploaded content may remain pending until approved. Approval does not transfer ownership, but you grant Memory Maker and the event host permission to store, display, process, resize, compress, and share approved event content inside the platform.\n\nFor beta release, package purchasing and paid upgrades may be disabled. Features may change, improve, or be temporarily unavailable during testing.\n\nMemory Maker is provided as-is during beta. To the maximum extent permitted by applicable law, Memory Maker is not liable for indirect, incidental, lost-data, or consequential damages.\n\nThese terms are intended for users in Canada and the United States and should be reviewed by qualified legal counsel before full commercial launch.''';

  Widget _legalAcceptance() {
    if (!_signup) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptedLegal,
            activeColor: MmColors.roseDark,
            onChanged: (v) => setState(() => _acceptedLegal = v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: MmColors.muted, height: 1.35),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Privacy Policy', style: const TextStyle(color: MmColors.roseDark, fontWeight: FontWeight.w800), recognizer: TapGestureRecognizer()..onTap = () => _showLegalSheet('Privacy Policy', _privacyText)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Terms & Conditions', style: const TextStyle(color: MmColors.roseDark, fontWeight: FontWeight.w800), recognizer: TapGestureRecognizer()..onTap = () => _showLegalSheet('Terms & Conditions', _termsText)),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              FadeTransition(opacity: _fade, child: Center(child: Image.asset('assets/images/logo.png', height: 104, fit: BoxFit.contain))),
              const SizedBox(height: 24),
              SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: MmCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(_signup ? 'Create your account' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: MmColors.ink)),
                      const SizedBox(height: 8),
                      const Text('Private event galleries, QR sharing, uploads, notifications and support in one clean app.', style: TextStyle(color: MmColors.muted)),
                      const SizedBox(height: 20),
                      if (_signup) ...[
                        TextField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined))),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: !_showPassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _showPassword = !_showPassword)),
                        ),
                      ),
                      _legalAcceptance(),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: _loading ? null : _submit, icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_signup ? Icons.person_add_alt_1 : Icons.login), label: Text(_signup ? 'Create Account' : 'Log In')),
                      const SizedBox(height: 10),
                      TextButton(onPressed: _loading ? null : _reset, child: const Text('Forgot password? Send reset email')),
                      TextButton(onPressed: _loading ? null : () => setState(() { _signup = !_signup; _acceptedLegal = false; }), child: Text(_signup ? 'Already have an account? Log in' : 'New user? Create account')),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

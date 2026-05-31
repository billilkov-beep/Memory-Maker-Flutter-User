import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import '../utils_app.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  final _security = SecurityService();
  bool _checking = true;
  bool _pinEnabled = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pinEnabled = await _security.pinEnabled;
    final bioEnabled = await _security.biometricEnabled;
    if (!mounted) return;
    setState(() { _pinEnabled = pinEnabled; _bioEnabled = bioEnabled; _checking = false; });
    if (!pinEnabled && !bioEnabled) _unlock();
    if (bioEnabled) _useBiometric();
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => widget.child));
  }

  Future<void> _useBiometric() async {
    final ok = await _security.authenticateBiometric();
    if (ok && mounted) _unlock();
  }

  Future<void> _verifyPin() async {
    final ok = await _security.verifyPin(_pin.text.trim());
    if (ok && mounted) return _unlock();
    if (mounted) showMmSnack(context, 'Incorrect PIN. Please try again.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: MmGradientBackground(child: Center(child: CircularProgressIndicator())));
    }
    return Scaffold(
      body: MmGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: MmCard(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Image.asset('assets/images/logo.png', height: 86),
                  const SizedBox(height: 18),
                  const Text('Unlock Memory Maker', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: MmColors.ink)),
                  const SizedBox(height: 8),
                  const Text('Enter your PIN or use your device biometric unlock.', textAlign: TextAlign.center, style: TextStyle(color: MmColors.muted)),
                  const SizedBox(height: 22),
                  if (_pinEnabled) TextField(controller: _pin, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'App PIN', prefixIcon: Icon(Icons.pin_outlined))),
                  if (_pinEnabled) const SizedBox(height: 12),
                  if (_pinEnabled) FilledButton.icon(onPressed: _verifyPin, icon: const Icon(Icons.lock_open), label: const Text('Unlock')),
                  if (_bioEnabled) const SizedBox(height: 10),
                  if (_bioEnabled) OutlinedButton.icon(onPressed: _useBiometric, icon: const Icon(Icons.fingerprint), label: const Text('Use biometric unlock')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

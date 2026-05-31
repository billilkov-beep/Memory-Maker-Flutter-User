import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/image_service.dart';
import '../services/repository_provider.dart';
import '../services/security_service.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import '../utils_app.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onProfileChanged;
  const AccountScreen({super.key, this.onProfileChanged});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  MmUser? _user;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _loading = true;
  bool _pinEnabled = false;
  bool _bioEnabled = false;
  final _imageService = ImageService();
  final _security = SecurityService();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user = await RepositoryProvider.instance.currentUser();
    final pin = await _security.pinEnabled;
    final bio = await _security.biometricEnabled;
    if (mounted) setState(() { _user = user; _name.text = user?.name ?? ''; _phone.text = user?.phone ?? ''; _pinEnabled = pin; _bioEnabled = bio; _loading = false; });
  }

  Future<void> _saveProfile({bool avatar = false}) async {
    try {
      final picked = avatar ? await _imageService.pickAndCompress() : null;
      final user = await RepositoryProvider.instance.updateProfile(name: _name.text.trim(), phone: _phone.text.trim(), avatar: picked);
      if (mounted) setState(() => _user = user);
      widget.onProfileChanged?.call();
      showMmSnack(context, 'Profile updated.');
    } catch (e) { showMmSnack(context, friendlyError(e), error: true); }
  }

  Future<void> _changePassword() async {
    if (_password.text.length < 8) return showMmSnack(context, 'Password must be at least 8 characters.', error: true);
    try { await RepositoryProvider.instance.updatePassword(_password.text); _password.clear(); showMmSnack(context, 'Password updated.'); }
    catch (e) { showMmSnack(context, friendlyError(e), error: true); }
  }

  Future<void> _togglePin(bool value) async {
    if (!value) {
      await _security.disablePin();
      if (mounted) setState(() => _pinEnabled = false);
      return showMmSnack(context, 'PIN lock disabled.');
    }
    final pin = await _showPinDialog();
    if (pin == null) return;
    await _security.setPin(pin);
    if (mounted) setState(() => _pinEnabled = true);
    showMmSnack(context, 'PIN lock enabled.');
  }

  Future<String?> _showPinDialog() async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Set app PIN'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'New PIN')),
        const SizedBox(height: 8),
        TextField(controller: c2, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration(labelText: 'Confirm PIN')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final a = c1.text.trim();
          final b = c2.text.trim();
          if (a.length < 4 || a != b) return showMmSnack(context, 'PIN must match and be at least 4 digits.', error: true);
          Navigator.pop(context, a);
        }, child: const Text('Save PIN')),
      ],
    ));
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      await _security.disableBiometric();
      if (mounted) setState(() => _bioEnabled = false);
      return showMmSnack(context, 'Biometric unlock disabled.');
    }
    final ok = await _security.enableBiometric();
    if (mounted) setState(() => _bioEnabled = ok);
    showMmSnack(context, ok ? 'Biometric unlock enabled.' : 'Biometric unlock is not available on this device.', error: !ok);
  }

  Future<void> _logout() async {
    await RepositoryProvider.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.w900))),
    body: MmGradientBackground(child: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(18), children: [
      MmCard(child: Column(children: [
        Stack(children: [
          CircleAvatar(radius: 44, backgroundColor: MmColors.blush, backgroundImage: imageProviderFromValue(_user?.avatarUrl), child: imageProviderFromValue(_user?.avatarUrl) == null ? const Icon(Icons.person, color: MmColors.roseDark, size: 42) : null),
          Positioned(right: 0, bottom: 0, child: InkWell(onTap: () => _saveProfile(avatar: true), child: const CircleAvatar(radius: 17, backgroundColor: MmColors.roseDark, child: Icon(Icons.camera_alt, size: 16, color: Colors.white))))
        ]),
        const SizedBox(height: 12),
        Text(_user?.name ?? 'Memory Maker User', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(_user?.email ?? '', style: const TextStyle(color: MmColors.muted)),
      ])),
      const SizedBox(height: 16),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Profile settings', subtitle: 'Update your name, phone, and profile picture. Pull down to refresh after web changes.'),
        const SizedBox(height: 14),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () => _saveProfile(), icon: const Icon(Icons.save_outlined), label: const Text('Save Profile')),
      ])),
      const SizedBox(height: 16),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Change password', subtitle: 'Use a strong password with at least 8 characters.'),
        const SizedBox(height: 14),
        TextField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'New password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPassword = !_showPassword)))),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.password), label: const Text('Update Password')),
      ])),
      const SizedBox(height: 16),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Account security', subtitle: 'Protect your private galleries with PIN or biometric unlock.'),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const CircleAvatar(backgroundColor: MmColors.blush, child: Icon(Icons.pin_outlined, color: MmColors.roseDark)),
          title: const Text('App PIN lock', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Ask for a PIN when opening Memory Maker.'),
          value: _pinEnabled,
          onChanged: _togglePin,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const CircleAvatar(backgroundColor: MmColors.blush, child: Icon(Icons.fingerprint, color: MmColors.roseDark)),
          title: const Text('Biometric unlock', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Use fingerprint or face unlock where available.'),
          value: _bioEnabled,
          onChanged: _toggleBiometric,
        ),
      ])),
      const SizedBox(height: 16),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9E2F3B)), onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Sign Out')),
    ]))),
  );
}

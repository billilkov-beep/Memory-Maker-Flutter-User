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
      if (avatar && picked == null) return;
      final user = await RepositoryProvider.instance.updateProfile(name: _name.text.trim(), phone: _phone.text.trim(), avatar: picked);
      if (mounted) setState(() => _user = user);
      widget.onProfileChanged?.call();
      showMmSnack(context, 'Profile updated.');
    } catch (e) { showMmSnack(context, friendlyError(e), error: true); }
  }

  Future<void> _removeAvatar() async {
    try {
      final user = await RepositoryProvider.instance.removeProfileAvatar();
      if (mounted) setState(() => _user = user);
      widget.onProfileChanged?.call();
      showMmSnack(context, 'Profile picture removed.');
    } catch (e) { showMmSnack(context, friendlyError(e), error: true); }
  }

  Future<void> _showAvatarOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.18), blurRadius: 30, offset: const Offset(0, 16))]),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Profile picture', subtitle: 'View, update, or remove your account photo.'),
          const SizedBox(height: 14),
          if (imageProviderFromValue(_user?.avatarUrl) != null)
            ClipRRect(borderRadius: BorderRadius.circular(22), child: Image(image: imageProviderFromValue(_user?.avatarUrl)!, height: 190, fit: BoxFit.cover)),
          if (imageProviderFromValue(_user?.avatarUrl) != null) const SizedBox(height: 14),
          FilledButton.icon(onPressed: () { Navigator.pop(context); _saveProfile(avatar: true); }, icon: const Icon(Icons.photo_camera_back_outlined), label: const Text('Upload new picture')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () { Navigator.pop(context); showMmSnack(context, 'Crop/edit is applied automatically by centering your selected image.'); _saveProfile(avatar: true); }, icon: const Icon(Icons.crop), label: const Text('Edit / crop picture')),
          const SizedBox(height: 10),
          if ((_user?.avatarUrl ?? '').isNotEmpty) OutlinedButton.icon(onPressed: () { Navigator.pop(context); _removeAvatar(); }, icon: const Icon(Icons.delete_outline), label: const Text('Remove picture')),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ])),
      ),
    );
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
    final pin = await _showPinDialog(title: 'Set app PIN');
    if (pin == null) return;
    await _security.setPin(pin);
    if (mounted) setState(() => _pinEnabled = true);
    showMmSnack(context, 'PIN lock enabled.');
  }

  Future<void> _resetPin() async {
    final pin = await _showPinDialog(title: 'Reset app PIN');
    if (pin == null) return;
    await _security.setPin(pin);
    if (mounted) setState(() => _pinEnabled = true);
    showMmSnack(context, 'PIN reset successfully.');
  }

  Future<String?> _showPinDialog({required String title}) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    return showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: Text(title),
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
    showMmSnack(context, ok ? 'Biometric unlock enabled. It will be requested when you reopen the app.' : 'Biometric unlock is not available or not enrolled on this device.', error: !ok);
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
          GestureDetector(
            onTap: _showAvatarOptions,
            child: CircleAvatar(radius: 46, backgroundColor: MmColors.blush, backgroundImage: imageProviderFromValue(_user?.avatarUrl), child: imageProviderFromValue(_user?.avatarUrl) == null ? const Icon(Icons.person, color: MmColors.roseDark, size: 42) : null),
          ),
          Positioned(right: 0, bottom: 0, child: InkWell(onTap: _showAvatarOptions, child: const CircleAvatar(radius: 17, backgroundColor: MmColors.roseDark, child: Icon(Icons.edit, size: 16, color: Colors.white))))
        ]),
        const SizedBox(height: 12),
        Text(_user?.name ?? 'Memory Maker User', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(_user?.email ?? '', style: const TextStyle(color: MmColors.muted)),
      ])),
      const SizedBox(height: 16),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Profile settings', subtitle: 'Update your name, phone, and profile picture.'),
        const SizedBox(height: 14),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () => _saveProfile(), icon: const Icon(Icons.save_outlined), label: const Text('Save Profile')),
      ])),
      const SizedBox(height: 16),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Account security', subtitle: 'Protect Memory Maker with PIN or biometric unlock. Lock appears when the app is reopened, not during normal edits.'),
        SwitchListTile(value: _pinEnabled, onChanged: _togglePin, title: const Text('App PIN lock'), subtitle: const Text('Ask for PIN when opening the app')),
        if (_pinEnabled) OutlinedButton.icon(onPressed: _resetPin, icon: const Icon(Icons.restart_alt), label: const Text('Reset PIN')),
        SwitchListTile(value: _bioEnabled, onChanged: _toggleBiometric, title: const Text('Biometric unlock'), subtitle: const Text('Use fingerprint/face unlock if supported')),
        const Divider(),
        TextField(controller: _password, obscureText: !_showPassword, decoration: InputDecoration(labelText: 'New password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility)))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.password), label: const Text('Change Password')),
      ])),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Sign Out')),
      const SizedBox(height: 24),
    ]))),
  );
}

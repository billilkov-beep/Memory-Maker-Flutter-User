import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/image_service.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
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
  final _imageService = ImageService();

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final user = await RepositoryProvider.instance.currentUser();
    if (mounted) setState(() { _user = user; _name.text = user?.name ?? ''; _phone.text = user?.phone ?? ''; _loading = false; });
  }

  Future<void> _saveProfile({bool avatar = false}) async {
    try {
      final picked = avatar ? await _imageService.pickAndCompress() : null;
      final user = await RepositoryProvider.instance.updateProfile(name: _name.text.trim(), phone: _phone.text.trim(), avatar: picked);
      if (mounted) setState(() => _user = user);
      showMmSnack(context, 'Profile updated.');
    } catch (e) { showMmSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true); }
  }

  Future<void> _changePassword() async {
    if (_password.text.length < 8) return showMmSnack(context, 'Password must be at least 8 characters.', error: true);
    try { await RepositoryProvider.instance.updatePassword(_password.text); _password.clear(); showMmSnack(context, 'Password updated.'); }
    catch (_) { showMmSnack(context, 'Could not update password. Please try again.', error: true); }
  }

  Future<void> _logout() async {
    await RepositoryProvider.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.w900))),
    body: MmGradientBackground(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [
      MmCard(child: Column(children: [
        Stack(children: [
          CircleAvatar(radius: 44, backgroundColor: MmColors.blush, backgroundImage: (_user?.avatarUrl != null && _user!.avatarUrl!.startsWith('http')) ? NetworkImage(_user!.avatarUrl!) : null, child: _user?.avatarUrl == null ? const Icon(Icons.person, color: MmColors.roseDark, size: 42) : null),
          Positioned(right: 0, bottom: 0, child: InkWell(onTap: () => _saveProfile(avatar: true), child: const CircleAvatar(radius: 17, backgroundColor: MmColors.roseDark, child: Icon(Icons.camera_alt, size: 16, color: Colors.white))))
        ]),
        const SizedBox(height: 12),
        Text(_user?.name ?? 'MemoryMaker User', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(_user?.email ?? '', style: const TextStyle(color: MmColors.muted)),
      ])),
      const SizedBox(height: 16),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Profile settings', subtitle: 'Update your name, phone, and profile picture.'),
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
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9E2F3B)), onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Sign Out')),
    ])),
  );
}

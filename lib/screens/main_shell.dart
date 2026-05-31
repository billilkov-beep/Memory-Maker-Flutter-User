import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../utils_app.dart';
import 'account_screen.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'support_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  MmUser? _user;

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    final user = await RepositoryProvider.instance.currentUser();
    if (mounted) setState(() => _user = user);
  }

  List<Widget> get _pages => const [DashboardScreen(), EventsScreen(), NotificationsScreen(), SupportScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    final avatar = imageProviderFromValue(_user?.avatarUrl);
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(.96), boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.12), blurRadius: 22, offset: const Offset(0, -8))]),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) async { setState(() => _index = i); await _refreshUser(); },
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.collections_outlined), selectedIcon: Icon(Icons.collections_rounded), label: 'Events'),
            const NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications_rounded), label: 'Alerts'),
            const NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent_rounded), label: 'Support'),
            NavigationDestination(
              icon: CircleAvatar(radius: 12, backgroundColor: MmColors.blush, backgroundImage: avatar, child: avatar == null ? const Icon(Icons.person_outline, size: 17) : null),
              selectedIcon: CircleAvatar(radius: 14, backgroundColor: MmColors.blush, backgroundImage: avatar, child: avatar == null ? const Icon(Icons.person_rounded, size: 18, color: MmColors.roseDark) : null),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

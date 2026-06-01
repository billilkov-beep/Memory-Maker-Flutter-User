import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/permissions_service.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import '../utils_app.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final MmUser? user;
  final VoidCallback? onOpenAccount;
  const DashboardScreen({super.key, this.user, this.onOpenAccount});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MmEvent> _events = [];
  MmUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    PermissionsService.requestNotifications();
  }

  Future<void> _load() async {
    try {
      final user = await RepositoryProvider.instance.currentUser();
      final events = await RepositoryProvider.instance.loadEvents();
      if (mounted) setState(() { _user = user; _events = events; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MmGradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(18), children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, ${(widget.user ?? _user)?.name.split(' ').first ?? 'there'}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: MmColors.ink)),
                  const Text('Collect, approve, and share every event memory.', style: TextStyle(color: MmColors.muted)),
                ])),
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: widget.onOpenAccount,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: MmColors.blush,
                    backgroundImage: imageProviderFromValue((widget.user ?? _user)?.avatarUrl),
                    child: imageProviderFromValue((widget.user ?? _user)?.avatarUrl) == null ? const Icon(Icons.person, color: MmColors.roseDark) : null,
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), gradient: const LinearGradient(colors: [MmColors.roseDark, Color(0xFFC77982)]), boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.25), blurRadius: 28, offset: Offset(0, 14))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 34),
                  const SizedBox(height: 12),
                  const Text('Collect every memory from one private event gallery.', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Create private galleries, invite guests by QR, upload from camera/gallery, and keep memories organized in one beautiful space.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())).then((_) => _load()), icon: const Icon(Icons.add), label: const Text('Create Gallery')),
                ]),
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _MetricCard(label: 'Events', value: '${_events.length}', icon: Icons.event_available)),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(label: 'Uploads', value: '${_events.fold<int>(0, (v, e) => v + e.mediaCount)}', icon: Icons.photo_library_outlined)),
              ]),
              const SizedBox(height: 18),
              Row(children: const [
                Expanded(child: _FeatureMiniCard(icon: Icons.photo_camera_back_outlined, title: 'Smart Uploads', body: 'Compressed photos save storage.')),
                SizedBox(width: 12),
                Expanded(child: _FeatureMiniCard(icon: Icons.qr_code_2_rounded, title: 'QR Sharing', body: 'Invite guests with one tap.')),
              ]),
              const SizedBox(height: 22),
              SectionTitle('Recent galleries', subtitle: 'Tap an event to upload, share QR code, or view gallery.'),
              const SizedBox(height: 12),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_events.isEmpty) const EmptyState(icon: Icons.collections_bookmark_outlined, title: 'No galleries yet', body: 'Create your first event gallery and start collecting memories.')
              else ..._events.take(3).map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MmCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))).then((_) => _load()), child: Row(children: [
                  const CircleAvatar(backgroundColor: MmColors.blush, child: Icon(Icons.favorite, color: MmColors.roseDark)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${event.kind} • ${event.status}', style: const TextStyle(color: MmColors.muted, fontSize: 12))])),
                  const Icon(Icons.chevron_right),
                ])),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: MmColors.roseDark), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: MmColors.muted))]));
}


class _FeatureMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _FeatureMiniCard({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.78),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: MmColors.blush),
      boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.06), blurRadius: 18, offset: const Offset(0, 10))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: MmColors.roseDark),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(fontSize: 12, color: MmColors.muted)),
    ]),
  );
}

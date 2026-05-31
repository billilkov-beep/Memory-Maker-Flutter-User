import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<MmEvent>> _future;
  @override
  void initState() { super.initState(); _future = RepositoryProvider.instance.loadEvents(); }
  Future<void> _refresh() async => setState(() => _future = RepositoryProvider.instance.loadEvents());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Galleries', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())).then((_) => _refresh()), icon: const Icon(Icons.add_circle_outline))]),
    body: MmGradientBackground(child: RefreshIndicator(onRefresh: () async => _refresh(), child: FutureBuilder<List<MmEvent>>(future: _future, builder: (context, snap) {
      final events = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(18), children: [
        const SectionTitle('Event galleries', subtitle: 'Manage QR code, upload photos and view approved memories.'),
        const SizedBox(height: 14),
        if (snap.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else if (events.isEmpty) const EmptyState(icon: Icons.add_photo_alternate_outlined, title: 'Create your first gallery', body: 'Package buying is disabled for beta. Create a free beta gallery now.')
        else ...events.map((event) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MmCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))).then((_) => _refresh()), child: Row(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: MmColors.blush), child: const Icon(Icons.collections_rounded, color: MmColors.roseDark)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('${event.kind} • ${event.status}', style: const TextStyle(color: MmColors.muted)), const SizedBox(height: 8), LinearProgressIndicator(value: .28, backgroundColor: MmColors.blush, color: MmColors.roseDark, borderRadius: BorderRadius.circular(99))])),
          const Icon(Icons.chevron_right_rounded),
        ]))))
      ]);
    }))),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())).then((_) => _refresh()), icon: const Icon(Icons.add), label: const Text('New')),
  );
}

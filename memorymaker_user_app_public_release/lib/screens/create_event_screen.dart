import 'package:flutter/material.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _title = TextEditingController();
  String _kind = 'Wedding';
  bool _loading = false;
  final _kinds = const ['Wedding', 'Memorial', 'Birthday', 'Graduation', 'Corporate', 'Family Reunion', 'Community'];

  Future<void> _create() async {
    if (_title.text.trim().length < 3) return showMmSnack(context, 'Please enter an event title.', error: true);
    setState(() => _loading = true);
    try {
      await RepositoryProvider.instance.createEvent(title: _title.text.trim(), kind: _kind);
      showMmSnack(context, 'Gallery created. You can now upload photos and share QR code.');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMmSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Gallery', style: TextStyle(fontWeight: FontWeight.w900))),
    body: MmGradientBackground(child: ListView(padding: const EdgeInsets.all(18), children: [
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Free beta gallery', subtitle: 'Package buying is disabled for now. Create a gallery and start testing upload flow.'),
        const SizedBox(height: 18),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Event title', prefixIcon: Icon(Icons.event_note_outlined))),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _kind, decoration: const InputDecoration(labelText: 'Event type', prefixIcon: Icon(Icons.category_outlined)), items: _kinds.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(), onChanged: (v) => setState(() => _kind = v ?? _kind)),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _loading ? null : _create, icon: const Icon(Icons.auto_awesome), label: Text(_loading ? 'Creating...' : 'Create Gallery')),
      ])),
    ])),
  );
}

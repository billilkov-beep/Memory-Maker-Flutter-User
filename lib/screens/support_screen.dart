import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  late Future<List<SupportTicket>> _future;
  bool _loading = false;

  @override
  void initState() { super.initState(); _future = RepositoryProvider.instance.loadTickets(); }

  Future<void> _send() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) return showMmSnack(context, 'Please enter subject and message.', error: true);
    setState(() => _loading = true);
    try {
      await RepositoryProvider.instance.createTicket(subject: _subject.text.trim(), message: _message.text.trim());
      _subject.clear(); _message.clear();
      setState(() => _future = RepositoryProvider.instance.loadTickets());
      showMmSnack(context, 'Support ticket created.');
    } catch (e) { showMmSnack(context, 'Could not create ticket. Please try again.', error: true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Support', style: TextStyle(fontWeight: FontWeight.w900))),
    body: MmGradientBackground(child: ListView(padding: const EdgeInsets.all(18), children: [
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Need help?', subtitle: 'Send a support request for gallery, upload, login or account questions.'),
        const SizedBox(height: 14),
        TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.subject_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _message, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true, prefixIcon: Icon(Icons.message_outlined))),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _loading ? null : _send, icon: const Icon(Icons.send), label: Text(_loading ? 'Sending...' : 'Create Ticket')),
      ])),
      const SizedBox(height: 18),
      const SectionTitle('My tickets'),
      const SizedBox(height: 12),
      FutureBuilder<List<SupportTicket>>(future: _future, builder: (context, snap) {
        final tickets = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (tickets.isEmpty) return const EmptyState(icon: Icons.support_agent, title: 'No tickets yet', body: 'Your support requests will appear here.');
        return Column(children: tickets.map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w900))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: MmColors.blush, borderRadius: BorderRadius.circular(99)), child: Text(t.status, style: const TextStyle(fontSize: 12, color: MmColors.roseDark, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 6), Text(t.message, style: const TextStyle(color: MmColors.muted)),
        ])))).toList());
      })
    ])),
  );
}

import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/permissions_service.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<MmNotification>> _future;
  @override
  void initState() { super.initState(); _future = RepositoryProvider.instance.loadNotifications(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () async { final ok = await PermissionsService.requestNotifications(); showMmSnack(context, ok ? 'Notifications permission enabled.' : 'Notifications permission was not enabled.', error: !ok); }, icon: const Icon(Icons.notifications_active_outlined))]),
    body: MmGradientBackground(child: FutureBuilder<List<MmNotification>>(future: _future, builder: (context, snap) {
      final items = snap.data ?? [];
      return ListView(padding: const EdgeInsets.all(18), children: [
        const SectionTitle('Latest updates', subtitle: 'Approvals, upload confirmations, gallery reminders and support updates.'),
        const SizedBox(height: 14),
        if (snap.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else if (items.isEmpty) const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications yet', body: 'You will see upload, approval, support and event alerts here.')
        else ...items.map((n) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MmCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: n.read ? MmColors.ivory : MmColors.blush, child: Icon(n.read ? Icons.mark_email_read_outlined : Icons.notifications, color: MmColors.roseDark)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(n.body, style: const TextStyle(color: MmColors.muted))])),
        ]))))
      ]);
    })),
  );
}

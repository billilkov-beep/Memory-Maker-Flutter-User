import 'dart:math';
import '../config/app_config.dart';
import '../models/app_models.dart';
import 'image_service.dart';
import 'memorymaker_repository.dart';

class DemoRepository implements MemoryMakerRepository {
  MmUser? _user;
  final List<MmEvent> _events = [
    MmEvent(id: 'demo-event-1', title: 'Rose Garden Wedding', slug: 'rose-garden-wedding', kind: 'Wedding', status: 'active', date: DateTime.now().add(const Duration(days: 12)), mediaCount: 8, pendingCount: 2),
  ];
  final Map<String, List<MmMedia>> _media = {'demo-event-1': []};
  final List<SupportTicket> _tickets = [];

  @override
  Future<bool> get isSignedIn async => _user != null;

  @override
  Future<MmUser?> currentUser() async => _user;

  @override
  Future<MmUser> signIn(String email, String password) async {
    if (email.trim().toLowerCase() == 'admin@memorymaker.com' && password == 'Test@123456') {
      _user = const MmUser(id: 'demo-user', email: 'admin@memorymaker.com', name: 'MemoryMaker Demo Host', phone: '+1 555 0100');
      return _user!;
    }
    throw Exception('Use admin@memorymaker.com / Test@123456 for demo login.');
  }

  @override
  Future<void> signUp({required String email, required String password, required String name}) async {
    _user = MmUser(id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}', email: email, name: name);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<void> signOut() async => _user = null;

  @override
  Future<MmUser> updateProfile({required String name, String? phone, PickedCompressedImage? avatar}) async {
    _user = (_user ?? const MmUser(id: 'demo-user', email: 'admin@memorymaker.com', name: 'Demo Host')).copyWith(name: name, phone: phone, avatarUrl: avatar == null ? null : 'memorymaker-local-avatar');
    return _user!;
  }

  @override
  Future<List<MmEvent>> loadEvents() async => _events;

  @override
  Future<MmEvent> createEvent({required String title, required String kind, DateTime? date}) async {
    final event = MmEvent(id: 'demo-${Random().nextInt(999999)}', title: title, slug: title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'), kind: kind, date: date, status: 'active');
    _events.insert(0, event);
    _media[event.id] = [];
    return event;
  }

  @override
  Future<List<MmMedia>> loadMedia(String eventId) async => _media[eventId] ?? [];

  @override
  Future<MmMedia> uploadPhoto({required String eventId, required PickedCompressedImage image, String? caption}) async {
    final media = MmMedia(id: 'media-${Random().nextInt(999999)}', eventId: eventId, filename: image.fileName, caption: caption, status: 'approved', url: null, createdAt: DateTime.now());
    _media.putIfAbsent(eventId, () => []).insert(0, media);
    return media;
  }

  @override
  Future<List<MmNotification>> loadNotifications() async => [
        MmNotification(id: 'n1', title: 'Gallery ready', body: 'Your event gallery is active and ready for uploads.', createdAt: DateTime.now().subtract(const Duration(minutes: 18))),
        MmNotification(id: 'n2', title: 'QR sharing enabled', body: 'Share the QR code with your guests to collect memories.', read: true, createdAt: DateTime.now().subtract(const Duration(hours: 3))),
      ];

  @override
  Future<List<SupportTicket>> loadTickets() async => _tickets;

  @override
  Future<SupportTicket> createTicket({required String subject, required String message}) async {
    final ticket = SupportTicket(id: 'ticket-${Random().nextInt(999999)}', subject: subject, message: message, createdAt: DateTime.now());
    _tickets.insert(0, ticket);
    return ticket;
  }

  String eventShareUrl(MmEvent event) => event.galleryUrl(AppConfig.appUrl);
}

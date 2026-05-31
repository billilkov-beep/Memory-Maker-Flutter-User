class MmUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;

  const MmUser({required this.id, required this.email, required this.name, this.phone, this.avatarUrl});

  MmUser copyWith({String? name, String? phone, String? avatarUrl}) => MmUser(id: id, email: email, name: name ?? this.name, phone: phone ?? this.phone, avatarUrl: avatarUrl ?? this.avatarUrl);
}

class MmEvent {
  final String id;
  final String title;
  final String slug;
  final String kind;
  final String status;
  final String? coverUrl;
  final DateTime? date;
  final int mediaCount;
  final int pendingCount;

  const MmEvent({required this.id, required this.title, required this.slug, this.kind = 'event', this.status = 'active', this.coverUrl, this.date, this.mediaCount = 0, this.pendingCount = 0});

  String galleryUrl(String appUrl) => '$appUrl/e/$slug';
}

class MmMedia {
  final String id;
  final String eventId;
  final String filename;
  final String status;
  final String? caption;
  final String? url;
  final DateTime? createdAt;

  const MmMedia({required this.id, required this.eventId, required this.filename, this.status = 'pending', this.caption, this.url, this.createdAt});
}

class MmNotification {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const MmNotification({required this.id, required this.title, required this.body, this.read = false, required this.createdAt});
}

class SupportTicket {
  final String id;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  const SupportTicket({required this.id, required this.subject, required this.message, this.status = 'open', required this.createdAt});
}

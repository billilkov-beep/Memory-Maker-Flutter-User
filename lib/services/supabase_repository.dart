import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/app_models.dart';
import 'image_service.dart';
import 'memorymaker_repository.dart';

class SupabaseRepository implements MemoryMakerRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<bool> get isSignedIn async => _client.auth.currentUser != null;

  Map<String, dynamic> _asMap(dynamic value) => value is Map<String, dynamic> ? value : Map<String, dynamic>.from(value as Map);

  String? _readString(Map<String, dynamic>? row, List<String> keys) {
    if (row == null) return null;
    for (final key in keys) {
      final v = row[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  @override
  Future<MmUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    Map<String, dynamic>? profile;
    try {
      final row = await _client.from('profiles').select('full_name,phone,avatar_url,avatar_base64,avatar_content_type,profile_picture_url,profile_photo_url,image_url,photo_url').eq('id', user.id).maybeSingle();
      profile = row == null ? null : _asMap(row);
    } catch (_) {
      profile = null;
    }
    final avatarBase64 = _readString(profile, ['avatar_base64']);
    final avatarContentType = _readString(profile, ['avatar_content_type']) ?? 'image/jpeg';
    final avatarUrl = avatarBase64 != null
        ? 'data:$avatarContentType;base64,$avatarBase64'
        : _readString(profile, ['avatar_url', 'profile_picture_url', 'profile_photo_url', 'image_url', 'photo_url']);
    return MmUser(
      id: user.id,
      email: user.email ?? '',
      name: _readString(profile, ['full_name']) ?? user.userMetadata?['full_name']?.toString() ?? user.email?.split('@').first ?? 'Memory Maker User',
      phone: _readString(profile, ['phone']),
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<MmUser> signIn(String email, String password) async {
    final result = await _client.auth.signInWithPassword(email: email.trim(), password: password);
    if (result.user == null) throw Exception('Login failed. Please check your email and password.');
    final user = await currentUser();
    if (user == null) throw Exception('Could not load account.');
    return user;
  }

  @override
  Future<void> signUp({required String email, required String password, required String name}) async {
    await _client.auth.signUp(email: email.trim(), password: password, data: {'full_name': name});
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim(), redirectTo: '${AppConfig.appUrl}/auth/reset-password');
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<MmUser> updateProfile({required String name, String? phone, PickedCompressedImage? avatar}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    final payload = <String, dynamic>{
      'id': user.id,
      'full_name': name,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatar != null) {
      payload['avatar_base64'] = avatar.compressedBase64;
      payload['avatar_content_type'] = avatar.compressedContentType;
      payload['avatar_url'] = 'data:${avatar.compressedContentType};base64,${avatar.compressedBase64}';
    }
    await _client.from('profiles').upsert(payload);
    return (await currentUser())!;
  }

  @override
  Future<List<MmEvent>> loadEvents() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');

    List rows;
    try {
      rows = await _client.rpc('app_list_events_v2') as List;
    } catch (_) {
      rows = await _client
          .from('events')
          .select('id,title,name,slug,event_kind,event_type,status,gallery_cover_url,event_start_at,created_at')
          .or('owner_id.eq.${user.id},user_id.eq.${user.id}')
          .order('created_at', ascending: false) as List;
    }

    return rows.map<MmEvent>((raw) {
      final row = _asMap(raw);
      return MmEvent(
        id: row['id'].toString(),
        title: _readString(row, ['title', 'name']) ?? 'Untitled gallery',
        slug: _readString(row, ['slug']) ?? row['id'].toString(),
        kind: _readString(row, ['event_kind', 'event_type', 'kind']) ?? 'Event',
        status: _readString(row, ['status']) ?? 'active',
        coverUrl: _readString(row, ['gallery_cover_url', 'cover_url']),
        date: row['event_start_at'] == null ? null : DateTime.tryParse(row['event_start_at'].toString()),
        mediaCount: int.tryParse('${row['media_count'] ?? row['media_count_value'] ?? 0}') ?? 0,
      );
    }).toList();
  }

  @override
  Future<MmEvent> createEvent({required String title, required String kind, DateTime? date}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    final safeTitle = title.trim().isEmpty ? 'My Memory Gallery' : title.trim();

    try {
      final row = await _client.rpc('app_create_event_v2', params: {'p_title': safeTitle, 'p_kind': kind}).single();
      final map = _asMap(row);
      return MmEvent(
        id: map['id'].toString(),
        title: _readString(map, ['title', 'name']) ?? safeTitle,
        slug: _readString(map, ['slug']) ?? map['id'].toString(),
        kind: _readString(map, ['event_kind', 'event_type']) ?? kind,
        status: _readString(map, ['status']) ?? 'active',
        date: date,
      );
    } catch (_) {
      final slug = '${safeTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final payload = <String, dynamic>{
        'owner_id': user.id,
        'user_id': user.id,
        'title': safeTitle,
        'name': safeTitle,
        'slug': slug,
        'event_kind': kind,
        'status': 'active',
        'event_start_at': (date ?? DateTime.now()).toIso8601String(),
        'beta_free_access': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final row = await _client.from('events').insert(payload).select().single();
      return MmEvent(id: row['id'].toString(), title: _readString(_asMap(row), ['title', 'name']) ?? safeTitle, slug: _readString(_asMap(row), ['slug']) ?? slug, kind: kind, status: _readString(_asMap(row), ['status']) ?? 'active', date: date);
    }
  }

  @override
  Future<List<MmMedia>> loadMedia(String eventId) async {
    List rows;
    try {
      rows = await _client.rpc('app_list_media_v2', params: {'p_event_id': eventId}) as List;
    } catch (_) {
      rows = await _client
          .from('media_uploads')
          .select('id,event_id,original_filename,file_url,thumbnail_url,object_key,storage_key,status,caption,uploaded_at,created_at,media_blobs(compressed_content_type,compressed_base64)')
          .eq('event_id', eventId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false) as List;
    }
    return rows.map<MmMedia>((raw) {
      final row = _asMap(raw);
      String? directDataUrl;
      if (row['data_url'] != null && row['data_url'].toString().startsWith('data:image')) {
        directDataUrl = row['data_url'].toString();
      } else {
        final blob = row['media_blobs'];
        if (blob is Map && blob['compressed_base64'] != null) {
          directDataUrl = 'data:${blob['compressed_content_type'] ?? 'image/jpeg'};base64,${blob['compressed_base64']}';
        }
      }
      return MmMedia(
        id: row['id'].toString(),
        eventId: row['event_id'].toString(),
        filename: _readString(row, ['original_filename', 'filename', 'object_key', 'storage_key']) ?? 'memory.jpg',
        status: _readString(row, ['status']) ?? 'pending',
        caption: _readString(row, ['caption']),
        url: directDataUrl ?? _readString(row, ['file_url', 'thumbnail_url']) ?? '${AppConfig.appUrl}/api/media/${row['id']}/file',
        createdAt: row['created_at'] == null ? (row['uploaded_at'] == null ? null : DateTime.tryParse(row['uploaded_at'].toString())) : DateTime.tryParse(row['created_at'].toString()),
      );
    }).toList();
  }

  @override
  Future<MmMedia> uploadPhoto({required String eventId, required PickedCompressedImage image, String? caption}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');

    final row = await _client.rpc('app_upload_photo_v2', params: {
      'p_event_id': eventId,
      'p_filename': image.fileName,
      'p_content_type': image.compressedContentType,
      'p_original_content_type': image.originalContentType,
      'p_original_bytes': image.originalBytes,
      'p_compressed_bytes': image.compressedBytes,
      'p_compressed_base64': image.compressedBase64,
      'p_width': image.width,
      'p_height': image.height,
      'p_caption': caption ?? '',
    }).single();
    final map = _asMap(row);
    final uploadId = map['id'].toString();
    return MmMedia(
      id: uploadId,
      eventId: eventId,
      filename: _readString(map, ['original_filename', 'filename']) ?? image.fileName,
      status: _readString(map, ['status']) ?? 'pending',
      caption: caption,
      url: 'data:${image.compressedContentType};base64,${image.compressedBase64}',
      createdAt: DateTime.now(),
    );
  }

  Future<String> _ensureUploader(String eventId, User user) async {
    final existing = await _client.from('event_guests').select('id').eq('event_id', eventId).eq('user_id', user.id).maybeSingle();
    if (existing != null) return existing['id'].toString();
    final inserted = await _client.from('event_guests').insert({
      'event_id': eventId,
      'user_id': user.id,
      'email': (user.email ?? '${user.id}@memorymaker.local').toLowerCase(),
      'display_name': user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'Guest',
      'status': 'accepted',
      'invited_at': DateTime.now().toIso8601String(),
      'accepted_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    return inserted['id'].toString();
  }

  @override
  Future<List<MmNotification>> loadNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from('user_notifications').select('id,title,body,status,created_at').eq('user_id', user.id).order('created_at', ascending: false).limit(50);
    return (rows as List).map<MmNotification>((raw) {
      final row = _asMap(raw);
      return MmNotification(id: row['id'].toString(), title: row['title'].toString(), body: (row['body'] ?? '').toString(), read: row['status'] == 'read', createdAt: DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now());
    }).toList();
  }

  @override
  Future<List<SupportTicket>> loadTickets() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from('support_tickets').select('id,subject,message,status,admin_reply,created_at,updated_at').eq('user_id', user.id).order('updated_at', ascending: false).limit(50);
    return (rows as List).map<SupportTicket>((raw) {
      final row = _asMap(raw);
      final reply = _readString(row, ['admin_reply']);
      final message = reply == null ? (row['message'] ?? '').toString() : '${row['message'] ?? ''}\n\nAdmin reply: $reply';
      return SupportTicket(id: row['id'].toString(), subject: row['subject'].toString(), message: message, status: (row['status'] ?? 'open').toString(), createdAt: DateTime.tryParse((row['updated_at'] ?? row['created_at']).toString()) ?? DateTime.now());
    }).toList();
  }

  @override
  Future<SupportTicket> createTicket({required String subject, required String message}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    try {
      final row = await _client.rpc('app_create_support_ticket_v2', params: {'p_subject': subject, 'p_message': message}).single();
      final map = _asMap(row);
      return SupportTicket(id: map['id'].toString(), subject: map['subject'].toString(), message: map['message'].toString(), status: (map['status'] ?? 'open').toString(), createdAt: DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now());
    } catch (_) {
      final row = await _client.from('support_tickets').insert({'user_id': user.id, 'subject': subject, 'message': message, 'status': 'open', 'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()}).select().single();
      try {
        await _client.from('user_notifications').insert({'user_id': user.id, 'title': 'Support request sent', 'body': 'We received your support request and will reply soon.', 'status': 'unread'});
      } catch (_) {}
      return SupportTicket(id: row['id'].toString(), subject: row['subject'].toString(), message: row['message'].toString(), status: (row['status'] ?? 'open').toString(), createdAt: DateTime.tryParse((row['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now());
    }
  }
}


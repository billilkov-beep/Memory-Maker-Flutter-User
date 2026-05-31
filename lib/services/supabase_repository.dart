import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/app_models.dart';
import 'image_service.dart';
import 'memorymaker_repository.dart';

class SupabaseRepository implements MemoryMakerRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<bool> get isSignedIn async => _client.auth.currentUser != null;

  @override
  Future<MmUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final profile = await _client.from('profiles').select('full_name,phone,avatar_url').eq('id', user.id).maybeSingle();
    return MmUser(id: user.id, email: user.email ?? '', name: (profile?['full_name'] ?? user.email?.split('@').first ?? 'MemoryMaker User').toString(), phone: profile?['phone']?.toString(), avatarUrl: profile?['avatar_url']?.toString());
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
    String? avatarUrl;
    if (avatar != null) {
      avatarUrl = 'data:${avatar.compressedContentType};base64,${avatar.compressedBase64}';
    }
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': name,
      'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return (await currentUser())!;
  }

  @override
  Future<List<MmEvent>> loadEvents() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    final rows = await _client.from('events').select('id,title,slug,event_kind,status,gallery_cover_url,event_start_at,created_at').eq('owner_id', user.id).order('created_at', ascending: false);
    return rows.map<MmEvent>((row) => MmEvent(
          id: row['id'].toString(),
          title: (row['title'] ?? 'Untitled event').toString(),
          slug: (row['slug'] ?? row['id']).toString(),
          kind: (row['event_kind'] ?? 'Event').toString(),
          status: (row['status'] ?? 'active').toString(),
          coverUrl: row['gallery_cover_url']?.toString(),
          date: row['event_start_at'] == null ? null : DateTime.tryParse(row['event_start_at'].toString()),
        )).toList();
  }

  @override
  Future<MmEvent> createEvent({required String title, required String kind, DateTime? date}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    final slug = '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final row = await _client.from('events').insert({
      'owner_id': user.id,
      'title': title,
      'slug': slug,
      'event_kind': kind,
      'status': 'active',
      'event_start_at': (date ?? DateTime.now()).toIso8601String(),
      'plan_code': 'beta',
      'duration_code': 'beta',
      'duration_days': 30,
      'max_guests': 50,
      'max_total_bytes': 1073741824,
      'max_photos_per_guest': 50,
      'used_total_bytes': 0,
      'beta_free_access': true,
      'paid_at': DateTime.now().toIso8601String(),
      'stripe_payment_status': 'beta_free',
    }).select().single();
    return MmEvent(id: row['id'].toString(), title: row['title'].toString(), slug: row['slug'].toString(), kind: kind, status: row['status'].toString(), date: date);
  }

  @override
  Future<List<MmMedia>> loadMedia(String eventId) async {
    final rows = await _client
        .from('media_uploads')
        .select('id,event_id,original_filename,status,caption,created_at,media_blobs(compressed_content_type,compressed_base64)')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return rows.map<MmMedia>((row) {
      String? directDataUrl;
      final blob = row['media_blobs'];
      if (blob is Map && blob['compressed_base64'] != null) {
        directDataUrl = 'data:${blob['compressed_content_type'] ?? 'image/jpeg'};base64,${blob['compressed_base64']}';
      }
      return MmMedia(
        id: row['id'].toString(),
        eventId: row['event_id'].toString(),
        filename: (row['original_filename'] ?? 'memory.jpg').toString(),
        status: (row['status'] ?? 'pending').toString(),
        caption: row['caption']?.toString(),
        url: directDataUrl ?? '${AppConfig.appUrl}/api/media/${row['id']}/file',
        createdAt: row['created_at'] == null ? null : DateTime.tryParse(row['created_at'].toString()),
      );
    }).toList();
  }

  @override
  Future<MmMedia> uploadPhoto({required String eventId, required PickedCompressedImage image, String? caption}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    // Production-safe direct database upload. The web API remains available, but direct Supabase keeps the app independent of browser cookies.
    final guest = await _ensureUploader(eventId, user);
    final upload = await _client.from('media_uploads').insert({
      'event_id': eventId,
      'guest_id': guest,
      'user_id': user.id,
      'kind': 'photo',
      'object_key': 'db-mobile-pending',
      'original_filename': image.fileName,
      'content_type': image.compressedContentType,
      'byte_size': image.compressedBytes,
      'status': 'pending',
      'caption': caption,
      'uploaded_at': DateTime.now().toIso8601String(),
    }).select().single();
    final uploadId = upload['id'].toString();
    await _client.from('media_uploads').update({'object_key': 'db-media/$uploadId'}).eq('id', uploadId);
    await _client.from('media_blobs').insert({
      'upload_id': uploadId,
      'event_id': eventId,
      'owner_id': user.id,
      'original_filename': image.fileName,
      'original_content_type': image.originalContentType,
      'original_byte_size': image.originalBytes,
      'compressed_content_type': image.compressedContentType,
      'compressed_byte_size': image.compressedBytes,
      'compressed_base64': image.compressedBase64,
      'width': image.width,
      'height': image.height,
    });
    return MmMedia(id: uploadId, eventId: eventId, filename: image.fileName, status: 'pending', caption: caption, url: '${AppConfig.appUrl}/api/media/$uploadId/file', createdAt: DateTime.now());
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
    }).select('id').single();
    return inserted['id'].toString();
  }

  @override
  Future<List<MmNotification>> loadNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from('user_notifications').select('id,title,body,status,created_at').eq('user_id', user.id).order('created_at', ascending: false).limit(50);
    return rows.map<MmNotification>((row) => MmNotification(id: row['id'].toString(), title: row['title'].toString(), body: (row['body'] ?? '').toString(), read: row['status'] == 'read', createdAt: DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now())).toList();
  }

  @override
  Future<List<SupportTicket>> loadTickets() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from('support_tickets').select('id,subject,message,status,created_at').eq('user_id', user.id).order('created_at', ascending: false).limit(50);
    return rows.map<SupportTicket>((row) => SupportTicket(id: row['id'].toString(), subject: row['subject'].toString(), message: (row['message'] ?? '').toString(), status: (row['status'] ?? 'open').toString(), createdAt: DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now())).toList();
  }

  @override
  Future<SupportTicket> createTicket({required String subject, required String message}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Please log in again.');
    final row = await _client.from('support_tickets').insert({'user_id': user.id, 'subject': subject, 'message': message, 'status': 'open'}).select().single();
    return SupportTicket(id: row['id'].toString(), subject: row['subject'].toString(), message: row['message'].toString(), status: row['status'].toString(), createdAt: DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now());
  }
}

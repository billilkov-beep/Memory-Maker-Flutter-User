import '../models/app_models.dart';
import 'image_service.dart';

abstract class MemoryMakerRepository {
  Future<bool> get isSignedIn;
  Future<MmUser?> currentUser();
  Future<MmUser> signIn(String email, String password);
  Future<void> signUp({required String email, required String password, required String name});
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
  Future<MmUser> updateProfile({required String name, String? phone, PickedCompressedImage? avatar});

  Future<List<MmEvent>> loadEvents();
  Future<MmEvent> createEvent({required String title, required String kind, DateTime? date});
  Future<List<MmMedia>> loadMedia(String eventId);
  Future<MmMedia> uploadPhoto({required String eventId, required PickedCompressedImage image, String? caption});

  Future<List<MmNotification>> loadNotifications();
  Future<List<SupportTicket>> loadTickets();
  Future<SupportTicket> createTicket({required String subject, required String message});
}

import '../services/notification_service.dart';

class NotificationController {
  Stream get stream => NotificationService.stream();

  Future<void> markSeen(String id) async {
    await NotificationService.markSeen(id);
  }

  Future<void> delete(String id) async {
    await NotificationService.delete(id);
  }
}

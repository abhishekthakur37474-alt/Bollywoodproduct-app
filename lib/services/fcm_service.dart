import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class FcmService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    print("🟡 [FCM] Initializing");

    await _fcm.requestPermission();

    final token = await _fcm.getToken();
    print("🟢 [FCM] Token: $token");

    // 🔔 FOREGROUND
    FirebaseMessaging.onMessage.listen((msg) async {
      print("🟢 [FCM] Foreground message received");
      _save(msg);
    });

    // 🔔 BACKGROUND (when app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      print("🟡 [FCM] Opened from notification");
      _save(msg);
    });
  }

  static Future<void> _save(RemoteMessage msg) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("🟢 [FCM] Saving notification to Firestore");

    await NotificationService.save(
      uid: user.uid,
      title: msg.notification?.title ?? "Notification",
      body: msg.notification?.body ?? "",
      image: msg.notification?.android?.imageUrl ??
          msg.notification?.apple?.imageUrl,
    );
  }
}

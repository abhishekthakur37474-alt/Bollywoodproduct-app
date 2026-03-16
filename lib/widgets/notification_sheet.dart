import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationSheet extends StatelessWidget {
  NotificationSheet({super.key});

  final controller = NotificationController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xff121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Notifications",
            style: TextStyle(
              color: Color(0xffD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder(
              stream: controller.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  print("🟡 [NOTIFICATION] Waiting for data...");
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  print("🔴 [NOTIFICATION] No notifications found");
                  return const Center(
                    child: Text(
                      "No notifications",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                print("🟢 [NOTIFICATION] Loaded ${docs.length} notifications");

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = AppNotification.fromMap(
                      docs[i].id,
                      docs[i].data() as Map<String, dynamic>,
                    );

                    return ListTile(
                      leading: data.image != null
                          ? CircleAvatar(
                        backgroundImage:
                        NetworkImage(data.image!),
                      )
                          : const Icon(
                        Icons.notifications,
                        color: Colors.amber,
                      ),
                      title: Text(
                        data.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        data.body,
                        style:
                        const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          print("🗑️ [NOTIFICATION] Deleting ${data.id}");
                          controller.delete(data.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

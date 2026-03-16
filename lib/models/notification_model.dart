class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? image;
  final bool seen;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    required this.seen,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      image: data['image'],
      seen: data['seen'] ?? false,
    );
  }
}

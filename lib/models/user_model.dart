class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String state;
  final String pincode;
  final String imageUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.pincode,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "phone": phone,
      "city": city,
      "state": state,
      "pincode": pincode,
      "imageUrl": imageUrl,
      "createdAt": DateTime.now(),
    };
  }
}

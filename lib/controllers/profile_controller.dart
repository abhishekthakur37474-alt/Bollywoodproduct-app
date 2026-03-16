import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class ProfileController {
  final ImagePicker _picker = ImagePicker();
  final UserService _service = UserService();

  File? selectedImage;

  Future<void> pickImage() async {
    try {
      print("🟡 [PROFILE] Picking image");

      final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        print("🔴 [PROFILE] Image picking cancelled");
        return;
      }

      selectedImage = File(picked.path);
      print("🟢 [PROFILE] Image selected: ${picked.path}");
    } catch (e) {
      print("🔴 [IMAGE PICK ERROR] $e");
    }
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String pincode,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      print("🟡 [PROFILE] Saving profile for ${user.uid}");

      String imageUrl = '';

      if (selectedImage != null) {
        imageUrl =
        await _service.uploadProfileImage(user.uid, selectedImage!);
      }

      final model = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        city: city,
        state: state,
        pincode: pincode,
        imageUrl: imageUrl,
      );

      await _service.saveUser(model);

      print("🟢 [PROFILE] Profile saved fully");
    } catch (e) {
      print("🔴 [PROFILE SAVE ERROR] $e");
    }
  }
}

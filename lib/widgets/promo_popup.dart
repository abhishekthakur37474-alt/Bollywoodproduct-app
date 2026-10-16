import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PromoPopup extends StatelessWidget {
  const PromoPopup({super.key});

  static const String _imageAsset = "assets/promo/promo.png";

  static const String _registerUrl =
      "https://www.bollywoodproduct.com/film-audition/";

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => const PromoPopup(),
    );
  }

  Future<void> _openRegister() async {
    final uri = Uri.parse(_registerUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xff141414),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xffD4AF37).withOpacity(0.6),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffD4AF37).withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: Image.asset(
                      _imageAsset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        height: size.width * 0.55,
                        color: const Color(0xff1c1c1c),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white38,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _openRegister,
                        child: const Text(
                          "Register Now",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ❌ CROSS / CLOSE BUTTON
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xff1f1f1f),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xffD4AF37).withOpacity(0.7),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Global navigator key used by [PromoPopupManager] to show the popup on top
/// of whatever screen is currently visible.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Screens that should never trigger the promo popup.
const Set<String> _excludedScreens = {
  'SplashScreen',
  'HomeLoaderScreen',
  'BottomNav',
  'LoginScreen',
};

const Set<String> _promoHiddenScreens = {
  'BollywoodQuizScreen',
  'QuizPlayScreen',
  'QuizHomeScreen',
  'QuizScoreScreen',
  'QuizLeaderboardScreen',
  'QuizProfileScreen',
  'QuizResultScreen',
  'LoginScreen',
};

/// Notifies [PromoBubbleLayer] whenever the bubble needs to be shown or
/// hidden.
final ValueNotifier<int> promoBubbleTick = ValueNotifier<int>(0);

/// Shows the promo popup once per screen per app session.
///
/// Every screen (bottom nav tabs and pushed pages) gets its own entry, so the
/// user has to close the popup on every screen. The state is stored in static
/// variables, hence it resets automatically when the app is restarted.
class PromoPopupManager {
  PromoPopupManager._();

  static const Duration _delay = Duration(seconds: 2);

  static final Set<String> _handledScreens = <String>{};
  static Timer? _timer;
  static String? _pendingKey;
  static bool _isVisible = false;
  static bool _dismissedOnce = false;
  static bool _isHiddenOnCurrentScreen = false;

  /// Key of the bottom nav tab that is currently selected.
  static String? currentTabKey;

  static bool get isPopupVisible => _isVisible;

  /// The small floating bubble is shown after the user closes the popup for
  /// the first time and stays for the rest of the app session.
  static bool get showBubble =>
      _dismissedOnce && !_isVisible && !_isHiddenOnCurrentScreen;

  static void setHiddenOnCurrentScreen(bool hidden) {
    if (_isHiddenOnCurrentScreen == hidden) return;
    _isHiddenOnCurrentScreen = hidden;

    if (hidden) {
      _timer?.cancel();
      _timer = null;
      _pendingKey = null;
    }

    promoBubbleTick.value++;
  }

  static void schedule(String screenKey) {
    if (_isVisible || _handledScreens.contains(screenKey)) return;

    if (_pendingKey == screenKey && (_timer?.isActive ?? false)) return;

    _timer?.cancel();
    _pendingKey = screenKey;

    _timer = Timer(_delay, () {
      _pendingKey = null;
      if (_isVisible || _handledScreens.contains(screenKey)) return;

      _handledScreens.add(screenKey);
      _open(context: appNavigatorKey.currentState?.overlay?.context);
    });
  }

  /// Opens the full popup immediately, used by the floating bubble.
  static void showNow() {
    if (_isVisible) return;
    _open(context: appNavigatorKey.currentState?.overlay?.context);
  }

  static void _open({BuildContext? context}) {
    if (context == null || _isVisible) return;

    _isVisible = true;
    promoBubbleTick.value++;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => const PromoPopup(),
    ).whenComplete(() {
      _isVisible = false;
      _dismissedOnce = true;
      promoBubbleTick.value++;
    });
  }

  /// Drops a pending popup when the user leaves the screen before the delay
  /// ends, so it never appears on top of a different screen.
  static void cancelIfPending(String screenKey) {
    if (_pendingKey != screenKey) return;
    _timer?.cancel();
    _timer = null;
    _pendingKey = null;
  }
}

/// Keeps the small promo bubble floating above the current screen.
///
/// Place it above the app navigator (see `MaterialApp.builder`) so it stays
/// visible on every route while the bottom nav and pushed pages change.
class PromoBubbleLayer extends StatelessWidget {
  final Widget child;

  const PromoBubbleLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: promoBubbleTick,
      builder: (context, _, __) {
        if (!PromoPopupManager.showBubble) return child;

        final media = MediaQuery.of(context);
        final bottomInset = media.viewInsets.bottom > media.viewPadding.bottom
            ? media.viewInsets.bottom
            : media.viewPadding.bottom;

        return Directionality(
          textDirection:
              Directionality.maybeOf(context) ?? TextDirection.ltr,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                right: 16,
                bottom: bottomInset + 76,
                child: const _PromoBubble(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromoBubble extends StatelessWidget {
  const _PromoBubble();

  static const String _imageAsset = "assets/promo/promo.png";

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Open promo offer",
      child: GestureDetector(
        onTap: PromoPopupManager.showNow,
        child: SizedBox(
          width: 132,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xffD4AF37),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xffD4AF37).withOpacity(0.3),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  _imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xff141414),
                    child: const Center(
                      child: Icon(
                        Icons.local_offer_outlined,
                        color: Color(0xffD4AF37),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Schedules the promo popup for every pushed page.
class PromoPopupRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _handleRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final poppedKey = _screenKey(route);
    if (poppedKey != null) PromoPopupManager.cancelIfPending(poppedKey);

    if (previousRoute == null) return;

    if (_screenKey(previousRoute) == 'BottomNav') {
      PromoPopupManager.setHiddenOnCurrentScreen(false);
      final tabKey = PromoPopupManager.currentTabKey;
      if (tabKey != null) PromoPopupManager.schedule(tabKey);
      return;
    }

    _handleRoute(previousRoute);
  }

  void _handleRoute(Route<dynamic> route) {
    final screenKey = _screenKey(route);
    if (screenKey == null) return;
    final hidePromo = _promoHiddenScreens.contains(screenKey);
    PromoPopupManager.setHiddenOnCurrentScreen(hidePromo);
    if (hidePromo) return;
    if (_excludedScreens.contains(screenKey)) return;

    PromoPopupManager.schedule(screenKey);
  }

  String? _screenKey(Route<dynamic> route) {
    if (route is! PageRoute<dynamic>) return null;

    final context = appNavigatorKey.currentState?.overlay?.context;
    if (context == null) return null;

    if (route is MaterialPageRoute<dynamic>) {
      final Widget page = route.builder(context);
      return page.runtimeType.toString();
    }

    return route.settings.name ?? route.runtimeType.toString();
  }
}

class PromoPopup extends StatelessWidget {
  const PromoPopup({super.key});

  static const String _imageAsset = "assets/promo/promo.png";

  static const String _registerUrl =
      "https://www.bollywoodproduct.com/film-audition/";

  static const String _resultUrl =
      "https://www.bollywoodproduct.com/film-audition/results.php";

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
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
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _openUrl(_registerUrl),
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
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffD4AF37),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Color(0xffD4AF37),
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _openUrl(_resultUrl),
                            child: const Text(
                              "View Result",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
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

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] (e.g. a Bloc's state stream) to a [Listenable] so
/// `GoRouter.refreshListenable` re-evaluates redirects on every emission.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the latest list of [ConnectivityResult] whenever the network changes.
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// `true` when at least one non-none connectivity result is present.
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    // Optimistic: assume online until we know otherwise.
    loading: () => true,
    error: (_, _) => true,
  );
});

/// Utility class for one-off connectivity checks (outside Riverpod context).
class ConnectivityManager {
  ConnectivityManager._();
  static final ConnectivityManager instance = ConnectivityManager._();

  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

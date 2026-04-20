import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  // Check if online (real internet reachability)
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) return false;
    // Verify actual internet with a fast HEAD request:
    try {
      final resp = await http.head(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 4));
      return resp.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
  
  // Listen to connectivity changes (real internet reachability)
  Stream<bool> get onConnectivityChanged async* {
    await for (final results in _connectivity.onConnectivityChanged) {
      if (results.contains(ConnectivityResult.none)) {
        yield false;
      } else {
        // Check actual internet access
        yield await isOnline();
      }
    }
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  // Check if online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    // In connectivity_plus 6.0+, checkConnectivity returns List<ConnectivityResult>
    return !result.contains(ConnectivityResult.none);
  }
  
  // Listen to connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none)
    );
  }
}

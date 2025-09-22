import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker {

  static bool updateConnectionStatus(List<ConnectivityResult> connectionStatus) {
    if (connectionStatus.contains(ConnectivityResult.mobile) || connectionStatus.contains(ConnectivityResult.wifi)) {
      return true;
    } else {return false;}
  }
}

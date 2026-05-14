import '../utils/network_utils.dart';

class NetworkService {
  /// Resolves the current local IPv4 address of the device.
  Future<String?> getLocalIpAddress() => NetworkUtils.getLocalIpAddress();
}

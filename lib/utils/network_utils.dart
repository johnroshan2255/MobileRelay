import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkUtils {
  NetworkUtils._();

  /// Returns the device's WiFi/Hotspot IP address.
  /// Uses network_info_plus for reliable WiFi detection, with fallback to
  /// dart:io NetworkInterface scanning if needed.
  static Future<String?> getLocalIpAddress() async {
    // STRATEGY 1: Try network_info_plus first (most reliable for WiFi/Hotspot)
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != '0.0.0.0') {
        // Validate it's a proper IP
        if (_isValidIp(wifiIP)) {
          return wifiIP;
        }
      }
    } catch (_) {
      // Plugin failed, fall through to manual detection
    }

    // STRATEGY 2: Fallback to NetworkInterface scanning
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Collect all non-loopback addresses with interface names
      final candidates = <MapEntry<String, String>>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            candidates.add(MapEntry(iface.name, addr.address));
          }
        }
      }

      // Priority 1: Prefer WiFi-related interfaces (wlan, ap, etc.)
      for (final entry in candidates) {
        final name = entry.key.toLowerCase();
        if (name.contains('wlan') || 
            name.contains('ap') || 
            name.contains('wifi')) {
          return entry.value;
        }
      }

      // Priority 2: Prefer private LAN ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
      // These are typically used for WiFi/hotspot networks
      for (final entry in candidates) {
        if (_isPrivateIp(entry.value)) {
          return entry.value;
        }
      }

      // Priority 3: Last resort - return any available IP
      if (candidates.isNotEmpty) {
        return candidates.first.value;
      }
    } catch (_) {}
    
    return null;
  }

  static bool _isValidIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final num = int.tryParse(part);
      return num != null && num >= 0 && num <= 255;
    });
  }

  static bool _isPrivateIp(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return false;
    final a = parts[0]!, b = parts[1]!;
    return (a == 10) ||
        (a == 192 && b == 168) ||
        (a == 172 && b >= 16 && b <= 31);
  }
}

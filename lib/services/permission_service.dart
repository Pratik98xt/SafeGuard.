import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool _isRequesting = false;

  /// Requests all necessary application permissions sequentially.
  /// Never executes concurrently to avoid platform channel collisions.
  static Future<void> requestAppPermissions() async {
    if (_isRequesting) return;
    _isRequesting = true;
    try {
      final permissions = [
        Permission.location,
        Permission.sms,
        Permission.phone,
        Permission.camera,
        Permission.microphone,
        Permission.notification,
      ];

      for (final permission in permissions) {
        try {
          final status = await permission.status;
          if (!status.isGranted && !status.isPermanentlyDenied) {
            await permission.request();
          }
        } catch (e) {
          debugPrint('Error requesting permission $permission: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in requestAppPermissions: $e');
    } finally {
      _isRequesting = false;
    }
  }
}


import 'dart:io';
import 'package:archive/archive_io.dart';

class LocalApkScanner {
  // ── Known dangerous permissions ─────────────────────────────────────────
  static const _dangerousPerms = {
    'READ_SMS', 'RECEIVE_SMS', 'SEND_SMS',
    'READ_CALL_LOG', 'PROCESS_OUTGOING_CALLS',
    'READ_CONTACTS', 'WRITE_CONTACTS',
    'ACCESS_FINE_LOCATION', 'ACCESS_BACKGROUND_LOCATION',
    'CAMERA', 'RECORD_AUDIO',
    'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
    'SYSTEM_ALERT_WINDOW', 'BIND_ACCESSIBILITY_SERVICE',
    'REQUEST_INSTALL_PACKAGES', 'RECEIVE_BOOT_COMPLETED',
    'FOREGROUND_SERVICE', 'BIND_DEVICE_ADMIN',
    'CHANGE_NETWORK_STATE', 'CHANGE_WIFI_STATE',
    'BLUETOOTH_ADMIN', 'USE_BIOMETRIC',
    'GET_ACCOUNTS', 'USE_CREDENTIALS',
    'READ_PHONE_STATE', 'CALL_PHONE',
  };

  static const _suspiciousExtensions = {
    '.sh', '.py', '.js', '.pl', '.rb', '.elf', '.bin',
    '.cmd', '.bat', '.ps1', '.vbs',
  };

  /// Unzips and parses basic APK structure and manifest fully offline.
  static Future<Map<String, dynamic>> parseApk(String apkPath) async {
    final file = File(apkPath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final allFiles = archive.files.where((f) => f.isFile).toList();
    final dexFiles = allFiles.where((f) => f.name.endsWith('.dex')).toList();
    final soFiles = allFiles.where((f) => f.name.endsWith('.so')).map((f) => f.name).toList();
    final suspiciousFiles = allFiles
        .where((f) => _suspiciousExtensions.any((ext) => f.name.endsWith(ext)))
        .map((f) => f.name)
        .toList();

    final permissions = <String>{};
    String packageName = 'Unknown';

    final manifestEntry = archive.findFile('AndroidManifest.xml');
    if (manifestEntry != null && manifestEntry.isFile) {
      final manifestBytes = manifestEntry.content as List<int>;
      final extracted = _extractStringsFromBinaryXml(manifestBytes);
      for (final s in extracted) {
        if (s.startsWith('android.permission.') || s.startsWith('com.android.')) {
          permissions.add(s.toUpperCase().replaceAll('ANDROID.PERMISSION.', '').trim());
        }
        if (s.contains('.') && s.length > 5 && s.length < 80 &&
            !s.contains(' ') && packageName == 'Unknown' &&
            RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(s)) {
          packageName = s;
        }
      }
    }

    final certFiles = allFiles
        .where((f) => f.name.startsWith('META-INF/'))
        .map((f) => f.name)
        .toList();
    final hasDebugCert = certFiles.any((f) => f.toLowerCase().contains('debug'));
    final isV2Signed = archive.findFile('META-INF/MANIFEST.MF') != null;
    final dangerousFound = permissions.where((p) => _dangerousPerms.contains(p)).toList();
    final hasMultipleDex = dexFiles.length > 2;
    final hasOverlayRisk = permissions.contains('SYSTEM_ALERT_WINDOW') &&
        permissions.contains('BIND_ACCESSIBILITY_SERVICE');
    final hasSpywareCombo = permissions.contains('READ_SMS') &&
        permissions.contains('READ_CONTACTS') &&
        permissions.contains('ACCESS_FINE_LOCATION');
    final fileSizeMb = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

    return {
      'fileName': apkPath.split(Platform.pathSeparator).last,
      'fileSizeMb': fileSizeMb,
      'packageName': packageName,
      'totalFiles': allFiles.length,
      'dexCount': dexFiles.length,
      'dexFiles': dexFiles.map((f) => f.name).toList(),
      'nativeLibraries': soFiles,
      'suspiciousEmbeddedFiles': suspiciousFiles,
      'assetFileCount': allFiles.where((f) => f.name.startsWith('assets/')).length,
      'permissions': permissions.toList(),
      'dangerousPermissions': dangerousFound,
      'signingCertFiles': certFiles,
      'hasDebugCertificate': hasDebugCert,
      'isV2Signed': isV2Signed,
      'heuristicFlags': {
        'multipleDexFiles': hasMultipleDex,
        'hasNativeLibraries': soFiles.isNotEmpty,
        'suspiciousEmbeddedFiles': suspiciousFiles.isNotEmpty,
        'overlayAttackRisk': hasOverlayRisk,
        'spywarePermissionCombo': hasSpywareCombo,
      },
    };
  }

  /// Helper to extract printable ASCII string sequences from AndroidManifest.xml binary format
  static List<String> _extractStringsFromBinaryXml(List<int> bytes) {
    final results = <String>[];
    final sb = StringBuffer();
    for (final b in bytes) {
      if (b >= 32 && b < 127) {
        sb.write(String.fromCharCode(b));
      } else {
        final s = sb.toString().trim();
        if (s.length > 5) results.add(s);
        sb.clear();
      }
    }
    return results;
  }

  /// Analyzes APK metadata using local heuristic threat scoring (Fully offline, no AI)
  static Map<String, dynamic> scanMetadata(Map<String, dynamic> meta) {
    int score = 0;
    final riskFlags = <Map<String, String>>[];
    final suspiciousPermissions = <String>[];
    final positiveIndicators = <String>[];

    final dangerousFound = List<String>.from(meta['dangerousPermissions'] ?? []);
    
    // Track categories of permissions for combination scoring
    bool hasAccessibility = dangerousFound.contains('BIND_ACCESSIBILITY_SERVICE');
    bool hasOverlay = dangerousFound.contains('SYSTEM_ALERT_WINDOW');
    bool hasDeviceAdmin = dangerousFound.contains('BIND_DEVICE_ADMIN');
    bool hasSms = dangerousFound.any((p) => p.contains('SMS'));
    bool hasContacts = dangerousFound.contains('READ_CONTACTS');
    bool hasLocation = dangerousFound.contains('ACCESS_FINE_LOCATION') || dangerousFound.contains('ACCESS_COARSE_LOCATION');
    bool hasPhoneState = dangerousFound.contains('READ_PHONE_STATE');

    // 1. Evaluate high-privilege permissions individually (if not in a combo)
    if (hasAccessibility) {
      suspiciousPermissions.add('BIND_ACCESSIBILITY_SERVICE');
      if (!hasOverlay) { // If combined, we score it under combos
        score += 15;
        riskFlags.add({
          'flag': 'Accessibility Service Permission',
          'detail': 'Requests Accessibility services, which can interact with other apps. Standard for assistance tools, but high risk if unexpected.',
          'severity': 'medium',
        });
      }
    }
    if (hasOverlay) {
      suspiciousPermissions.add('SYSTEM_ALERT_WINDOW');
      if (!hasAccessibility) {
        score += 10;
        riskFlags.add({
          'flag': 'Overlay Window Permission',
          'detail': 'Requests permission to draw over other apps (frequently used for custom UI or alert panels).',
          'severity': 'medium',
        });
      }
    }
    if (hasDeviceAdmin) {
      suspiciousPermissions.add('BIND_DEVICE_ADMIN');
      score += 15;
      riskFlags.add({
        'flag': 'Device Administrator Access',
        'detail': 'App requests full device administrator privileges, granting control over lockscreens or storage wipe capabilities.',
        'severity': 'high',
      });
    }

    // 2. Evaluate dangerous combos (Highly indicators of Trojans and Spyware)
    final rawFlags = meta['heuristicFlags'];
    final Map<String, dynamic> hFlags = rawFlags is Map
        ? Map<String, dynamic>.from(rawFlags)
        : <String, dynamic>{};
    
    if (hasAccessibility && hasOverlay) {
      score += 45;
      suspiciousPermissions.addAll(['BIND_ACCESSIBILITY_SERVICE', 'SYSTEM_ALERT_WINDOW']);
      riskFlags.add({
        'flag': 'Critical Combo: Overlay + Accessibility',
        'detail': 'Combination of Overlay window and Accessibility services is highly characteristic of financial screen-tapping trojans.',
        'severity': 'critical',
      });
    }

    if (hasSms && hasContacts && hasLocation) {
      score += 40;
      suspiciousPermissions.addAll(['READ_SMS', 'READ_CONTACTS', 'ACCESS_FINE_LOCATION']);
      riskFlags.add({
        'flag': 'Critical Combo: Spyware Package',
        'detail': 'Requests SMS access, Contacts reading, and GPS location tracking simultaneously. Classic spyware data-gathering behavior.',
        'severity': 'critical',
      });
    } else {
      // Score single sensitive permissions lightly if not in a dangerous combination
      if (hasSms) {
        suspiciousPermissions.add('READ_SMS');
        score += 8;
        riskFlags.add({
          'flag': 'SMS Access',
          'detail': 'Allows reading or sending SMS messages (common intercept threat for OTP theft).',
          'severity': 'high',
        });
      }
      if (hasPhoneState) {
        suspiciousPermissions.add('READ_PHONE_STATE');
        score += 5;
        riskFlags.add({
          'flag': 'Phone Identity Access',
          'detail': 'Reads device ID and phone numbers.',
          'severity': 'medium',
        });
      }
    }

    // Standard user-granted permissions (like CAMERA, Location on their own) should NOT inflate the risk score
    // to prevent flagging every utility app as dangerous. We just log them if sensitive.
    for (final perm in dangerousFound) {
      if (!['BIND_ACCESSIBILITY_SERVICE', 'SYSTEM_ALERT_WINDOW', 'BIND_DEVICE_ADMIN', 'READ_SMS', 'RECEIVE_SMS', 'SEND_SMS', 'READ_PHONE_STATE'].contains(perm)) {
        // We log it as a flagged permission in UI but add 0-2 risk points max
        suspiciousPermissions.add(perm);
        if (['RECORD_AUDIO', 'CAMERA'].contains(perm)) {
          score += 2; // Negligible score addition for camera/mic
        }
      }
    }

    // Heuristics flags checks
    if (hFlags['multipleDexFiles'] == true) {
      score += 8;
      riskFlags.add({
        'flag': 'Multiple DEX Files',
        'detail': 'Contains multiple executable DEX files, indicating code compartmentalization or obfuscated library components.',
        'severity': 'low',
      });
    }
    
    if (hFlags['suspiciousEmbeddedFiles'] == true) {
      score += 20;
      riskFlags.add({
        'flag': 'Executable Embedded Scripts',
        'detail': 'Contains raw executable binary or scripting assets (.sh, .bin, .py) hidden inside the app folder structure.',
        'severity': 'high',
      });
    }

    // 3. Certificate checks
    if (meta['hasDebugCertificate'] == true) {
      score += 30;
      riskFlags.add({
        'flag': 'Debug Sign Signature',
        'detail': 'Signed with a non-production development certificate. Usually means it did not come from an official store.',
        'severity': 'high',
      });
    } else {
      positiveIndicators.add('Signed with a release certificate');
    }

    if (meta['isV2Signed'] == false) {
      score += 10;
      riskFlags.add({
        'flag': 'Outdated V1 Signature Only',
        'detail': 'Does not use Android V2 signature schemes, making it more vulnerable to custom resource modification.',
        'severity': 'low',
      });
    } else {
      positiveIndicators.add('Uses secure V2 APK Signature scheme');
    }

    // Limit score to 100
    if (score > 100) score = 100;

    String verdict = 'Clean';
    String category = 'Clean';
    bool isMalicious = false;

    if (score >= 60) {
      verdict = 'Malicious';
      category = 'Trojan/Spyware';
      isMalicious = true;
    } else if (score >= 35) {
      verdict = 'Dangerous';
      category = 'Potentially Unwanted App (PUA)';
      isMalicious = true;
    } else if (score >= 20) {
      verdict = 'Suspicious';
      category = 'Riskware';
      isMalicious = false;
    }

    if (positiveIndicators.isEmpty) {
      positiveIndicators.add('Standard APK file structure');
    }

    String recommendation = 'No action required.';
    if (score >= 60) {
      recommendation = 'This app exhibits multiple high-risk characteristics. Review its permissions carefully and check recent news in the App Auditor before continuing to use it.';
    } else if (score >= 35) {
      recommendation = 'Do not grant accessibility or overlay permissions to this application.';
    } else if (score >= 20) {
      recommendation = 'Monitor the behavior of this app and review its permissions in settings.';
    }

    return {
      'score': score,
      'verdict': verdict,
      'ismalicious': isMalicious,
      'explanation': 'Offline Scan: Threat rating of $score% based on structural properties and permission combination analysis.',
      'threatCategory': category,
      'riskFlags': riskFlags,
      'suspiciousPermissions': suspiciousPermissions,
      'positiveIndicators': positiveIndicators,
      'recommendation': recommendation,
    };
  }
}

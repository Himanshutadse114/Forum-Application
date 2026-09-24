import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Service that communicates with the APKiD Python backend server.
///
/// APKiD detects: compilers, packers, obfuscators, anti-VM/anti-tamper tricks.
/// This provides a much deeper analysis than permission heuristics alone.
class ApkidService {
  // ── Server Configuration ─────────────────────────────────────────────────

  /// Server URL for APKiD backend.
  /// - Live VPS: http://vps.innvikta.com:5005
  /// - Real device (local testing): http://192.168.0.38:5005
  /// - Android Emulator: http://10.0.2.2:5005
  static const String _defaultServerUrl = 'http://vps.innvikta.com:5005';

  static String _serverUrl = _defaultServerUrl;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 300),
    sendTimeout: const Duration(seconds: 300),
  ));

  static String get serverUrl => _serverUrl;

  /// Override the server URL (e.g. when user sets their PC IP in settings)
  static void setServerUrl(String url) {
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // ── API Methods ───────────────────────────────────────────────────────────

  /// Checks if the APKiD backend server is reachable and APKiD is installed.
  ///
  /// Returns [true] if server is available, [false] otherwise.
  static Future<bool> checkServerHealth() async {
    try {
      final response = await _dio.get(
        '$_serverUrl/health',
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 4),
          connectTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == 'ok' && data['apkid_available'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[APKiD] Server health check failed: $e');
      return false;
    }
  }

  /// Scans an APK file by uploading it to the APKiD backend server.
  ///
  /// [apkPath] - absolute path to the APK file on device.
  ///
  /// Returns a structured map with findings, or `null` if server is unavailable.
  ///
  /// Result shape:
  /// ```dart
  /// {
  ///   'compilers': [ {'file': '...', 'value': 'r8'} ],
  ///   'packers': [ {'file': '...', 'value': 'dexguard'} ],
  ///   'obfuscators': [ ... ],
  ///   'anti_features': [ ... ],
  ///   'risk_score': 0-100,
  ///   'risk_label': 'CLEAN' | 'SUSPICIOUS' | 'HIGH RISK',
  ///   'is_packed': bool,
  ///   'is_obfuscated': bool,
  ///   'has_anti_analysis': bool,
  ///   'summary': 'Human readable summary',
  /// }
  /// ```
  static Future<Map<String, dynamic>?> scanApk(String apkPath) async {
    final file = File(apkPath);
    if (!await file.exists()) {
      debugPrint('[APKiD] File not found: $apkPath');
      return null;
    }

    try {
      debugPrint('[APKiD] Uploading APK for fingerprinting: $apkPath');

      final fileName = apkPath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(apkPath, filename: fileName),
      });

      final response = await _dio.post(
        '$_serverUrl/scan',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 300),
          sendTimeout: const Duration(seconds: 300),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('[APKiD] Scan complete. Risk: ${data['risk_label']}');
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is String) {
          final decoded = json.decode(data);
          return Map<String, dynamic>.from(decoded as Map);
        }
        return null;
      } else {
        debugPrint('[APKiD] Server error ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('[APKiD] Dio error: ${e.type} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[APKiD] Scan failed: $e');
      return null;
    }
  }

  /// Runs a detailed audit using MobSF on the live VPS.
  ///
  /// [apkPath] - absolute path to the APK file on device.
  ///
  /// Returns a simplified vulnerability report with security score, grade, trackers, and secrets.
  static Future<Map<String, dynamic>?> scanApkDetailed(String apkPath) async {
    final file = File(apkPath);
    if (!await file.exists()) {
      debugPrint('[APKiD] Detailed scan file not found: $apkPath');
      return null;
    }

    try {
      debugPrint('[APKiD] Uploading APK for detailed audit: $apkPath');

      final fileName = apkPath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(apkPath, filename: fileName),
      });

      final response = await _dio.post(
        '$_serverUrl/scan/detailed',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 300),
          sendTimeout: const Duration(seconds: 300),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is String) {
          final decoded = json.decode(data);
          return Map<String, dynamic>.from(decoded as Map);
        }
        return null;
      } else {
        debugPrint('[APKiD] Detailed scan server error ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('[APKiD] Detailed scan Dio error: ${e.type} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[APKiD] Detailed scan failed: $e');
      return null;
    }
  }

  // ── Result Parsing Helpers ────────────────────────────────────────────────

  /// Returns a user-friendly label for the compiler(s) detected.
  static String getCompilerSummary(Map<String, dynamic> result) {
    final compilers = result['compilers'] as List<dynamic>? ?? [];
    if (compilers.isEmpty) return 'Unknown';
    final names = compilers.map((c) => (c as Map)['value'] as String).toSet().toList();
    return names.join(', ');
  }

  /// Returns the risk label.
  static String getRiskLabel(Map<String, dynamic> result) {
    return result['risk_label'] as String? ?? 'UNKNOWN';
  }

  /// Returns [true] if APKiD found any red flags (packer/obfuscator/anti).
  static bool hasAnyFindings(Map<String, dynamic> result) {
    return (result['is_packed'] == true) ||
        (result['is_obfuscated'] == true) ||
        (result['has_anti_analysis'] == true);
  }

  /// Formats the APKiD risk score as a contribution to the overall scan score.
  static int extraRiskScore(Map<String, dynamic>? apkidResult) {
    if (apkidResult == null) return 0;
    final score = (apkidResult['risk_score'] as num?)?.toInt() ?? 0;
    return (score * 0.30).round().clamp(0, 30);
  }
}

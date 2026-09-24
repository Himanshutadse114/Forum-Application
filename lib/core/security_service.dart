import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';
import 'dart:io';

class SecurityService {
  static bool _isCompromised = false;
  static String _compromiseReason = '';

  static bool get isCompromised => _isCompromised;
  static String get compromiseReason => _compromiseReason;

  static Future<void> init() async {
    if (kDebugMode) {
      debugPrint('freeRASP security checks bypassed in debug mode.');
      return;
    }
    // 1. Define the threat callback behavior
    final callback = ThreatCallback(
      onAppIntegrity: () => _handleThreat('App Integrity Violation (Repackaging/Tampering detected)'),
      onDebug: () => _handleThreat('Debugger Attached'),
      onDeviceBinding: () => _handleThreat('Device Binding Violation'),
      onDeviceID: () => _handleThreat('Device ID Mismatch'),
      onHooks: () => _handleThreat('Hooking Framework Detected (e.g. Frida)'),
      onPasscode: () => _handleThreat('Passcode Not Set on Device'),
      onPrivilegedAccess: () => _handleThreat('Privileged Access Detected (Rooted/Jailbroken device)'),
      onSecureHardwareNotAvailable: () => _handleThreat('Secure Hardware Not Available'),
      onSimulator: () => _handleThreat('App running on Simulator/Emulator'),
      onUnofficialStore: () => _handleThreat('App installed from Unofficial Store'),
    );

    // 2. Attach the threat listener before starting freeRASP
    Talsec.instance.attachListener(callback);

    // 3. Define the configuration for freeRASP
    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.example.sneakers_app',
        signingCertHashes: [
          'qiU6sXcR4q8zD1LrAQ1FG5fYcSmL8cvYeWGShK1+zxs='
        ],
        supportedStores: ['com.android.vending'],
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.cybershield.forum'],
        teamId: 'CYBERSHIELD123',
      ),
      watcherMail: 'security-alerts@cybershield.org',
      isProd: false, // Set to true in release builds
    );

    try {
      // 4. Start Talsec security monitoring
      await Talsec.instance.start(config);
      debugPrint('freeRASP security protection started successfully.');
    } catch (e) {
      debugPrint('Failed to start freeRASP: $e');
    }
  }

  static void _handleThreat(String reason) {
    _isCompromised = true;
    _compromiseReason = reason;
    debugPrint('SECURITY WARNING: $reason');
    
    // In a high-security app, you might want to terminate the application:
    // exit(0);
  }

  /// Helper widget builder to wrap screens with a security warning if compromised.
  static Widget securityWrapper(Widget child) {
    if (kDebugMode) return child;
    if (_isCompromised) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security_update_warning_rounded, color: Colors.redAccent, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'SECURITY BLOCK',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This application cannot run under the current device environment.\nReason: $_compromiseReason',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => exit(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Exit Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return child;
  }
}

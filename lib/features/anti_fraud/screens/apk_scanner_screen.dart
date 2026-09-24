import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/anti_fraud/services/gemini_service.dart';

class ApkScannerScreen extends StatefulWidget {
  final int initialTab;
  const ApkScannerScreen({super.key, this.initialTab = 0});
  @override
  State<ApkScannerScreen> createState() => _ApkScannerScreenState();
}

class _ApkScannerScreenState extends State<ApkScannerScreen>
    with TickerProviderStateMixin {

  final GeminiService _geminiService = GeminiService();

  // Current active tab index
  int _currentTab = 0;


  // Audit state
  bool _isLoading = false;
  String _loadingStep = '';
  String? _error;
  Map<String, dynamic>? _result;
  String? _scannedAppName;
  String? _scannedPackageName;

  // Background Cache state
  final Map<String, Map<String, dynamic>> _scanResults = {};
  final Map<String, Uint8List?> _appIcons = {};
  bool _isAutoScanning = false;

  // Installed apps state
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  bool _loadingApps = false;
  bool _showSystemApps = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _appSearchInputController = TextEditingController();

  late final AnimationController _pulseController;
  late final AnimationController _rotationController;
  late final AnimationController _resultController;
  late final Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    final cached = HiveBoxHelper.getScanResults();
    bool isLegacy = cached.values.any((val) => val.containsKey('score') || val.containsKey('meta'));
    if (isLegacy) {
      HiveBoxHelper.saveScanResults({});
    } else {
      _scanResults.addAll(cached);
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(parent: _resultController, curve: Curves.easeOut);

    _loadInstalledApps();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _resultController.dispose();
    _searchController.dispose();
    _appSearchInputController.dispose();
    super.dispose();
  }

  // ── Installed Apps Loading ───────────────────────────────────────────────

  Future<void> _loadInstalledApps() async {
    setState(() => _loadingApps = true);
    try {
      final apps = await InstalledApps.getInstalledApps(
        !_showSystemApps,
        false, // Fetch list instantly without loading heavy icons upfront
        '',
        BuiltWith.native_or_others,
      );
      apps.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) {
        setState(() {
          _installedApps = apps;
          _filteredApps = apps;
          _loadingApps = false;
        });
        _sortApps();
        _scanAllApps();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingApps = false);
    }
  }

  String _riskLevel(bool isAudited) {
    return isAudited ? 'AUDITED' : 'UNAUDITED';
  }

  Color _riskColor(bool isAudited) {
    return isAudited ? CyberTheme.primary : CyberTheme.textMuted;
  }

  void _sortApps() {
    if (!mounted) return;
    setState(() {
      _filteredApps.sort((a, b) {
        final resA = _scanResults[a.packageName];
        final resB = _scanResults[b.packageName];

        final isAuditedA = resA != null && resA['isOffline'] != true;
        final isAuditedB = resB != null && resB['isOffline'] != true;

        if (isAuditedA != isAuditedB) {
          return isAuditedA ? -1 : 1; // Audited first
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    });
  }

  Future<void> _scanAllApps() async {
    if (_isAutoScanning) return;
    setState(() => _isAutoScanning = true);

    final appsToScan = List<AppInfo>.from(_installedApps);

    for (final app in appsToScan) {
      if (!mounted) break;
      final pkgName = app.packageName;
      if (_scanResults.containsKey(pkgName)) continue;

      // Fast Offline Heuristics for System/Reputable Apps:
      final isSystem = pkgName.startsWith('com.google.') ||
          pkgName.startsWith('com.android.') ||
          pkgName.startsWith('com.sec.') ||
          pkgName.startsWith('com.samsung.') ||
          pkgName.startsWith('com.xiaomi.') ||
          pkgName.startsWith('com.huawei.') ||
          pkgName.startsWith('com.oppo.') ||
          pkgName.startsWith('com.vivo.');

      final isReputable = pkgName.startsWith('com.whatsapp') ||
          pkgName.startsWith('com.instagram.') ||
          pkgName.startsWith('com.facebook.') ||
          pkgName.startsWith('com.spotify.') ||
          pkgName.startsWith('org.mozilla.') ||
          pkgName.startsWith('com.snapchat.') ||
          pkgName.startsWith('com.netflix.') ||
          pkgName.startsWith('com.amazon.') ||
          pkgName.startsWith('com.adobe.');

      if (isSystem || isReputable) {
        _scanResults[pkgName] = {
          'isOffline': true,
          'explanation': isSystem ? 'Official system application. Fully trusted vendor.' : 'Popular and verified standard application.',
          'newsAndCautions': [
            {
              'title': isSystem ? 'System Core Component' : 'Reputable App Profile',
              'date': 'Recent',
              'description': isSystem ? 'This is an official system component pre-installed on the device.' : 'This is a widely verified application from a known official developer.',
              'isCaution': false
            }
          ],
          'privacyCautions': [
            isSystem ? 'System level permissions granted' : 'Standard app privacy policy applies'
          ],
          'recommendation': 'Keep the application updated through official channels.',
        };
      } else {
        // Mark as Unaudited third-party app
        _scanResults[pkgName] = {
          'isOffline': true,
          'explanation': 'This third-party application has not been audited yet. Tap to run a reputation and security breach check.',
          'newsAndCautions': [],
          'privacyCautions': [
            'Reputation and breach history are currently unchecked'
          ],
          'recommendation': 'Run a breach audit to retrieve recent news and security cautions.',
        };
      }
    }

    if (mounted) {
      setState(() {
        _isAutoScanning = false;
      });
      HiveBoxHelper.saveScanResults(_scanResults);
      _sortApps();
    }
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = _installedApps.where((app) {
        final lq = query.toLowerCase();
        return app.name.toLowerCase().contains(lq) ||
            app.packageName.toLowerCase().contains(lq);
      }).toList();
    });
    _sortApps();
  }

  // ── App Audit Execution ──────────────────────────────────────────────────

  Future<void> _auditApp(String appName, {String? packageName}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _loadingStep = 'Searching breach history & safety news for $appName…';
      _scannedAppName = appName;
      _scannedPackageName = packageName;
    });
    _resultController.reset();

    try {
      final auditData = await _geminiService.auditAppReputation(appName, packageName: packageName);
      try {
        await HiveBoxHelper.incrementScanCount('app');
      } catch (_) {}
      if (!mounted) return;

      setState(() {
        _result = auditData;
        _isLoading = false;
        _loadingStep = '';
      });
      _resultController.forward();

      if (packageName != null) {
        setState(() {
          _scanResults[packageName] = auditData;
        });
        HiveBoxHelper.saveScanResults(_scanResults);
        _sortApps();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Reputation audit failed: $e';
          _isLoading = false;
          _loadingStep = '';
        });
      }
    }
  }



  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5E7EB).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Auditor', Icons.apps_rounded),
          _buildTabItem(1, 'Search', Icons.search_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
          if (index == 0 && _installedApps.isEmpty) {
            _loadInstalledApps();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? CyberTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : CyberTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : CyberTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _result = null;
      _error = null;
      _scannedAppName = null;
      _scannedPackageName = null;
    });
    _resultController.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return Scaffold(
        backgroundColor: CyberTheme.background,
        appBar: AppBar(
          backgroundColor: CyberTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: CyberTheme.textPrimary,
            onPressed: _resetScan,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Audit Report',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18, color: CyberTheme.textPrimary),
              ),
              if (_scannedAppName != null)
                Text(_scannedAppName!,
                  style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: FadeTransition(opacity: _resultFade, child: _buildResults()),
          ),
        ),
      );
    }

    String screenTitle = 'App Reputation Search';
    if (_currentTab == 0) {
      screenTitle = 'Installed App Auditor';
    } else if (_currentTab == 2) {
      screenTitle = 'Device & Fraud News';
    }

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        backgroundColor: CyberTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: CyberTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          screenTitle,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 20, color: CyberTheme.textPrimary),
        ),
      ),
      body: _isLoading
          ? _buildLoadingOverlay()
          : SafeArea(
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: _currentTab == 0
                        ? _buildInstalledAppsTab()
                        : _buildSearchTab(),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Loading Overlay ──────────────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotationController]),
            builder: (context, _) => SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _RadarPainter(
                      animationValue: _pulseController.value,
                      rotationValue: _rotationController.value,
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: CyberTheme.primary.withOpacity(0.15), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: CyberTheme.primary.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: CyberTheme.primary,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Auditing App Security…',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: CyberTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _loadingStep,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CyberTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Installed Apps Tab ───────────────────────────────────────────────────

  Widget _buildInstalledAppsTab() {
    final displayApps = _filteredApps;

    return Column(
      children: [
        // Search + filter bar
        Container(
          color: CyberTheme.background,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEFEDED)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFE5E7EB).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterApps,
                    style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      hintText: 'Search apps…',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: CyberTheme.textMuted, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // System apps toggle
              GestureDetector(
                onTap: () {
                  setState(() => _showSystemApps = !_showSystemApps);
                  _loadInstalledApps();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showSystemApps ? CyberTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showSystemApps ? CyberTheme.primary : const Color(0xFFEFEDED),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 18,
                    color: _showSystemApps ? Colors.white : CyberTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // App count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                '${displayApps.length} apps ${_showSystemApps ? '(incl. system)' : '(user only)'}',
                style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
              ),
              const Spacer(),
              if (_loadingApps)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: CyberTheme.primary),
                ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildErrorBanner(),
          ),
        // App list
        Expanded(
          child: _loadingApps
              ? const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
              : displayApps.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No apps found',
                          style: GoogleFonts.inter(fontSize: 14, color: CyberTheme.textMuted, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: displayApps.length,
                      itemBuilder: (context, index) => _buildAppTile(displayApps[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildAppTile(AppInfo app) {
    final pkgName = app.packageName;
    final scanResult = _scanResults[pkgName];

    final isAudited = scanResult != null && scanResult['isOffline'] != true;
    final risk = _riskLevel(isAudited);
    final color = _riskColor(isAudited);

    final trailingWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        risk,
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          fontSize: 9,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE5E7EB).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: _appIcons.containsKey(pkgName)
            ? (_appIcons[pkgName] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _appIcons[pkgName]!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.android_rounded, color: CyberTheme.textMuted, size: 44),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CyberTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.android_rounded, color: CyberTheme.primary),
                  ))
            : FutureBuilder<AppInfo?>(
                future: InstalledApps.getAppInfo(pkgName, BuiltWith.native_or_others),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final iconBytes = snapshot.data?.icon;
                    _appIcons[pkgName] = iconBytes;
                    if (iconBytes != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          iconBytes,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.android_rounded, color: CyberTheme.textMuted, size: 44),
                        ),
                      );
                    }
                  }
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CyberTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.android_rounded, color: CyberTheme.primary),
                  );
                },
              ),
        title: Text(
          app.name,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: CyberTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.packageName,
              style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            Text(
              'v${app.versionName}',
              style: GoogleFonts.inter(fontSize: 10, color: CyberTheme.textMuted),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            trailingWidget,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: CyberTheme.textMuted, size: 18),
          ],
        ),
        onTap: () {
          if (scanResult != null && scanResult['isOffline'] != true) {
            setState(() {
              _result = scanResult;
              _scannedAppName = app.name;
              _scannedPackageName = pkgName;
            });
            _resultController.forward();
          } else {
            _auditApp(app.name, packageName: pkgName);
          }
        },
      ),
    );
  }

  // ── Search Tab ───────────────────────────────────────────────────────────

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFEDED)),
              boxShadow: [
                BoxShadow(
                  color: CyberTheme.primary.withOpacity(0.04),
                  blurRadius: 16, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Audit Any Application',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: CyberTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type the name of any app (e.g. TikTok, Signal, Adobe Reader) to check its breach history, reputation, and security record.',
                  style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted, height: 1.45),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _appSearchInputController,
                  style: GoogleFonts.inter(fontSize: 14, color: CyberTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter app name...',
                    hintStyle: GoogleFonts.inter(color: CyberTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: CyberTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final appName = _appSearchInputController.text.trim();
                    if (appName.isNotEmpty) {
                      _auditApp(appName);
                    } else {
                      setState(() {
                        _error = 'Please enter an app name to search.';
                      });
                    }
                  },
                  icon: const Icon(Icons.gavel_rounded, color: Colors.white),
                  label: Text('Audit Reputation', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 12), _buildErrorBanner()],
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CyberTheme.danger.withOpacity(0.07), CyberTheme.primary.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CyberTheme.danger.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: CyberTheme.danger.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.bug_report_outlined, color: CyberTheme.danger, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reputation & Breach Checker',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: CyberTheme.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Checks the global web for recent data leaks, privacy breaches, and vulnerability advisory alerts.',
                  style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CyberTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberTheme.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: CyberTheme.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.danger))),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: CyberTheme.danger),
            onPressed: () => setState(() => _error = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Audit Results Redesign ───────────────────────────────────────────────

  Widget _buildResults() {
    final r = _result!;
    final explanation = r['explanation']?.toString() ?? '';
    final recommendation = r['recommendation']?.toString() ?? '';

    // Get Privacy Cautions
    final privacyCautions = (r['privacyCautions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    // Get News & Cautions
    final newsAndCautions = (r['newsAndCautions'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Advisory Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFEDED)),
            boxShadow: [BoxShadow(color: const Color(0xFFE5E7EB).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CyberTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: CyberTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Advisory Summary',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 15, color: CyberTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                explanation,
                style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),

        // Metadata details
        if (_scannedPackageName != null) ...[
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.info_outline_rounded,
            title: 'Application Identity',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Name', _scannedAppName ?? 'Unknown'),
                _infoRow('Package ID', _scannedPackageName!),
              ],
            ),
          ),
        ],

        // Privacy Cautions Section
        if (privacyCautions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.lock_person_outlined,
            title: 'Privacy Cautions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: privacyCautions.map((caution) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: CyberTheme.warning, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          caution,
                          style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Timeline of Incidents & News
        const SizedBox(height: 16),
        _buildSection(
          icon: Icons.article_outlined,
          title: 'Latest News & Cautions Timeline',
          child: newsAndCautions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: CyberTheme.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No recent news or security cautions registered for this app.',
                          style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: newsAndCautions.map((item) {
                    final isCaution = item['isCaution'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCaution ? const Color(0xFFFFF8F2) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCaution ? CyberTheme.primary.withOpacity(0.15) : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCaution ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                            color: isCaution ? CyberTheme.primary : CyberTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title']?.toString() ?? '',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: CyberTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['date']?.toString() ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: CyberTheme.textMuted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['description']?.toString() ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: CyberTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        // Recommendation
        if (recommendation.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CyberTheme.secondary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEDED)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: CyberTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 13, color: CyberTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation,
                        style: GoogleFonts.inter(fontSize: 13, color: CyberTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: _resetScan,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text('Audit Another App', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: CyberTheme.primary,
            side: const BorderSide(color: CyberTheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEDED)),
        boxShadow: [BoxShadow(color: const Color(0xFFE5E7EB).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Icon(icon, color: CyberTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: CyberTheme.textPrimary)),
            ]),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: CyberTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double animationValue;
  final double rotationValue;

  _RadarPainter({required this.animationValue, required this.rotationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 1; i <= 3; i++) {
      final rippleValue = (animationValue + i / 3.0) % 1.0;
      paint.color = CyberTheme.primary.withOpacity(0.35 * (1.0 - rippleValue));
      canvas.drawCircle(center, maxRadius * rippleValue, paint);
    }

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          CyberTheme.primary.withOpacity(0.0),
          CyberTheme.primary.withOpacity(0.25),
        ],
        stops: const [0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue * 2 * 3.14159265);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, maxRadius, sweepPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rotationValue != rotationValue;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cybershield_forum/core/theme.dart';

class MobsfReportScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  final String appName;

  const MobsfReportScreen({
    super.key,
    required this.report,
    required this.appName,
  });

  @override
  State<MobsfReportScreen> createState() => _MobsfReportScreenState();
}

class _MobsfReportScreenState extends State<MobsfReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return CyberTheme.success;
      case 'B':
        return const Color(0xFF4CAF50);
      case 'C':
        return CyberTheme.warning;
      case 'D':
        return const Color(0xFFFF6F00);
      case 'F':
        return CyberTheme.danger;
      default:
        return CyberTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final score = (report['security_score'] as num?)?.toInt() ?? 100;
    final grade = report['security_grade']?.toString() ?? 'A';
    final trackers = (report['trackers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final secrets = List<String>.from(report['secrets'] ?? []);
    final vulns = report['vulnerabilities'] as Map<String, dynamic>? ?? {};
    
    final highVulns = (vulns['high'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final mediumVulns = (vulns['medium'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final lowVulns = (vulns['low'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

    final gradeColor = _getGradeColor(grade);

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
          'Detailed Audit Report',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 18, color: CyberTheme.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEDED)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5E7EB).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Grade Badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gradeColor.withOpacity(0.08),
                      border: Border.all(color: gradeColor.withOpacity(0.3), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      grade,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CyberTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report['filename']?.toString() ?? 'unknown_app.apk',
                          style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: score / 100,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFEEEEEE),
                                  valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$score/100',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: CyberTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEF2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                labelColor: CyberTheme.primary,
                unselectedLabelColor: CyberTheme.textMuted,
                labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: 'VULNERABILITIES'),
                  Tab(text: 'TRACKERS'),
                  Tab(text: 'SECRETS'),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Vulnerabilities
                  _buildVulnsTab(highVulns, mediumVulns, lowVulns),
                  // Tab 2: Trackers
                  _buildTrackersTab(trackers),
                  // Tab 3: Secrets
                  _buildSecretsTab(secrets),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVulnsTab(
    List<Map<String, dynamic>> high,
    List<Map<String, dynamic>> medium,
    List<Map<String, dynamic>> low,
  ) {
    if (high.isEmpty && medium.isEmpty && low.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 48, color: CyberTheme.success),
            const SizedBox(height: 12),
            Text(
              'No Vulnerabilities Found',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: CyberTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'The application is exceptionally secure.',
              style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (high.isNotEmpty) ...[
          _buildSeverityHeader('HIGH SEVERITY ISSUES', CyberTheme.danger, high.length),
          ...high.map((item) => _buildVulnTile(item, CyberTheme.danger)),
          const SizedBox(height: 16),
        ],
        if (medium.isNotEmpty) ...[
          _buildSeverityHeader('WARNINGS & INFO', CyberTheme.warning, medium.length),
          ...medium.map((item) => _buildVulnTile(item, CyberTheme.warning)),
          const SizedBox(height: 16),
        ],
        if (low.isNotEmpty) ...[
          _buildSeverityHeader('MINOR COMPLIANCE ISSUES', CyberTheme.textMuted, low.length),
          ...low.map((item) => _buildVulnTile(item, Colors.blue.shade700)),
        ],
      ],
    );
  }

  Widget _buildSeverityHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: CyberTheme.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVulnTile(Map<String, dynamic> item, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEDED)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: CyberTheme.textMuted,
          collapsedIconColor: CyberTheme.textMuted,
          title: Text(
            item['title']?.toString() ?? 'Security Risk',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: CyberTheme.textPrimary,
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              color == CyberTheme.danger
                  ? Icons.gpp_bad_rounded
                  : color == CyberTheme.warning
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
              color: color,
              size: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    item['description']?.toString() ?? 'No detail available.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CyberTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackersTab(List<Map<String, dynamic>> trackers) {
    if (trackers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nature_people_rounded, size: 48, color: CyberTheme.success),
            const SizedBox(height: 12),
            Text(
              'No Trackers Detected',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: CyberTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'The application does not include known advertising tracker SDKs.',
              style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: trackers.length,
      itemBuilder: (context, index) {
        final t = trackers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEDED)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.analytics_outlined, color: Colors.blue.shade700, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['name']?.toString() ?? 'Unknown Tracker',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 14, color: CyberTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t['categories']?.toString() ?? 'Analytics / Ads',
                      style: GoogleFonts.inter(fontSize: 11, color: CyberTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecretsTab(List<String> secrets) {
    if (secrets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vpn_key_off_rounded, size: 48, color: CyberTheme.success),
            const SizedBox(height: 12),
            Text(
              'No Hardcoded Keys Detected',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: CyberTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'No plain-text credentials, tokens, or private secrets were found.',
              style: GoogleFonts.inter(fontSize: 12, color: CyberTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: secrets.length,
      itemBuilder: (context, index) {
        final sec = secrets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEDED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.key_rounded, color: CyberTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Secret Token/Key Found',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: CyberTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CyberTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  sec,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 12,
                    color: CyberTheme.danger,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

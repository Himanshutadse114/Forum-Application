import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/api_client.dart';

class ThreatReport {
  final int id;
  final int? userId;
  final String title;
  final String description;
  final String scamType;
  final String? evidenceUrl;
  final String status;
  final String reporterName;
  final DateTime createdAt;

  ThreatReport({
    required this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.scamType,
    this.evidenceUrl,
    required this.status,
    required this.reporterName,
    required this.createdAt,
  });

  factory ThreatReport.fromJson(Map<String, dynamic> json) => ThreatReport(
    id: int.parse(json['id'].toString()),
    userId: json['user_id'] != null ? int.parse(json['user_id'].toString()) : null,
    title: json['title'].toString(),
    description: json['description'].toString(),
    scamType: json['scam_type'].toString(),
    evidenceUrl: json['evidence_url']?.toString(),
    status: json['status'].toString(),
    reporterName: json['reporter_name']?.toString() ?? 'Anonymous Sentinel',
    createdAt: DateTime.parse(json['created_at'].toString()),
  );
}

class ScamAnalysisResult {
  final int score;
  final String threatLevel;
  final String confidence;
  final List<String> indicators;
  final List<String> recommendations;
  final String analyzerName;

  ScamAnalysisResult({
    required this.score,
    required this.threatLevel,
    required this.confidence,
    required this.indicators,
    required this.recommendations,
    required this.analyzerName,
  });

  factory ScamAnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ScamAnalysisResult(
      score: int.parse(data['scam_likelihood_score'].toString()),
      threatLevel: data['threat_level'].toString(),
      confidence: data['confidence'].toString(),
      indicators: List<String>.from(data['indicators_found'] ?? []),
      recommendations: List<String>.from(data['recommendations'] ?? []),
      analyzerName: json['analyzer'].toString(),
    );
  }
}

// 1. Threat Feed Provider
final threatFeedProvider = FutureProvider<List<ThreatReport>>((ref) async {
  final client = ApiClient();
  final response = await client.dio.get('/reports/list.php');
  if (response.data['status'] == 'success') {
    final list = response.data['data'] as List;
    return list.map((e) => ThreatReport.fromJson(e)).toList();
  }
  throw Exception(response.data['message'] ?? 'Failed to load threats');
});

// 2. Scam Analysis & Creation Notifier
class ThreatNotifier extends StateNotifier<bool> {
  final ApiClient _client = ApiClient();

  ThreatNotifier() : super(false);

  Future<bool> submitReport({
    required String title,
    required String description,
    required String scamType,
    String? evidenceUrl,
  }) async {
    state = true;
    try {
      final response = await _client.dio.post('/reports/create.php', data: {
        'title': title,
        'description': description,
        'scam_type': scamType,
        'evidence_url': evidenceUrl,
      });
      state = false;
      return response.data['status'] == 'success';
    } catch (_) {
      state = false;
      return false;
    }
  }

  Future<ScamAnalysisResult?> analyzeScamContent(String content) async {
    state = true;
    try {
      final response = await _client.dio.post('/reports/analyze.php', data: {
        'content': content,
      });
      state = false;
      if (response.data['status'] == 'success') {
        return ScamAnalysisResult.fromJson(response.data);
      }
      return null;
    } catch (_) {
      state = false;
      return null;
    }
  }
}

final threatOpsProvider = StateNotifierProvider<ThreatNotifier, bool>((ref) {
  return ThreatNotifier();
});

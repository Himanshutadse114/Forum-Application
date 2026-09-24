import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxHelper {
  static const String authBoxName = 'cybershield_auth';
  
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String emailKey = 'email';
  static const String avatarKey = 'avatar';
  static const String roleKey = 'role';
  static const String repKey = 'reputation';
  static const String rankKey = 'rank';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(authBoxName);
  }

  static Box get _box => Hive.box(authBoxName);

  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String username,
    required String email,
    required String avatar,
    required String role,
    required int reputation,
    required String rank,
  }) async {
    await _box.put(tokenKey, token);
    await _box.put(userIdKey, userId);
    await _box.put(usernameKey, username);
    await _box.put(emailKey, email);
    await _box.put(avatarKey, avatar);
    await _box.put(roleKey, role);
    await _box.put(repKey, reputation);
    await _box.put(rankKey, rank);
  }

  static String? getToken() => _box.get(tokenKey) as String?;
  static int? getUserId() => _box.get(userIdKey) as int?;
  static String? getUsername() => _box.get(usernameKey) as String?;
  static String? getEmail() => _box.get(emailKey) as String?;
  static String? getAvatar() => _box.get(avatarKey) as String?;
  static String? getRole() => _box.get(roleKey) as String?;
  static int? getReputation() => _box.get(repKey) as int?;
  static String? getRank() => _box.get(rankKey) as String?;

  static Future<void> updateRepAndRank(int reputation, String rank) async {
    await _box.put(repKey, reputation);
    await _box.put(rankKey, rank);
  }

  static Future<void> updateUsername(String username) async {
    await _box.put(usernameKey, username);
  }

  static Future<void> updateAvatar(String avatar) async {
    await _box.put(avatarKey, avatar);
  }

  static Future<void> clear() async {
    await _box.clear();
  }

  static List<int> getSavedPostIds() {
    final list = _box.get('saved_post_ids');
    if (list is List) {
      return List<int>.from(list);
    }
    return [];
  }

  static Future<void> toggleSavedPostId(int id) async {
    final current = getSavedPostIds();
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await _box.put('saved_post_ids', current);
  }

  static Future<void> saveGameScore(int userId, String gameId, int score) async {
    final key = 'game_score_${userId}_$gameId';
    final currentHigh = getGameScore(userId, gameId);
    if (score > currentHigh) {
      await _box.put(key, score);
    }
    // Also log all individual score entries as history in database
    final historyKey = 'game_history_${userId}_$gameId';
    final List<dynamic> history = _box.get(historyKey, defaultValue: []) as List<dynamic>;
    final List<int> intHistory = List<int>.from(history);
    intHistory.add(score);
    await _box.put(historyKey, intHistory);
  }

  static int getGameScore(int userId, String gameId) {
    final key = 'game_score_${userId}_$gameId';
    return _box.get(key, defaultValue: 0) as int;
  }

  static List<int> getGameHistory(int userId, String gameId) {
    final historyKey = 'game_history_${userId}_$gameId';
    final List<dynamic> history = _box.get(historyKey, defaultValue: []) as List<dynamic>;
    return List<int>.from(history);
  }

  static Map<String, Map<String, dynamic>> getScanResults() {
    final Map? data = _box.get('scan_results') as Map?;
    if (data != null) {
      final results = <String, Map<String, dynamic>>{};
      data.forEach((key, value) {
        if (key is String && value is Map) {
          results[key] = Map<String, dynamic>.from(value);
        }
      });
      return results;
    }
    return {};
  }

  static Future<void> saveScanResults(Map<String, Map<String, dynamic>> results) async {
    await _box.put('scan_results', results);
  }

  static List<Map<String, dynamic>> getSecurityForumPosts() {
    final list = _box.get('security_forum_posts');
    if (list is List && list.isNotEmpty) {
      final parsed = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      // Auto-migrate old default IDs (< 999999) to new IDs (> 999999) to enable local likes/comments
      if (parsed.any((p) => int.tryParse(p['id'].toString()) == 999901)) {
        // Fall through to re-seed correct IDs
      } else {
        return parsed;
      }
    }
    
    final defaultPosts = [
      {
        'id': 9999991,
        'user_id': 1,
        'category_id': 9999,
        'title': 'Critical Warning: Android Banking Malware "GoldPickaxe" Active',
        'content': 'A new Android Trojan named "GoldPickaxe" is actively targeting financial applications. It harvests biometric data, identity documents, and intercepts SMS verification codes. Keep Google Play Protect enabled and never install applications from unverified links.',
        'is_anonymous': 0,
        'likes_count': 12,
        'comments_count': 0,
        'author_name': 'cybershield_admin',
        'author_avatar': 'admin.png',
        'author_rank': 'Cyber Security Commander',
        'category_name': 'Security Advisories & Fraud Alerts',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 9999992,
        'user_id': 1,
        'category_id': 9999,
        'title': 'Alert: Zero-Day Vulnerability in WebRTC Protocols',
        'content': 'A critical zero-day vulnerability (CVE-2026-1182) has been patched in WebRTC, allowing for remote code execution. Please ensure Chrome and other Android WebViews are updated immediately to version 125.0.0 or higher.',
        'is_anonymous': 0,
        'likes_count': 8,
        'comments_count': 0,
        'author_name': 'cybershield_admin',
        'author_avatar': 'admin.png',
        'author_rank': 'Cyber Security Commander',
        'category_name': 'Security Advisories & Fraud Alerts',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];
    _box.put('security_forum_posts', defaultPosts);
    return defaultPosts;
  }

  static Future<void> addSecurityForumPost(Map<String, dynamic> postJson) async {
    final list = getSecurityForumPosts();
    if (list.any((p) => p['title'] == postJson['title'])) return;
    list.add(postJson);
    await _box.put('security_forum_posts', list);
  }

  static Future<void> saveSecurityForumPosts(List<Map<String, dynamic>> posts) async {
    await _box.put('security_forum_posts', posts);
  }

  static List<Map<String, dynamic>> getSecurityForumComments(int postId) {
    final list = _box.get('security_forum_comments_$postId');
    if (list is List) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<void> addSecurityForumComment(int postId, Map<String, dynamic> commentJson) async {
    final list = getSecurityForumComments(postId);
    list.add(commentJson);
    await _box.put('security_forum_comments_$postId', list);
    await incrementCommentCount(postId);
  }

  static Future<void> incrementCommentCount(int postId) async {
    final list = getSecurityForumPosts();
    final idx = list.indexWhere((p) => int.tryParse(p['id'].toString()) == postId);
    if (idx != -1) {
      final currentCount = int.tryParse(list[idx]['comments_count'].toString()) ?? 0;
      list[idx]['comments_count'] = currentCount + 1;
      await _box.put('security_forum_posts', list);
    }
  }

  static int getSecurityForumAutoPostTime() {
    return _box.get('security_forum_auto_post_time', defaultValue: 0) as int;
  }

  static Future<void> saveSecurityForumAutoPostTime(int val) async {
    await _box.put('security_forum_auto_post_time', val);
  }

  static int getScanCount(String type) {
    return _box.get('scan_count_$type', defaultValue: 0) as int;
  }

  static Future<void> incrementScanCount(String type) async {
    final current = getScanCount(type);
    await _box.put('scan_count_$type', current + 1);
  }

  static Map<String, dynamic>? getLatestBriefing() {
    final data = _box.get('latest_briefing');
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> saveLatestBriefing(Map<String, dynamic> briefing) async {
    await _box.put('latest_briefing', briefing);
  }

  static bool isLoggedIn() => getToken() != null;
}

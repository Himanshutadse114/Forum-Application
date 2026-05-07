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

  static bool isLoggedIn() => getToken() != null;
}

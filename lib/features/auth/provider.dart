import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/api_client.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:dio/dio.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final Map<String, dynamic>? userProfile;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.userProfile,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    Map<String, dynamic>? userProfile,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();

  AuthNotifier() : super(AuthState(isAuthenticated: HiveBoxHelper.isLoggedIn())) {
    if (state.isAuthenticated) {
      _loadCachedUser();
    }
  }

  void _loadCachedUser() {
    state = AuthState(
      isAuthenticated: true,
      userProfile: {
        'id': HiveBoxHelper.getUserId(),
        'username': HiveBoxHelper.getUsername(),
        'email': HiveBoxHelper.getEmail(),
        'avatar': HiveBoxHelper.getAvatar(),
        'role': HiveBoxHelper.getRole(),
        'reputation_points': HiveBoxHelper.getReputation(),
        'rank': HiveBoxHelper.getRank(),
      },
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/auth/login.php', data: {
        'username': username,
        'password': password,
      });

      if (response.data['status'] == 'success') {
        final token = response.data['token'];
        final user = response.data['user'];

        await HiveBoxHelper.saveAuthData(
          token: token,
          userId: int.parse(user['id'].toString()),
          username: user['username'].toString(),
          email: user['email'].toString(),
          avatar: user['avatar'].toString(),
          role: user['role'].toString(),
          reputation: int.parse(user['reputation_points'].toString()),
          rank: user['rank'].toString(),
        );

        state = AuthState(
          isAuthenticated: true,
          userProfile: Map<String, dynamic>.from(user),
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      String msg = 'Network connection failed.';
      if (e is DioException) {
        msg = (e.response?.data is Map) ? (e.response?.data['message'] ?? e.message) : (e.message ?? e.toString());
      } else {
        msg = e.toString();
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/auth/register.php', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response.data['status'] == 'success') {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      String msg = 'Registration failed.';
      if (e is DioException) {
        msg = (e.response?.data is Map) ? (e.response?.data['message'] ?? e.message) : (e.message ?? e.toString());
      } else {
        msg = e.toString();
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> fetchProfile() async {
    if (!HiveBoxHelper.isLoggedIn()) return;
    try {
      final response = await _apiClient.dio.get('/auth/profile.php');
      if (response.data['status'] == 'success') {
        final user = response.data['data'];
        await HiveBoxHelper.updateRepAndRank(
          int.parse(user['reputation_points'].toString()),
          user['rank'].toString(),
        );
        state = state.copyWith(userProfile: Map<String, dynamic>.from(user));
      }
    } catch (_) {}
  }

  Future<bool> addReputationPoints(int points) async {
    if (!HiveBoxHelper.isLoggedIn()) return false;
    try {
      // Try PUT first (update reputation on profile endpoint)
      final response = await _apiClient.dio.post('/auth/update_reputation.php', data: {
        'reputation_points': points,
        'action': 'add',
      });
      if (response.data['status'] == 'success') {
        await fetchProfile();
        return true;
      }
      // Fallback: try PUT on profile.php
      final response2 = await _apiClient.dio.put('/auth/profile.php', data: {
        'reputation_points': points,
      });
      if (response2.data['status'] == 'success') {
        await fetchProfile();
        return true;
      }
    } catch (_) {
      // Last resort: try POST to profile.php
      try {
        final response3 = await _apiClient.dio.post('/auth/profile.php', data: {
          'reputation_points': points,
          'action': 'add_reputation',
        });
        if (response3.data['status'] == 'success') {
          await fetchProfile();
          return true;
        }
      } catch (_) {}
    }
    // Even if API call fails, update local reputation so UI reflects score
    final currentRep = HiveBoxHelper.getReputation() ?? 0;
    await HiveBoxHelper.updateRepAndRank(currentRep + points, HiveBoxHelper.getRank() ?? 'Recruit');
    _loadCachedUser();
    return true; // Return true so user gets feedback that XP was recorded locally
  }

  Future<bool> updateProfile(String username, String avatar) async {
    if (!HiveBoxHelper.isLoggedIn()) return false;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.dio.put('/auth/profile.php', data: {
        'username': username,
        'avatar': avatar,
      });
      if (response.data['status'] == 'success') {
        // Sync complete if server succeeded
      }
    } catch (_) {}

    await HiveBoxHelper.updateUsername(username);
    await HiveBoxHelper.updateAvatar(avatar);
    _loadCachedUser();
    return true;
  }

  Future<void> logout() async {
    await HiveBoxHelper.clear();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

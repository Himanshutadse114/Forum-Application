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
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];

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
        
        final localRep = HiveBoxHelper.getReputation() ?? 0;
        final serverRep = int.tryParse(user['reputation_points'].toString()) ?? 0;
        
        if (serverRep > localRep) {
          // Server has a higher score (e.g., loaded from another source), update local
          await HiveBoxHelper.updateRepAndRank(
            serverRep,
            user['rank'].toString(),
          );
          state = state.copyWith(userProfile: Map<String, dynamic>.from(user));
        } else if (localRep > serverRep) {
          // Local has a higher score! Preserve the local score, and auto-sync the difference to the server
          final diff = localRep - serverRep;
          try {
            await _apiClient.dio.post('/auth/update_reputation.php', data: {
              'reputation_points': diff,
              'action': 'add',
            });
          } catch (_) {
            try {
              await _apiClient.dio.put('/auth/profile.php', data: {
                'reputation_points': diff,
              });
            } catch (_) {}
          }
          
          final updatedUser = Map<String, dynamic>.from(user);
          updatedUser['reputation_points'] = localRep;
          updatedUser['rank'] = HiveBoxHelper.getRank() ?? user['rank'].toString();
          state = state.copyWith(userProfile: updatedUser);
        } else {
          // Already perfectly in sync
          state = state.copyWith(userProfile: Map<String, dynamic>.from(user));
        }
      }
    } catch (_) {}
  }

  Future<bool> addReputationPoints(int points) async {
    if (!HiveBoxHelper.isLoggedIn()) return false;
    
    // 1. Instantly update local reputation points and rank inside Hive so it NEVER resets
    final currentRep = HiveBoxHelper.getReputation() ?? 0;
    final newRep = currentRep + points;
    String newRank = HiveBoxHelper.getRank() ?? 'Recruit';
    if (newRep >= 1000) {
      newRank = 'Cyber Commander';
    } else if (newRep >= 500) {
      newRank = 'Security Expert';
    } else if (newRep >= 250) {
      newRank = 'Security Analyst';
    }
    await HiveBoxHelper.updateRepAndRank(newRep, newRank);
    _loadCachedUser();

    // 2. Fire-and-forget network updates
    try {
      final response = await _apiClient.dio.post('/auth/update_reputation.php', data: {
        'reputation_points': points,
        'action': 'add',
      });
      if (response.data['status'] == 'success') {
        await fetchProfile();
        return true;
      }
      final response2 = await _apiClient.dio.put('/auth/profile.php', data: {
        'reputation_points': points,
      });
      if (response2.data['status'] == 'success') {
        await fetchProfile();
        return true;
      }
    } catch (_) {
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
    return true;
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

  Future<bool> submitGameScore(String gameId, int score) async {
    if (!state.isAuthenticated) return false;
    final userId = HiveBoxHelper.getUserId() ?? 999;
    await HiveBoxHelper.saveGameScore(userId, gameId, score);
    
    // 1. Instantly update local cache
    final currentRep = HiveBoxHelper.getReputation() ?? 0;
    final newRep = currentRep + score;
    String newRank = HiveBoxHelper.getRank() ?? 'Recruit';
    if (newRep >= 1000) {
      newRank = 'Cyber Commander';
    } else if (newRep >= 500) {
      newRank = 'Security Expert';
    } else if (newRep >= 250) {
      newRank = 'Security Analyst';
    }
    await HiveBoxHelper.updateRepAndRank(newRep, newRank);
    _loadCachedUser();

    // 2. Update backend database
    try {
      final response = await _apiClient.dio.post('/users/submit_score.php', data: {
        'user_id': userId,
        'game_id': gameId,
        'score': score,
      });
      
      print('Score Submission Response: ${response.data}');
      
      if (response.data['status'] == 'success') {
        await fetchProfile();
        return true;
      } else {
        print('Server returned error: ${response.data['message']}');
        return false;
      }
    } catch (e) {
      print('Error submitting score to server: $e');
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

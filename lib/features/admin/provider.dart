import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/api_client.dart';

class AdminState {
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> admins;
  final List<dynamic> allUsers;
  final List<dynamic> myAssignedUsers;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? userDetail;

  AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.admins = const [],
    this.allUsers = const [],
    this.myAssignedUsers = const [],
    this.analytics,
    this.userDetail,
  });

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? admins,
    List<dynamic>? allUsers,
    List<dynamic>? myAssignedUsers,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? userDetail,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      admins: admins ?? this.admins,
      allUsers: allUsers ?? this.allUsers,
      myAssignedUsers: myAssignedUsers ?? this.myAssignedUsers,
      analytics: analytics ?? this.analytics,
      userDetail: userDetail ?? this.userDetail,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiClient _apiClient = ApiClient();

  AdminNotifier() : super(AdminState());

  Future<void> fetchSuperAdminData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.get('/super_admin/list_all.php');
      if (response.data['status'] == 'success') {
        state = state.copyWith(
          isLoading: false,
          admins: response.data['data']['admins'],
          allUsers: response.data['data']['users'],
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> assignUserToAdmin(int userId, int adminId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/super_admin/assign_user.php', data: {
        'user_id': userId,
        'admin_id': adminId,
      });
      if (response.data['status'] == 'success') {
        // Refresh the lists
        await fetchSuperAdminData();
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> createAdmin(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/super_admin/create_admin.php', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      if (response.data['status'] == 'success') {
        await fetchSuperAdminData();
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> makeUserAdmin(int userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/super_admin/make_admin.php', data: {
        'user_id': userId,
      });
      if (response.data['status'] == 'success') {
        await fetchSuperAdminData();
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> removeAdmin(int userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/super_admin/remove_admin.php', data: {
        'user_id': userId,
      });
      if (response.data['status'] == 'success') {
        await fetchSuperAdminData();
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> fetchAdminAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.get('/admin/users_analytics.php');
      if (response.data['status'] == 'success') {
        state = state.copyWith(
          isLoading: false,
          analytics: response.data['data'],
          myAssignedUsers: response.data['data']['assigned_users_list'] ?? [],
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchUserDetail(int userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, userDetail: null);
    try {
      final response = await _apiClient.dio.get('/admin/user_detail.php?user_id=$userId');
      if (response.data['status'] == 'success') {
        state = state.copyWith(
          isLoading: false,
          userDetail: response.data['data'],
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: response.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});

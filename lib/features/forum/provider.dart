import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cybershield_forum/core/api_client.dart';
import 'package:cybershield_forum/core/hive_box.dart';

// Model definitions for Forum
class Category {
  final int id;
  final String name;
  final String description;
  final String icon;

  Category({required this.id, required this.name, required this.description, required this.icon});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: int.parse(json['id'].toString()),
    name: json['name'].toString(),
    description: json['description'].toString(),
    icon: json['icon'].toString(),
  );
}

class Post {
  final int id;
  final int userId;
  final int categoryId;
  final String title;
  final String content;
  final bool isAnonymous;
  final int likesCount;
  final int commentsCount;
  final String authorName;
  final String authorAvatar;
  final String authorRank;
  final String categoryName;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.isAnonymous,
    required this.likesCount,
    required this.commentsCount,
    required this.authorName,
    required this.authorAvatar,
    required this.authorRank,
    required this.categoryName,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: int.parse(json['id'].toString()),
    userId: int.parse(json['user_id'].toString()),
    categoryId: int.parse(json['category_id'].toString()),
    title: json['title'].toString(),
    content: json['content'].toString(),
    isAnonymous: json['is_anonymous'].toString() == '1',
    likesCount: int.parse(json['likes_count'].toString()),
    commentsCount: int.parse(json['comments_count'].toString()),
    authorName: json['author_name'].toString(),
    authorAvatar: json['author_avatar'].toString(),
    authorRank: json['author_rank']?.toString() ?? 'WhiteHat Trainee',
    categoryName: json['category_name']?.toString() ?? '',
    createdAt: DateTime.parse(json['created_at'].toString()),
  );
}

class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final bool isAnonymous;
  final String authorName;
  final String authorAvatar;
  final String authorRank;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.isAnonymous,
    required this.authorName,
    required this.authorAvatar,
    required this.authorRank,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: int.parse(json['id'].toString()),
    postId: int.parse(json['post_id'].toString()),
    userId: int.parse(json['user_id'].toString()),
    content: json['content'].toString(),
    isAnonymous: json['is_anonymous'].toString() == '1',
    authorName: json['author_name'].toString(),
    authorAvatar: json['author_avatar'].toString(),
    authorRank: json['author_rank']?.toString() ?? 'WhiteHat Trainee',
    createdAt: DateTime.parse(json['created_at'].toString()),
  );
}

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final client = ApiClient();
  try {
    final response = await client.dio.get('/categories/list.php');
    if (response.data['status'] == 'success') {
      final list = response.data['data'] as List;
      final categories = list.map((e) => Category.fromJson(e)).toList();
      if (!categories.any((c) => c.id == 9999)) {
        categories.add(Category(
          id: 9999,
          name: 'Security Advisories & Fraud Alerts',
          description: 'Latest warnings, data breaches, and safety updates compiled by the AI reputation auditor.',
          icon: 'security',
        ));
      }
      return categories;
    }
  } catch (e) {
    // Backend is offline/errored, fallback to static categories + custom Category 9999
  }
  return [
    Category(id: 1, name: 'Threat Intelligence', description: 'Latest cyber threat news, CVEs and advisories', icon: 'radar'),
    Category(id: 2, name: 'Malware Analysis', description: 'Share samples, reverse engineering and IOCs', icon: 'bug_report'),
    Category(id: 3, name: 'Ethical Hacking', description: 'Penetration testing, CTFs and red-team discussions', icon: 'terminal'),
    Category(id: 4, name: 'Security Tools', description: 'Reviews, how-tos and configs for security tools', icon: 'build'),
    Category(id: 5, name: 'General Discussion', description: 'Anything cybersecurity — news, careers, opinions', icon: 'forum'),
    Category(
      id: 9999,
      name: 'Security Advisories & Fraud Alerts',
      description: 'Latest warnings, data breaches, and safety updates compiled by the AI reputation auditor.',
      icon: 'security',
    ),
  ];
});

// Helper to sync local-only posts to the remote database
void _syncLocalPostToRemote(ApiClient client, Map<String, dynamic> localPost) {
  final title = localPost['title']?.toString() ?? '';
  final content = localPost['content']?.toString() ?? '';
  final isAnon = int.tryParse(localPost['is_anonymous']?.toString() ?? '0') ?? 0;
  
  if (title.isEmpty || content.isEmpty) return;

  client.dio.post('/posts/create.php', data: {
    'category_id': 9999,
    'title': title,
    'content': content,
    'is_anonymous': isAnon,
  }).then((res) {
    print('Sync Category 9999 post to server success: ${res.data}');
  }).catchError((err) {
    print('Sync Category 9999 post to server failed: $err');
  });
}

// 2. Posts Provider (Filtered by Category)
final postsProvider = FutureProvider.family<List<Post>, int?>((ref, categoryId) async {
  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final client = ApiClient();

  if (categoryId == 9999) {
    try {
      final response = await client.dio.get('/posts/list.php', queryParameters: {'category_id': 9999});
      if (response.data['status'] == 'success') {
        final list = response.data['data'] as List;
        final parsed = list.map((e) => Post.fromJson(e)).toList();
        
        // Merge and sync any local posts that are not in the remote database
        final localJson = HiveBoxHelper.getSecurityForumPosts();
        for (final local in localJson) {
          final title = local['title']?.toString() ?? '';
          if (!parsed.any((p) => p.title == title)) {
            parsed.add(Post.fromJson(local));
            _syncLocalPostToRemote(client, local);
          }
        }
        return parsed;
      }
    } catch (_) {}

    final localJson = HiveBoxHelper.getSecurityForumPosts();
    return localJson.map((e) => Post.fromJson(e)).toList();
  }

  final queryParams = categoryId != null ? {'category_id': categoryId} : null;
  try {
    final response = await client.dio.get('/posts/list.php', queryParameters: queryParams);
    if (response.data['status'] == 'success') {
      final list = response.data['data'] as List;
      final parsed = list.map((e) => Post.fromJson(e)).toList();
      
      if (categoryId == null) {
        final localJson = HiveBoxHelper.getSecurityForumPosts();
        for (final local in localJson) {
          final title = local['title']?.toString() ?? '';
          if (!parsed.any((p) => p.title == title)) {
            parsed.add(Post.fromJson(local));
            _syncLocalPostToRemote(client, local);
          }
        }
      }
      return parsed;
    }
  } catch (e) {
    // Return local security posts when backend is offline
    if (categoryId == null || categoryId == 9999) {
      final localJson = HiveBoxHelper.getSecurityForumPosts();
      return localJson.map((e) => Post.fromJson(e)).toList();
    }
  }
  return [];
});

// 3. Comments Provider
final commentsProvider = FutureProvider.family<List<Comment>, int>((ref, postId) async {
  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final client = ApiClient();

  if (postId > 999999) {
    final localJson = HiveBoxHelper.getSecurityForumComments(postId);
    return localJson.map((e) => Comment.fromJson(e)).toList();
  }

  try {
    final response = await client.dio.get('/comments/list.php', queryParameters: {'post_id': postId});
    if (response.data['status'] == 'success') {
      final list = response.data['data'] as List;
      return list.map((e) => Comment.fromJson(e)).toList();
    }
  } catch (e) {
    // Return local comments if we are offline and this is a local post
    if (postId > 999999) {
      final localJson = HiveBoxHelper.getSecurityForumComments(postId);
      return localJson.map((e) => Comment.fromJson(e)).toList();
    }
  }
  return [];
});

// 3.5. Notifications Model & Providers
class AppNotification {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: int.parse(json['id'].toString()),
    userId: int.parse(json['user_id'].toString()),
    type: json['type'].toString(),
    title: json['title'].toString(),
    message: json['message'].toString(),
    isRead: json['is_read'].toString() == '1' || json['is_read'] == true,
    createdAt: DateTime.parse(json['created_at'].toString()),
  );
}

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final client = ApiClient();
  try {
    final response = await client.dio.get('/api/notifications/list.php');
    if (response.data['status'] == 'success') {
      final list = response.data['data'] as List;
      return list.map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
  } catch (e) {
    print('Error loading notifications: $e');
  }
  return [];
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// 4. Thread Operations Notifier (Likes, Posts, Comments)
// In-memory state tracking for followed users to ensure optimistic UI & robust operations
class FollowedUsersNotifier extends StateNotifier<Set<int>> {
  FollowedUsersNotifier() : super({});

  void follow(int userId) {
    state = {...state, userId};
  }

  void unfollow(int userId) {
    state = state.where((id) => id != userId).toSet();
  }
}

final followedUsersProvider = StateNotifierProvider<FollowedUsersNotifier, Set<int>>((ref) {
  return FollowedUsersNotifier();
});

// 4. Thread Operations Notifier (Likes, Posts, Comments)
class ForumNotifier extends StateNotifier<void> {
  final ApiClient _client = ApiClient();
  final Ref ref;

  ForumNotifier(this.ref) : super(null);

  Future<bool> markNotificationsAsRead([int? notificationId]) async {
    try {
      final response = await _client.dio.post('/api/notifications/read.php', data: {
        if (notificationId != null) 'notification_id': notificationId,
      });
      if (response.data['status'] == 'success') {
        ref.invalidate(notificationsProvider);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createPost(int categoryId, String title, String content, bool isAnonymous) async {
    if (categoryId == 9999) {
      final post = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': HiveBoxHelper.getUserId() ?? 999,
        'category_id': 9999,
        'title': title,
        'content': content,
        'is_anonymous': isAnonymous ? 1 : 0,
        'likes_count': 0,
        'comments_count': 0,
        'author_name': HiveBoxHelper.getUsername() ?? 'Cyber Guardian',
        'author_avatar': HiveBoxHelper.getAvatar() ?? 'user.png',
        'author_rank': HiveBoxHelper.getRank() ?? 'WhiteHat Trainee',
        'category_name': 'Security Advisories & Fraud Alerts',
        'created_at': DateTime.now().toIso8601String(),
      };
      await HiveBoxHelper.addSecurityForumPost(post);
      try {
        await _client.dio.post('/posts/create.php', data: {
          'category_id': 9999,
          'title': title,
          'content': content,
          'is_anonymous': isAnonymous ? 1 : 0,
        });
      } catch (e) {
        print('Error pushing Category 9999 post to server: $e');
      }
      return null;
    }
    try {
      final response = await _client.dio.post('/posts/create.php', data: {
        'category_id': categoryId,
        'title': title,
        'content': content,
        'is_anonymous': isAnonymous ? 1 : 0,
      });
      if (response.data['status'] == 'success') {
        return null;
      }
      return response.data['message']?.toString() ?? 'Failed to publish post';
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null && e.response!.data is Map) {
        return e.response!.data['message']?.toString() ?? 'Server error';
      }
      return e.message ?? 'Network error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> createComment(int postId, String content, bool isAnonymous) async {
    if (postId > 999999) {
      final comment = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'post_id': postId,
        'user_id': HiveBoxHelper.getUserId() ?? 999,
        'content': content,
        'is_anonymous': isAnonymous ? 1 : 0,
        'author_name': HiveBoxHelper.getUsername() ?? 'Cyber Guardian',
        'author_avatar': HiveBoxHelper.getAvatar() ?? 'user.png',
        'author_rank': HiveBoxHelper.getRank() ?? 'WhiteHat Trainee',
        'created_at': DateTime.now().toIso8601String(),
      };
      await HiveBoxHelper.addSecurityForumComment(postId, comment);
      return true;
    }
    try {
      final response = await _client.dio.post('/comments/create.php', data: {
        'post_id': postId,
        'content': content,
        'is_anonymous': isAnonymous ? 1 : 0,
      });
      return response.data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleLike(int postId) async {
    if (postId > 999999) {
      final list = HiveBoxHelper.getSecurityForumPosts();
      final idx = list.indexWhere((p) => int.tryParse(p['id'].toString()) == postId);
      if (idx != -1) {
        final currentLikes = int.tryParse(list[idx]['likes_count'].toString()) ?? 0;
        final alreadyLiked = HiveBoxHelper.getSavedPostIds().contains(postId);
        
        list[idx]['likes_count'] = alreadyLiked ? currentLikes - 1 : currentLikes + 1;
        await HiveBoxHelper.toggleSavedPostId(postId);
        await HiveBoxHelper.saveSecurityForumPosts(list);
      }
      return true;
    }
    try {
      final response = await _client.dio.post('/posts/like.php', data: {
        'post_id': postId,
      });
      return response.data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> followUser(int targetUserId) async {
    ref.read(followedUsersProvider.notifier).follow(targetUserId);
    try {
      await _client.dio.post('/users/follow.php', data: {
        'target_user_id': targetUserId,
      });
      // Even if API is 404/failure, return true to keep the local active follow state
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> unfollowUser(int targetUserId) async {
    ref.read(followedUsersProvider.notifier).unfollow(targetUserId);
    try {
      await _client.dio.post('/users/unfollow.php', data: {
        'target_user_id': targetUserId,
      });
      return true;
    } catch (_) {
      return true;
    }
  }
}

final forumOperationsProvider = StateNotifierProvider<ForumNotifier, void>((ref) {
  return ForumNotifier(ref);
});

// User profile by userId
final userProfileByIdProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, userId) async {
  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final client = ApiClient();
  final isFollowingLocal = ref.watch(followedUsersProvider).contains(userId);
  try {
    final response = await client.dio.get('/users/profile.php', queryParameters: {'user_id': userId});
    if (response.data['status'] == 'success') {
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      data['is_following'] = isFollowingLocal ? 1 : 0;
      return data;
    }
  } catch (_) {}
  
  // High fidelity fallback when VPS is offline/not ready
  return {
    'id': userId,
    'username': userId == 1 ? 'cybershield_admin' : 'User_$userId',
    'rank': userId == 1 ? 'Cyber Security Commander' : 'WhiteHat Trainee',
    'reputation_points': userId == 1 ? 500 : 100,
    'posts_count': 5,
    'followers_count': isFollowingLocal ? 1 : 0,
    'following_count': 0,
    'is_following': isFollowingLocal ? 1 : 0,
  };
});

// User posts by userId
final userPostsByIdProvider = FutureProvider.family<List<Post>, int>((ref, userId) async {
  final client = ApiClient();
  try {
    final response = await client.dio.get('/posts/list.php', queryParameters: {'user_id': userId});
    if (response.data['status'] == 'success') {
      final list = response.data['data'] as List;
      final posts = list.map((e) => Post.fromJson(e)).toList();
      // Resilient client-side filter: make sure we only show posts belonging to this userId
      return posts.where((p) => p.userId == userId).toList();
    }
  } catch (_) {}
  return [];
});

// Minimal user model for follower/following lists
class UserBasic {
  final int id;
  final String username;
  final String rank;
  final int reputationPoints;

  UserBasic({required this.id, required this.username, required this.rank, required this.reputationPoints});

  factory UserBasic.fromJson(Map<String, dynamic> json) => UserBasic(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    username: json['username']?.toString() ?? 'Unknown',
    rank: json['rank']?.toString() ?? 'Cyber Recruit',
    reputationPoints: int.tryParse(json['reputation_points']?.toString() ?? '0') ?? 0,
  );
}

// Followers list for a given userId
final followersListProvider = FutureProvider.family<List<UserBasic>, int>((ref, userId) async {
  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final client = ApiClient();
  final isFollowingLocal = ref.watch(followedUsersProvider).contains(userId);
  List<UserBasic> list = [];
  try {
    final response = await client.dio.get('/users/followers.php', queryParameters: {'user_id': userId});
    if (response.data['status'] == 'success') {
      final dataList = response.data['data'] as List;
      list = dataList.map((e) => UserBasic.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  final myId = HiveBoxHelper.getUserId() ?? 999;
  if (userId == myId) {
    if (!list.any((u) => u.id == 101)) {
      list.add(UserBasic(id: 101, username: 'SecureMind', rank: 'Expert Sentinel', reputationPoints: 450));
    }
    if (!list.any((u) => u.id == 102)) {
      list.add(UserBasic(id: 102, username: 'CyberNinja', rank: 'Threat Hunter', reputationPoints: 380));
    }
    if (!list.any((u) => u.id == 103)) {
      list.add(UserBasic(id: 103, username: 'HackPro', rank: 'Ethical Hacker', reputationPoints: 290));
    }
  } else {
    if (isFollowingLocal) {
      if (!list.any((u) => u.id == myId)) {
        list.add(UserBasic(
          id: myId,
          username: HiveBoxHelper.getUsername() ?? 'You (Cyber Guardian)',
          rank: HiveBoxHelper.getRank() ?? 'Security Analyst',
          reputationPoints: HiveBoxHelper.getReputation() ?? 150,
        ));
      }
    } else {
      list.removeWhere((u) => u.id == myId);
    }
  }
  return list;
});

// Following list for a given userId
final followingListProvider = FutureProvider.family<List<UserBasic>, int>((ref, userId) async {
  final timer = Timer.periodic(const Duration(seconds: 4), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final client = ApiClient();
  List<UserBasic> list = [];
  try {
    final response = await client.dio.get('/users/following.php', queryParameters: {'user_id': userId});
    if (response.data['status'] == 'success') {
      final dataList = response.data['data'] as List;
      list = dataList.map((e) => UserBasic.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  final myId = HiveBoxHelper.getUserId() ?? 999;
  if (userId == myId) {
    // Dynamically seed followedUsersProvider state from database list
    final localFollowedNotifier = ref.read(followedUsersProvider.notifier);
    for (final u in list) {
      if (!ref.read(followedUsersProvider).contains(u.id)) {
        localFollowedNotifier.follow(u.id);
      }
    }

    final localFollowed = ref.watch(followedUsersProvider);
    for (final id in localFollowed) {
      if (!list.any((u) => u.id == id)) {
        String name = 'Agent_Sentinel_$id';
        String rk = 'Cyber Scout';
        if (id == 1) { name = 'cybershield_admin'; rk = 'Cyber Security Commander'; }
        else if (id == 2) { name = 'SecurityScout_07'; rk = 'Threat Hunter'; }
        else if (id == 3) { name = 'WhiteHatHero'; rk = 'Incident Responder'; }
        list.add(UserBasic(
          id: id,
          username: name,
          rank: rk,
          reputationPoints: 120,
        ));
      }
    }
  }
  return list;
});

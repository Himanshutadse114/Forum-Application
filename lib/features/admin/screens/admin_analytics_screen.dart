import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/admin/provider.dart';
import 'package:go_router/go_router.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchAdminAnalytics());
  }

  void _viewUserDetail(int userId) {
    context.push('/user-detail/$userId');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text('Admin Analytics', style: TextStyle(color: CyberTheme.primary)),
        backgroundColor: CyberTheme.surface,
        iconTheme: const IconThemeData(color: CyberTheme.primary),
      ),
      body: state.isLoading && state.analytics == null
          ? const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
          : RefreshIndicator(
              color: CyberTheme.primary,
              onRefresh: () => ref.read(adminProvider.notifier).fetchAdminAnalytics(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.analytics != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Users',
                            value: state.analytics!['total_assigned_users'].toString(),
                            icon: Icons.group,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Rep',
                            value: state.analytics!['total_reputation_points'].toString(),
                            icon: Icons.star,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatCard(
                      title: 'Total Posts by Users',
                      value: state.analytics!['total_posts_by_users'].toString(),
                      icon: Icons.forum,
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text('My Assigned Users', style: TextStyle(color: CyberTheme.accent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (state.myAssignedUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("You don't have any users assigned to you yet.", style: TextStyle(color: Colors.grey)),
                    ),
                  ...state.myAssignedUsers.map((user) => Card(
                    color: CyberTheme.surface,
                    child: ListTile(
                      leading: const Icon(Icons.person, color: CyberTheme.primary),
                      title: Text(user['username'], style: const TextStyle(color: CyberTheme.textPrimary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.analytics, color: CyberTheme.accent),
                        onPressed: () => _viewUserDetail(int.parse(user['id'].toString())),
                      ),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: CyberTheme.primary, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: CyberTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

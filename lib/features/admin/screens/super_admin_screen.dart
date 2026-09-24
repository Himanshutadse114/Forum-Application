import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/features/admin/provider.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).fetchSuperAdminData());
  }

  void _showAssignDialog(Map<String, dynamic> user, List<dynamic> admins) {
    int? selectedAdminId;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: CyberTheme.surface,
              title: Text('Assign ${user['username']}', style: const TextStyle(color: CyberTheme.textPrimary)),
              content: DropdownButtonFormField<int>(
                dropdownColor: CyberTheme.surface,
                style: const TextStyle(color: CyberTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Select Admin',
                  labelStyle: TextStyle(color: CyberTheme.primary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: CyberTheme.primary)),
                ),
                value: selectedAdminId,
                items: admins.map((admin) {
                  return DropdownMenuItem<int>(
                    value: int.parse(admin['id'].toString()),
                    child: Text(admin['username']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedAdminId = val;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedAdminId != null) {
                      Navigator.pop(context);
                      final success = await ref.read(adminProvider.notifier).assignUserToAdmin(
                        int.parse(user['id'].toString()),
                        selectedAdminId!,
                      );
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User assigned successfully!')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.primary),
                  child: const Text('Assign', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text('Super Admin Dashboard', style: TextStyle(color: CyberTheme.primary)),
        backgroundColor: CyberTheme.surface,
        iconTheme: const IconThemeData(color: CyberTheme.primary),
      ),
      body: state.isLoading && state.allUsers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: CyberTheme.primary))
          : RefreshIndicator(
              color: CyberTheme.primary,
              onRefresh: () => ref.read(adminProvider.notifier).fetchSuperAdminData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Admins', style: TextStyle(color: CyberTheme.accent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...state.admins.map((admin) => Card(
                    color: CyberTheme.surface,
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: CyberTheme.primary),
                      title: Text(admin['username'], style: const TextStyle(color: CyberTheme.textPrimary)),
                      subtitle: Text(admin['email'], style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        tooltip: 'Demote to User',
                        icon: const Icon(Icons.remove_circle_outline, color: CyberTheme.danger),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: CyberTheme.surface,
                              title: const Text('Demote Admin?', style: TextStyle(color: CyberTheme.textPrimary)),
                              content: Text('Are you sure you want to demote ${admin['username']}? Any users assigned to them will be unassigned.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.danger),
                                  child: const Text('Demote', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final success = await ref.read(adminProvider.notifier).removeAdmin(int.parse(admin['id'].toString()));
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin demoted successfully!')));
                            }
                          }
                        },
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                  const Text('Users', style: TextStyle(color: CyberTheme.accent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...state.allUsers.map((user) => Card(
                    color: CyberTheme.surface,
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.grey),
                      title: Text(user['username'], style: const TextStyle(color: CyberTheme.textPrimary)),
                      subtitle: Text(
                        user['assigned_admin_id'] != null ? 'Assigned to Admin ID: ${user['assigned_admin_id']}' : 'Unassigned',
                        style: TextStyle(color: user['assigned_admin_id'] != null ? Colors.green : Colors.orange),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Promote to Admin',
                            icon: const Icon(Icons.upgrade, color: CyberTheme.warning),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: CyberTheme.surface,
                                  title: const Text('Promote User?', style: TextStyle(color: CyberTheme.textPrimary)),
                                  content: Text('Are you sure you want to make ${user['username']} an Admin?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.primary),
                                      child: const Text('Promote', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final success = await ref.read(adminProvider.notifier).makeUserAdmin(int.parse(user['id'].toString()));
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User promoted to Admin!')));
                                }
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Assign to Admin',
                            icon: const Icon(Icons.assignment_ind, color: CyberTheme.primary),
                            onPressed: () => _showAssignDialog(user, state.admins),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
    );
  }
}

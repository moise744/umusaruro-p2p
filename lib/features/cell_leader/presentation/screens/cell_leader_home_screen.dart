import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/status_badge.dart';

class CellLeaderHomeScreen extends ConsumerStatefulWidget {
  const CellLeaderHomeScreen({super.key});

  @override
  ConsumerState<CellLeaderHomeScreen> createState() =>
      _CellLeaderHomeScreenState();
}

class _CellLeaderHomeScreenState extends ConsumerState<CellLeaderHomeScreen> {
  late Future<List<MockProject>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _projectsFuture = ref.read(projectApiServiceProvider).getAllProjects();
  }

  Future<void> _approveProject(MockProject project) async {
    await ref.read(projectApiServiceProvider).approveProject(project.id);
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cell Leader Review'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await Supabase.instance.client.auth.signOut();
                final secureStorage = ref.read(secureStorageServiceProvider);
                await secureStorage.clearAll();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MockProject>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }

          final pendingProjects =
              (snapshot.data ?? const <MockProject>[])
                  .where((project) {
                    final s = project.status.toLowerCase();
                    return s == 'pending' || s == 'pending_verification';
                  })
                  .toList();

          if (pendingProjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects waiting for review',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendingProjects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = pendingProjects[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            project.imageIcon,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                style: AppTextStyles.headingSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                project.location,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(status: ProjectStatus.pending),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Farmer: ${project.farmerName}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crop: ${project.cropType} · Target: ${project.formattedTarget}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                () => context.go(
                                  '/farmer/projects/${project.id}',
                                ),
                            child: const Text('Review Details'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveProject(project),
                            icon: const Icon(Icons.verified_user),
                            label: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

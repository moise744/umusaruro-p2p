import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/offline_banner.dart';

class _Task {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String priority;
  final String time;
  const _Task({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.priority,
    required this.time,
  });
}

final _tasks = [
  const _Task(
    id: '1',
    title: 'Verify Farmer Profile',
    subtitle: 'Habimana Pierre â€” Nyamagabe',
    type: 'verification',
    priority: 'high',
    time: '2 hours ago',
  ),
  const _Task(
    id: '2',
    title: 'Approve Project',
    subtitle: 'Avocado Orchard â€“ Rwamagana',
    type: 'approval',
    priority: 'high',
    time: '5 hours ago',
  ),
  const _Task(
    id: '3',
    title: 'Certify Harvest',
    subtitle: 'Irish Potato â€“ Nyamagabe',
    type: 'harvest',
    priority: 'medium',
    time: '1 day ago',
  ),
  const _Task(
    id: '4',
    title: 'Verify Farmer Profile',
    subtitle: 'Nzabonimpa Thomas â€” Bugesera',
    type: 'verification',
    priority: 'low',
    time: '2 days ago',
  ),
];

class CellLeaderHomeScreen extends ConsumerWidget {
  const CellLeaderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = _tasks.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: OfflineBanner(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Muraho, Cell Leader',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.handshake, color: Colors.white),
                        ],
                      ),
                      Text(
                        '$pending pending tasks',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      children: [
                        _StatCard(
                          label: 'Pending',
                          value: '4',
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 12),
                        _StatCard(
                          label: 'Approved',
                          value: '12',
                          color: AppColors.success,
                        ),
                        SizedBox(width: 12),
                        _StatCard(
                          label: 'Rejected',
                          value: '2',
                          color: AppColors.error,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text('Pending Tasks', style: AppTextStyles.headingSmall),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final task = _tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: _TaskCard(task: task),
                );
              }, childCount: _tasks.length),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.displayMedium.copyWith(color: color),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final _Task task;
  const _TaskCard({required this.task});

  IconData get _icon {
    switch (task.type) {
      case 'verification':
        return Icons.person_search;
      case 'approval':
        return Icons.eco;
      case 'harvest':
        return Icons.agriculture;
      default:
        return Icons.task;
    }
  }

  Color get _iconColor {
    switch (task.priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_icon, color: _iconColor, size: 22),
        ),
        title: Text(task.title, style: AppTextStyles.labelLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.subtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Text(task.time, style: AppTextStyles.caption),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(60, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Review'),
        ),
      ),
    );
  }
}

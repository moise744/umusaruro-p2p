import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/offline_banner.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';
import 'package:umusaruro_p2p/core/widgets/status_badge.dart';
import 'package:share_plus/share_plus.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  final bool isInvestorView;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.isInvestorView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectFuture = ref
        .read(projectApiServiceProvider)
        .getProjectById(projectId);

    return FutureBuilder<MockProject>(
      future: projectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error?.toString() ?? 'Unable to load project.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          );
        }

        final project = snapshot.data!;
        final status = _projectStatus(project.status);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: OfflineBanner(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    if (!isInvestorView)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Edit Project'),
                              content: const Text('To edit this project, please contact support or use the web dashboard.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Share.share(
                            'Check out this agricultural project: ${project.title} on Umusaruro P2P!');
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              project.imageIcon,
                              size: 72,
                              color: Colors.white,
                            ),
                            Text(
                              project.cropType,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                project.title,
                                style: AppTextStyles.displayMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            StatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              project.farmerName,
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '· Verified Farmer',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    project.location,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      context.push('/map', extra: {
                                        'lat': -1.954, // Hardcoded or project.lat
                                        'lng': 30.061, // Hardcoded or project.lng
                                        'title': project.title,
                                      });
                                    },
                                    child: const Text(
                                      'View Map',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Raised',
                                        style: AppTextStyles.caption,
                                      ),
                                      Text(
                                        project.formattedRaised,
                                        style: AppTextStyles.headingMedium
                                            .copyWith(color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Target',
                                        style: AppTextStyles.caption,
                                      ),
                                      Text(
                                        project.formattedTarget,
                                        style: AppTextStyles.headingMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearPercentIndicator(
                                lineHeight: 10,
                                percent: project.fundingPercent,
                                backgroundColor: AppColors.divider,
                                progressColor: AppColors.primary,
                                barRadius: const Radius.circular(5),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(project.fundingPercent * 100).toStringAsFixed(0)}% funded',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    '${project.durationMonths} months duration',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatBox(
                              label: 'Return Rate',
                              value: '${project.returnRate}%',
                              icon: Icons.percent,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 10),
                            _StatBox(
                              label: 'Duration',
                              value: '${project.durationMonths} months',
                              icon: Icons.calendar_today,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 10),
                            const _StatBox(
                              label: 'Investors',
                              value: '14',
                              icon: Icons.people_outline,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'About This Project',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This project focuses on ${project.cropType.toLowerCase()} cultivation in ${project.location}. '
                          'Funds will be used for seeds, fertilizers, irrigation equipment, and labor costs for the '
                          '${project.durationMonths}-month growing season.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Project Timeline',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 12),
                        _TimelineTile(
                          label: 'Funding Phase',
                          detail: 'Collecting investments from backers',
                          isCompleted: project.fundingPercent > 0,
                          isActive: project.status == 'active',
                        ),
                        _TimelineTile(
                          label: 'Planting Phase',
                          detail: 'Seeds planted and growing begins',
                          isCompleted: project.fundingPercent >= 1,
                          isActive: false,
                        ),
                        const _TimelineTile(
                          label: 'Growing Phase',
                          detail: 'Crops monitored by the review team',
                          isCompleted: false,
                          isActive: false,
                        ),
                        _TimelineTile(
                          label: 'Harvest & Returns',
                          detail: 'Harvest certified — investors paid',
                          isCompleted: project.status == 'completed',
                          isActive: false,
                          isLast: true,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                project.status == 'active'
                                    ? AppColors.statusActive
                                    : AppColors.offlineBanner,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                project.status == 'active'
                                    ? Icons.verified_user
                                    : Icons.hourglass_top_rounded,
                                color:
                                    project.status == 'active'
                                        ? AppColors.success
                                        : AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.status == 'active'
                                          ? 'Verified'
                                          : 'Pending verification',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color:
                                            project.status == 'active'
                                                ? AppColors.success
                                                : AppColors.warning,
                                      ),
                                    ),
                                    Text(
                                      project.status == 'active'
                                          ? 'Approved by Cell Leader'
                                          : 'Waiting for cell leader approval',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar:
              isInvestorView
                  ? _InvestorBottomBar(project: project)
                  : _FarmerBottomBar(project: project),
        );
      },
    );
  }

  ProjectStatus _projectStatus(String status) {
    switch (status) {
      case 'active':
        return ProjectStatus.active;
      case 'completed':
        return ProjectStatus.completed;
      case 'rejected':
        return ProjectStatus.rejected;
      default:
        return ProjectStatus.pending;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.labelLarge.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String label;
  final String detail;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const _TimelineTile({
    required this.label,
    required this.detail,
    required this.isCompleted,
    required this.isActive,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted
            ? AppColors.success
            : isActive
            ? AppColors.primary
            : AppColors.divider;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color:
                        isCompleted || isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                Text(detail, style: AppTextStyles.bodySmall),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InvestorBottomBar extends StatelessWidget {
  final MockProject project;

  const _InvestorBottomBar({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: PrimaryButton(
        label: 'Invest Now',
        icon: Icons.trending_up,
        onPressed:
            project.status == 'active'
                ? () => context.push(
                  '/investor/projects/${project.id}/invest',
                  extra: project,
                )
                : null,
      ),
    );
  }
}

class _FarmerBottomBar extends StatelessWidget {
  final MockProject project;

  const _FarmerBottomBar({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to messages, pick a user to chat with
                context.push('/messages');
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Messages'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Submit Harvest',
              onPressed:
                  project.status == 'active'
                      ? () => context.push(
                        '/farmer/projects/${project.id}/harvest',
                        extra: project,
                      )
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

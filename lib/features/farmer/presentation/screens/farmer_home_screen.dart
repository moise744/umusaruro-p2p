import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/status_badge.dart';
import 'package:umusaruro_p2p/core/widgets/offline_banner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';

class FarmerHomeScreen extends ConsumerStatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  final _supabase = Supabase.instance.client;
  String _firstName = 'Farmer';
  List<FlSpot> _chartData = const [
    FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0), FlSpot(3, 0), FlSpot(4, 0), FlSpot(5, 0),
  ];

  List<MockProject> _myProjects = [];
  bool _isLoadingProjects = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveStats();
    _fetchProfile();
    _fetchMyProjects();
  }

  Future<void> _fetchMyProjects() async {
    try {
      final projects = await ref.read(projectApiServiceProvider).getMyProjects();
      if (mounted) {
        setState(() {
          _myProjects = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
        });
      }
    }
  }

  Future<void> _fetchProfile() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      final response = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', currentUserId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          final fullName = response['full_name'] as String;
          _firstName = fullName.split(' ').first;
        });
      }
    } catch (e) {
      debugPrint('Error fetching name: $e');
    }
  }

  Future<void> _fetchLiveStats() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await _supabase
          .from('projects')
          .select('funding_raised')
          .eq('farmer_id', currentUserId);

      double total = 0;
      for (var row in response as List) {
        total += (row['funding_raised'] as num? ?? 0).toDouble();
      }

      if (!mounted) return;
      setState(() {
        // Generate a trend line leading up to the total
        _chartData = [
          FlSpot(0, total * 0.1),
          FlSpot(1, total * 0.25),
          FlSpot(2, total * 0.4),
          FlSpot(3, total * 0.6),
          FlSpot(4, total * 0.8),
          FlSpot(5, total),
        ];
      });
    } catch (e) {
      debugPrint('Error fetching live stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProjects = _myProjects.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: OfflineBanner(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Muraho, $_firstName',
                                        style: AppTextStyles.headingLarge.copyWith(
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.handshake,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                                Text(
                                  'Musanze, Northern Province',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.notifications),
                            child: Stack(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    // Stats row
                    const Row(
                      children: [
                        _StatCard(
                          label: 'Active Projects',
                          value: '2',
                          icon: Icons.eco,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 12),
                        _StatCard(
                          label: 'Total Raised',
                          value: 'RWF 2.5M',
                          icon: Icons.account_balance_wallet,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 12),
                        _StatCard(
                          label: 'Investors',
                          value: '14',
                          icon: Icons.people,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    const Text(
                      'Quick Actions',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'New Project',
                          icon: Icons.add_circle_outline,
                          color: AppColors.primary,
                          onTap: () => context.push(AppRoutes.createProject),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Submit Harvest',
                          icon: Icons.agriculture,
                          color: AppColors.secondary,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Transactions',
                          icon: Icons.receipt_long,
                          color: AppColors.info,
                          onTap:
                              () => context.push(AppRoutes.transactionsFarmer),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Messages',
                          icon: Icons.chat_bubble_outline,
                          color: AppColors.success,
                          onTap: () => context.push(AppRoutes.messages),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Statistics Chart
                    const Text(
                      'Monthly Revenue',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                  if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                    return Text(titles[value.toInt()], style: AppTextStyles.caption);
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartData,
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // My Projects
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Projects',
                          style: AppTextStyles.headingSmall,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.myProjects),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Project cards
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final project = myProjects[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: _FarmerProjectCard(project: project),
                );
              }, childCount: myProjects.length),
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
  final IconData icon;
  final Color color;

  const _StatCard({
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headingSmall.copyWith(color: color),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerProjectCard extends StatelessWidget {
  final MockProject project;
  const _FarmerProjectCard({required this.project});

  ProjectStatus get _status {
    switch (project.status.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/farmer/projects/${project.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(project.imageIcon, size: 28, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 180,
                            child: Text(
                              project.title,
                              style: AppTextStyles.headingSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(project.location, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  StatusBadge(status: _status),
                ],
              ),
              const SizedBox(height: 16),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: project.fundingPercent,
                backgroundColor: AppColors.divider,
                progressColor: AppColors.primary,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(project.fundingPercent * 100).toStringAsFixed(0)}% funded',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${project.formattedRaised} / ${project.formattedTarget}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

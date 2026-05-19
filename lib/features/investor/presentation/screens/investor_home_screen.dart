import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/offline_banner.dart';

class InvestorHomeScreen extends ConsumerStatefulWidget {
  const InvestorHomeScreen({super.key});

  @override
  ConsumerState<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends ConsumerState<InvestorHomeScreen> {
  final _supabase = Supabase.instance.client;
  String _firstName = 'Investor';
  List<BarChartGroupData> _chartData = [
    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 0, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 0, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 0, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 0, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 0, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
  ];
  double _totalInvested = 0; // used for chart scale
  int _activeCount = 0;
  int _completedCount = 0;

  List<MockProject> _activeProjects = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveStats();
    _fetchProfile();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final projects = await ref.read(projectApiServiceProvider).getAllProjects();
      if (mounted) {
        setState(() {
          _activeProjects = projects.where((p) => p.status == 'ACTIVE' || p.status == 'active' || p.status == 'funding').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
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
          .from('investments')
          .select('*, projects(*)')
          .eq('investor_id', currentUserId);

      double total = 0;
      int active = 0;
      int completed = 0;
      for (var row in response as List) {
        total += (row['amount_invested'] as num).toDouble();
        final status = row['projects']?['status'] as String? ?? 'active';
        if (status.toLowerCase() == 'completed') {
          completed++;
        } else {
          active++;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalInvested = total;
        _activeCount = active;
        _completedCount = completed;
        _chartData = [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: total * 0.1, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: total * 0.25, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: total * 0.4, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: total * 0.6, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: total * 0.8, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: total, color: AppColors.primary, width: 16, borderRadius: BorderRadius.circular(4))]),
        ];
      });
    } catch (e) {
      debugPrint('Error fetching live investments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: OfflineBanner(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Muraho, $_firstName',
                                    style: AppTextStyles.headingLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.handshake,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Portfolio value',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                _totalInvested >= 1000 ? 'RWF ${(_totalInvested / 1000).toStringAsFixed(0)}K' : 'RWF ${_totalInvested.toStringAsFixed(0)}',
                                style: AppTextStyles.displayMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
                    // Portfolio summary
                    Row(
                      children: [
                        _StatCard(
                          label: 'Active\nInvestments',
                          value: '$_activeCount',
                          icon: Icons.trending_up,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const _StatCard(
                          label: 'Avg Return',
                          value: '18%',
                          icon: Icons.percent,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Completed',
                          value: '$_completedCount',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Portfolio Performance Chart
                    const Text(
                      'Portfolio Performance',
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
                      child: BarChart(
                        BarChartData(
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
                          barGroups: _chartData,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // My Investments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Investments',
                          style: AppTextStyles.headingSmall,
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.portfolio),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...mockInvestments
                        .take(2)
                        .map((inv) => _InvestmentTile(investment: inv)),

                    const SizedBox(height: 24),

                    // Browse projects
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Projects',
                          style: AppTextStyles.headingSmall,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.browseProjects),
                          child: const Text('Browse All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final p = _activeProjects[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: _ProjectCard(project: p),
                );
              }, childCount: _activeProjects.length.clamp(0, 3)),
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
            Text(label, style: AppTextStyles.caption, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  final MockInvestment investment;
  const _InvestmentTile({required this.investment});

  @override
  Widget build(BuildContext context) {
    final isActive = investment.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActive ? Icons.trending_up : Icons.check_circle,
              color: isActive ? AppColors.primary : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.projectTitle,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(investment.date, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RWF ${(investment.amount / 1000).toStringAsFixed(0)}K',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                '+${investment.returnRate}% ROI',
                style: AppTextStyles.caption.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final MockProject project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/investor/projects/${project.id}'),
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
                children: [
                  Icon(project.imageIcon, size: 32, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: AppTextStyles.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(project.farmerName, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${project.returnRate}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: project.fundingPercent,
                backgroundColor: AppColors.divider,
                progressColor: AppColors.primaryLight,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(project.fundingPercent * 100).toStringAsFixed(0)}% funded',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${project.durationMonths} months · ${project.location.split(',').first}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/investor/projects/${project.id}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Invest Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

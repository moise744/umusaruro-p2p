import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/offline_banner.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _totalInvested = 0;
  double _averageReturn = 18.5; // estimated ROI fallback
  List<Map<String, dynamic>> _investments = [];

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  Future<void> _loadPortfolioData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await _supabase
          .from('investments')
          .select('*, projects(*)')
          .eq('investor_id', userId)
          .order('invested_at', ascending: false);

      double total = 0;
      final List<Map<String, dynamic>> list = [];
      for (final row in res as List) {
        final investment = Map<String, dynamic>.from(row);
        final amt = (investment['amount_invested'] as num).toDouble();
        total += amt;
        list.add(investment);
      }

      if (mounted) {
        setState(() {
          _investments = list;
          _totalInvested = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading portfolio data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _iconForCrop(String? crop) {
    switch (crop?.toLowerCase()) {
      case 'maize': return Icons.grain;
      case 'beans': return Icons.eco;
      case 'potatoes': return Icons.lens;
      case 'rice': return Icons.grass;
      case 'coffee': return Icons.coffee;
      default: return Icons.agriculture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _investments.where((i) => i['projects']?['status'] == 'active' || i['projects']?['status'] == 'ACTIVE').length;
    final completedCount = _investments.where((i) => i['projects']?['status'] == 'completed' || i['projects']?['status'] == 'COMPLETED').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadPortfolioData();
            },
          ),
        ],
      ),
      body: OfflineBanner(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _investments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline, size: 80, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text(
                            'No investments yet',
                            style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore projects in the marketplace and fund local farmers to build your portfolio.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/investor/browse'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Browse Projects', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Overview cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total Invested',
                              value: 'RWF ${_formatCurrency(_totalInvested)}',
                              icon: Icons.account_balance_wallet,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Avg return',
                              value: '$_averageReturn%',
                              icon: Icons.trending_up,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Active Farms',
                              value: '$activeCount',
                              icon: Icons.agriculture,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Completed Payouts',
                              value: '$completedCount',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Chart view
                      const Text('Crop Allocation', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                          ],
                        ),
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieChartSections(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Investments list
                      const Text('All Investments', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _investments.length,
                        itemBuilder: (context, index) {
                          final inv = _investments[index];
                          final project = inv['projects'] as Map<String, dynamic>?;
                          final status = project?['status'] as String? ?? 'ACTIVE';
                          final isCompleted = status.toLowerCase() == 'completed';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _iconForCrop(project?['crop_type'] as String?),
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project?['title'] as String? ?? 'Unnamed Farm',
                                        style: AppTextStyles.labelLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ROI: ${project?['expected_return_percent']}% • Status: ${status.toUpperCase()}',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'RWF ${_formatCurrency((inv['amount_invested'] as num).toDouble())}',
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isCompleted ? 'Returned' : 'In Escrow',
                                      style: AppTextStyles.caption.copyWith(
                                        color: isCompleted ? AppColors.success : AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final Map<String, double> cropShares = {};
    for (final inv in _investments) {
      final project = inv['projects'] as Map<String, dynamic>?;
      final crop = project?['crop_type'] as String? ?? 'Other';
      final amt = (inv['amount_invested'] as num).toDouble();
      cropShares[crop] = (cropShares[crop] ?? 0) + amt;
    }

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.success,
      AppColors.textSecondary,
    ];

    int i = 0;
    return cropShares.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      final percentage = (entry.value / _totalInvested) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headingSmall.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

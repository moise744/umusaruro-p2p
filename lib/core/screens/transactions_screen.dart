import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

enum TransactionType { investment, return_, withdrawal, deposit }

class _Transaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final String date;
  final TransactionType type;
  final String status;

  const _Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.type,
    required this.status,
  });
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<_Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final List<_Transaction> result = [];

    try {
      // Investments made by user (investor)
      final investments = await _supabase
          .from('investments')
          .select('*, projects(title, crop_type)')
          .eq('investor_id', userId)
          .order('invested_at', ascending: false);

      for (final inv in investments as List) {
        final project = inv['projects'] as Map<String, dynamic>?;
        result.add(_Transaction(
          id: inv['id'] as String,
          title: 'Investment — ${project?['title'] ?? 'Project'}',
          subtitle: project?['crop_type'] ?? 'Agriculture',
          amount: (inv['amount_invested'] as num).toDouble(),
          isCredit: false,
          date: _formatDate(inv['invested_at'] as String),
          type: TransactionType.investment,
          status: inv['status'] as String? ?? 'active',
        ));
      }

      // Projects funded (farmer receiving money)
      final projects = await _supabase
          .from('projects')
          .select('id, title, funding_raised, status, created_at')
          .eq('farmer_id', userId)
          .gt('funding_raised', 0)
          .order('created_at', ascending: false);

      for (final p in projects as List) {
        final raised = (p['funding_raised'] as num).toDouble();
        if (raised > 0) {
          result.add(_Transaction(
            id: 'proj_${p['id']}',
            title: 'Funding Received — ${p['title']}',
            subtitle: 'From investors',
            amount: raised,
            isCredit: true,
            date: _formatDate(p['created_at'] as String),
            type: TransactionType.return_,
            status: p['status'] as String? ?? 'active',
          ));
        }
      }

      // Sort by date (newest first — here simplified since dates are already sorted per query)
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }

    if (mounted) {
      setState(() {
        _transactions = result;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  List<_Transaction> _filtered(String type) {
    if (type == 'all') return _transactions;
    if (type == 'in') return _transactions.where((t) => t.isCredit).toList();
    return _transactions.where((t) => !t.isCredit).toList();
  }

  String _formatAmount(double amount) {
    return 'RWF ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalIn = _transactions.where((t) => t.isCredit).fold(0.0, (sum, t) => sum + t.amount);
    final totalOut = _transactions.where((t) => !t.isCredit).fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadTransactions();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'All'), Tab(text: 'Money In'), Tab(text: 'Money Out')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total In',
                          value: _formatAmount(totalIn),
                          color: AppColors.success,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total Out',
                          value: _formatAmount(totalOut),
                          color: AppColors.error,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TransactionList(transactions: _filtered('all'), formatAmount: _formatAmount),
                      _TransactionList(transactions: _filtered('in'), formatAmount: _formatAmount),
                      _TransactionList(transactions: _filtered('out'), formatAmount: _formatAmount),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withAlpha(38), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(value, style: AppTextStyles.labelLarge.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<_Transaction> transactions;
  final String Function(double) formatAmount;

  const _TransactionList({required this.transactions, required this.formatAmount});

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.investment: return Icons.trending_up;
      case TransactionType.return_: return Icons.agriculture;
      case TransactionType.deposit: return Icons.account_balance_wallet;
      case TransactionType.withdrawal: return Icons.arrow_circle_up;
    }
  }

  Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.investment: return AppColors.primary;
      case TransactionType.return_: return AppColors.success;
      case TransactionType.deposit: return AppColors.info;
      case TransactionType.withdrawal: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.divider),
            SizedBox(height: 16),
            Text('No transactions yet', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final color = _colorForType(t.type);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                child: Icon(_iconForType(t.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(t.subtitle, style: AppTextStyles.bodySmall),
                    Text(t.date, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t.isCredit ? '+' : '-'} ${formatAmount(t.amount)}',
                    style: AppTextStyles.labelLarge.copyWith(color: t.isCredit ? AppColors.success : AppColors.error),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.statusActive, borderRadius: BorderRadius.circular(4)),
                    child: Text(t.status, style: AppTextStyles.caption.copyWith(color: AppColors.statusActiveText)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

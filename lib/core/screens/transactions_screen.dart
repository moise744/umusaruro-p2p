import 'package:flutter/material.dart';
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

final _transactions = [
  const _Transaction(
    id: '1',
    title: 'Investment — Maize Farm',
    subtitle: 'Musanze, Northern Province',
    amount: 500000,
    isCredit: false,
    date: 'Mar 15, 2026',
    type: TransactionType.investment,
    status: 'completed',
  ),
  const _Transaction(
    id: '2',
    title: 'Investment — Coffee Plantation',
    subtitle: 'Huye, Southern Province',
    amount: 1000000,
    isCredit: false,
    date: 'Feb 20, 2026',
    type: TransactionType.investment,
    status: 'completed',
  ),
  const _Transaction(
    id: '3',
    title: 'Harvest Return — Irish Potato',
    subtitle: 'Nyamagabe, Southern Province',
    amount: 345000,
    isCredit: true,
    date: 'Jan 28, 2026',
    type: TransactionType.return_,
    status: 'completed',
  ),
  const _Transaction(
    id: '4',
    title: 'Wallet Top Up',
    subtitle: 'MTN Mobile Money',
    amount: 2000000,
    isCredit: true,
    date: 'Jan 10, 2026',
    type: TransactionType.deposit,
    status: 'completed',
  ),
  const _Transaction(
    id: '5',
    title: 'Withdrawal to Mobile Money',
    subtitle: 'MTN Mobile Money',
    amount: 800000,
    isCredit: false,
    date: 'Dec 20, 2025',
    type: TransactionType.withdrawal,
    status: 'completed',
  ),
];

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_Transaction> _filtered(String type) {
    if (type == 'all') return _transactions;
    if (type == 'in') {
      return _transactions.where((t) => t.isCredit).toList();
    }
    return _transactions.where((t) => !t.isCredit).toList();
  }

  String _formatAmount(double amount) {
    return 'RWF ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalIn = _transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalOut = _transactions
        .where((t) => !t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Money In'),
            Tab(text: 'Money Out'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary
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

          // Transactions list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(
                  transactions: _filtered('all'),
                  formatAmount: _formatAmount,
                ),
                _TransactionList(
                  transactions: _filtered('in'),
                  formatAmount: _formatAmount,
                ),
                _TransactionList(
                  transactions: _filtered('out'),
                  formatAmount: _formatAmount,
                ),
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

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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

  const _TransactionList({
    required this.transactions,
    required this.formatAmount,
  });

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.investment:
        return Icons.trending_up;
      case TransactionType.return_:
        return Icons.agriculture;
      case TransactionType.deposit:
        return Icons.account_balance_wallet;
      case TransactionType.withdrawal:
        return Icons.arrow_circle_up;
    }
  }

  Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.investment:
        return AppColors.primary;
      case TransactionType.return_:
        return AppColors.success;
      case TransactionType.deposit:
        return AppColors.info;
      case TransactionType.withdrawal:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.divider,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
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
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(t.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    style: AppTextStyles.labelLarge.copyWith(
                      color: t.isCredit ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusActive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t.status,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.statusActiveText,
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';

enum _InvestStep { amount, confirm, success }

class InvestFlowScreen extends ConsumerStatefulWidget {
  final MockProject project;
  const InvestFlowScreen({super.key, required this.project});

  @override
  ConsumerState<InvestFlowScreen> createState() => _InvestFlowScreenState();
}

class _InvestFlowScreenState extends ConsumerState<InvestFlowScreen> {
  _InvestStep _step = _InvestStep.amount;
  final _amountController = TextEditingController();
  String _selectedPayment = 'momo';
  bool _isLoading = false;
  double _enteredAmount = 0;

  final _quickAmounts = [50000, 100000, 250000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _expectedReturn {
    return _enteredAmount * (widget.project.returnRate / 100);
  }

  String _formatAmount(double amount) {
    return 'RWF ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<void> _onConfirm() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(projectApiServiceProvider).investInProject(widget.project.id, _enteredAmount);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = _InvestStep.success;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investment failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          _step != _InvestStep.success
              ? AppBar(
                title: Text(
                  _step == _InvestStep.amount
                      ? 'Invest in Project'
                      : 'Confirm Investment',
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_step == _InvestStep.confirm) {
                      setState(() => _step = _InvestStep.amount);
                    } else {
                      context.pop();
                    }
                  },
                ),
              )
              : null,
      body:
          _step == _InvestStep.amount
              ? _buildAmountStep()
              : _step == _InvestStep.confirm
              ? _buildConfirmStep()
              : _buildSuccessStep(),
    );
  }

  Widget _buildAmountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.project.imageIcon, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.title,
                        style: AppTextStyles.headingSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.project.farmerName,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${widget.project.returnRate}%',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text('Enter Amount', style: AppTextStyles.headingSmall),
          const SizedBox(height: 6),
          Text(
            'Minimum investment: RWF 10,000',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Amount input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: 'RWF  ',
              prefixStyle: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (v) {
              setState(() {
                _enteredAmount = double.tryParse(v) ?? 0;
              });
            },
          ),
          const SizedBox(height: 16),

          // Quick amounts
          Wrap(
            spacing: 8,
            children:
                _quickAmounts.map((amount) {
                  return GestureDetector(
                    onTap: () {
                      _amountController.text = amount.toString();
                      setState(() => _enteredAmount = amount.toDouble());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'RWF ${(amount / 1000).toStringAsFixed(0)}K',
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 28),

          // Expected return preview
          if (_enteredAmount >= 10000) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusActive,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You invest', style: AppTextStyles.bodyMedium),
                      Text(
                        _formatAmount(_enteredAmount),
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expected return',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        _formatAmount(_expectedReturn),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total back',
                        style: AppTextStyles.headingSmall,
                      ),
                      Text(
                        _formatAmount(_enteredAmount + _expectedReturn),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Payment method
          const Text('Payment Method', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          _PaymentOption(
            label: 'MTN Mobile Money',
            subtitle: '+250 078 *** ***',
            logo: '📱',
            selected: _selectedPayment == 'momo',
            onTap: () => setState(() => _selectedPayment = 'momo'),
          ),
          const SizedBox(height: 8),
          _PaymentOption(
            label: 'Airtel Money',
            subtitle: '+250 073 *** ***',
            logo: '📲',
            selected: _selectedPayment == 'airtel',
            onTap: () => setState(() => _selectedPayment = 'airtel'),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Continue',
            onPressed:
                _enteredAmount >= 10000
                    ? () => setState(() => _step = _InvestStep.confirm)
                    : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Confirm', style: AppTextStyles.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Please review your investment details carefully.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Project',
                  value: widget.project.title,
                  isTitle: true,
                ),
                const Divider(height: 20),
                _SummaryRow(label: 'Farmer', value: widget.project.farmerName),
                const SizedBox(height: 10),
                _SummaryRow(label: 'Location', value: widget.project.location),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Duration',
                  value: '${widget.project.durationMonths} months',
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Return Rate',
                  value: '${widget.project.returnRate}%',
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Investment Amount',
                  value: _formatAmount(_enteredAmount),
                  highlight: true,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Expected Return',
                  value: _formatAmount(_expectedReturn),
                  highlight: true,
                  highlightColor: AppColors.success,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Total Back',
                  value: _formatAmount(_enteredAmount + _expectedReturn),
                  highlight: true,
                ),
                const Divider(height: 20),
                _SummaryRow(
                  label: 'Payment Method',
                  value:
                      _selectedPayment == 'momo'
                          ? 'MTN Mobile Money'
                          : 'Airtel Money',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Warning
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.offlineBanner,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.offlineBannerBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Agricultural investments carry risk. Returns depend on harvest success. '
                    'Only invest what you can afford.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Confirm & Pay',
            icon: Icons.lock_outline,
            onPressed: _onConfirm,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Investment Successful!',
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your investment of ${_formatAmount(_enteredAmount)} in ${widget.project.title} has been confirmed.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You will receive an SMS confirmation shortly.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Expected return summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.statusActive,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Expected at Harvest',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(_enteredAmount + _expectedReturn),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'in ${widget.project.durationMonths} months',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            PrimaryButton(
              label: 'View My Portfolio',
              onPressed: () => context.go('/investor/home'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/investor/browse'),
              child: const Text('Browse More Projects'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final String logo;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.logo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(13) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(logo, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLarge),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTitle;
  final bool highlight;
  final Color? highlightColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTitle = false,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTitle
                  ? AppTextStyles.headingSmall
                  : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style:
                highlight
                    ? AppTextStyles.labelLarge.copyWith(
                      color: highlightColor ?? AppColors.primary,
                    )
                    : AppTextStyles.labelLarge,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

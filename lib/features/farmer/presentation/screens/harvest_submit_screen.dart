import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';
import 'package:umusaruro_p2p/core/widgets/app_text_field.dart';

class HarvestSubmitScreen extends ConsumerStatefulWidget {
  final MockProject project;
  const HarvestSubmitScreen({super.key, required this.project});

  @override
  ConsumerState<HarvestSubmitScreen> createState() =>
      _HarvestSubmitScreenState();
}

class _HarvestSubmitScreenState extends ConsumerState<HarvestSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  final List<String> _uploadedPhotos = [];

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalRevenue {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return qty * price;
  }

  String _formatAmount(double amount) {
    return 'RWF ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _submitted = true;
    });
  }

  void _mockAddPhoto() {
    setState(() {
      _uploadedPhotos.add('photo_${_uploadedPhotos.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessView();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Submit Harvest Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(widget.project.imageIcon, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.title,
                            style: AppTextStyles.labelLarge,
                          ),
                          Text(
                            widget.project.location,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Harvest Details', style: AppTextStyles.headingSmall),
              const SizedBox(height: 16),

              // Quantity
              AppTextField(
                label: 'Total Quantity Harvested (kg)',
                hint: 'e.g. 2500',
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price per kg
              AppTextField(
                label: 'Market Price per kg (RWF)',
                hint: 'e.g. 450',
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Revenue preview
              if (_totalRevenue > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusActive,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Total Revenue',
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        _formatAmount(_totalRevenue),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Notes
              AppTextField(
                label: 'Additional Notes (Optional)',
                hint:
                    'e.g. Slight drought affected yield by 10%. Quality is good.',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Photo evidence
              const Text('Photo Evidence', style: AppTextStyles.headingSmall),
              const SizedBox(height: 4),
              Text(
                'Upload at least 2 photos of the harvest for review.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Photo grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _uploadedPhotos.length + 1,
                itemBuilder: (context, index) {
                  if (index == _uploadedPhotos.length) {
                    return GestureDetector(
                      onTap: _mockAddPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.textSecondary,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Icon(
                          Icons.image,
                          color: AppColors.primary,
                          size: 36,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap:
                                () => setState(
                                  () => _uploadedPhotos.removeAt(index),
                                ),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Submit requirements check
              _RequirementRow(
                label: 'Quantity entered',
                met: _quantityController.text.isNotEmpty,
              ),
              _RequirementRow(
                label: 'Price entered',
                met: _priceController.text.isNotEmpty,
              ),
              _RequirementRow(
                label: 'At least 2 photos uploaded',
                met: _uploadedPhotos.length >= 2,
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Submit Harvest Report',
                onPressed: _uploadedPhotos.length >= 2 ? _onSubmit : null,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
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
                  Icons.agriculture,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Harvest Report Submitted!',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your harvest report has been sent for verification. '
                'Investors will be notified once it is certified.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusActive,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Project', value: widget.project.title),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Total Revenue',
                      value: _formatAmount(_totalRevenue),
                    ),
                    const SizedBox(height: 8),
                    const _SummaryRow(label: 'Status', value: 'Pending Review'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Back to My Projects',
                onPressed: () => context.go('/farmer/projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: met ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: met ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(value, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

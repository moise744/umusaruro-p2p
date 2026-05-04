import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';
import 'package:umusaruro_p2p/core/widgets/app_text_field.dart';

const _provinces = [
  'Kigali City',
  'Northern Province',
  'Southern Province',
  'Eastern Province',
  'Western Province',
];

const _cropTypes = [
  'Maize',
  'Beans',
  'Potatoes',
  'Tomatoes',
  'Rice',
  'Tea',
  'Coffee',
  'Avocado',
  'Sorghum',
  'Sweet Potatoes',
  'Cassava',
  'Wheat',
];

class FarmerProfileSetupScreen extends ConsumerStatefulWidget {
  const FarmerProfileSetupScreen({super.key});

  @override
  ConsumerState<FarmerProfileSetupScreen> createState() =>
      _FarmerProfileSetupScreenState();
}

class _FarmerProfileSetupScreenState
    extends ConsumerState<FarmerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _landSizeController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedProvince;
  final Set<String> _selectedCrops = {};
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _landSizeController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one crop type')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) context.go(AppRoutes.pendingVerification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Farm Profile', style: AppTextStyles.headingMedium),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(2, (i) {
                  final active = i <= _currentStep;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i == 0 ? 6 : 0,
                        left: i == 1 ? 6 : 0,
                      ),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child:
                  _currentStep == 0
                      ? PrimaryButton(
                        label: 'Next',
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              _selectedProvince != null) {
                            setState(() => _currentStep = 1);
                          } else if (_selectedProvince == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select your province'),
                              ),
                            );
                          }
                        },
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _currentStep = 0),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Submit',
                              onPressed: _onSubmit,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Farm Location', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Tell us about where your farm is located.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // Province dropdown
        const Text('Province', style: AppTextStyles.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedProvince,
          decoration: InputDecoration(
            hintText: 'Select province',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items:
              _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
          onChanged: (v) => setState(() => _selectedProvince = v),
        ),
        const SizedBox(height: 16),

        AppTextField(
          label: 'Sector / Cell / Village',
          hint: 'e.g. Remera Sector, Rukiri Cell',
          controller: _locationController,
          validator:
              (v) =>
                  v == null || v.isEmpty ? 'Please enter your location' : null,
        ),
        const SizedBox(height: 16),

        AppTextField(
          label: 'Total Land Size (hectares)',
          hint: 'e.g. 2.5',
          controller: _landSizeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            final n = double.tryParse(v);
            if (n == null || n <= 0) return 'Enter valid land size';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Crops & Bio', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Select the crops you grow and add a short bio.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        const Text('Crops You Grow', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _cropTypes.map((crop) {
                final selected = _selectedCrops.contains(crop);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedCrops.remove(crop);
                      } else {
                        _selectedCrops.add(crop);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      crop,
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 24),

        AppTextField(
          label: 'Short Bio (Optional)',
          hint: 'e.g. I have been farming for 10 years in Eastern Province...',
          controller: _bioController,
          maxLines: 4,
        ),
      ],
    );
  }
}

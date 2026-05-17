import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/app_text_field.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final _capitalController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _projectTypeController = TextEditingController();
  String _landOwnershipType = 'lease';
  File? _landDocument;
  File? _projectImage;
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    _capitalController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _projectTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _landDocument = File(path));
    }
  }

  Future<void> _pickProjectImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _projectImage = File(path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(projectApiServiceProvider)
          .createProject(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            landOwnershipType: _landOwnershipType,
            landDocument: _landDocument,
            province: _provinceController.text.trim(),
            district: _districtController.text.trim(),
            sector: _sectorController.text.trim(),
            cell: _cellController.text.trim(),
            projectType: _projectTypeController.text.trim(),
            capitalNeeded: double.tryParse(_capitalController.text.trim()),
            latitude: double.tryParse(_latitudeController.text.trim()),
            longitude: double.tryParse(_longitudeController.text.trim()),
            projectImage: _projectImage,
          );

      if (!mounted) return;
      context.go(AppRoutes.myProjects);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Project Details', style: AppTextStyles.headingSmall),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Title',
                hint: 'Seasonal Maize Farm',
                controller: _titleController,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Explain the project, goals, and expected impact.',
                controller: _descriptionController,
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Location',
                hint: 'Musanze, Northern Province',
                controller: _locationController,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Province',
                      hint: 'Northern Province',
                      controller: _provinceController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'District',
                      hint: 'Musanze',
                      controller: _districtController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Sector',
                      hint: 'Busogo',
                      controller: _sectorController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Cell',
                      hint: 'Ruhengeri',
                      controller: _cellController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      hint: '-1.5',
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.-]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      hint: '29.6',
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.-]')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Project Type',
                hint: 'Maize',
                controller: _projectTypeController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Capital Needed',
                hint: '2500000',
                controller: _capitalController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Land Ownership Type',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lease', label: Text('Lease')),
                  ButtonSegment(value: 'owned', label: Text('Owned')),
                ],
                selected: {_landOwnershipType},
                onSelectionChanged: (value) {
                  setState(() => _landOwnershipType = value.first);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Land Document'),
                subtitle: Text(
                  _landDocument?.path.split('\\').last ?? 'Optional',
                ),
                trailing: OutlinedButton(
                  onPressed: _pickDocument,
                  child: const Text('Pick File'),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Project Image'),
                subtitle: Text(
                  _projectImage?.path.split('\\').last ?? 'Optional',
                ),
                trailing: OutlinedButton(
                  onPressed: _pickProjectImage,
                  child: const Text('Pick Image'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Submit Project',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

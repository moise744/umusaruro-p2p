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
  final _capitalController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _projectTypeController = TextEditingController(text: 'Maize');
  String _landOwnershipType = 'lease';
  File? _landDocument;
  File? _projectImage;
  String? _error;
  bool _isLoading = false;

  // Cascading location datasets
  String _selectedProvince = 'Northern Province';
  String _selectedDistrict = 'Musanze';
  String _selectedSector = 'Busogo';
  String _selectedCell = 'Ruhengeri';

  final List<String> _provinces = ['Kigali City', 'Northern Province', 'Southern Province', 'Eastern Province', 'Western Province'];

  final Map<String, List<String>> _districtsByProvince = {
    'Kigali City': ['Nyarugenge', 'Gasabo', 'Kicukiro'],
    'Northern Province': ['Musanze', 'Burera', 'Gicumbi', 'Rulindo', 'Gakenke'],
    'Southern Province': ['Huye', 'Nyanza', 'Gisagara', 'Nyamagabe', 'Ruhango', 'Muhanga', 'Kamonyi', 'Nyaruguru'],
    'Eastern Province': ['Rwamagana', 'Bugesera', 'Kayonza', 'Gatsibo', 'Nyagatare', 'Kirehe', 'Ngoma'],
    'Western Province': ['Rubavu', 'Karongi', 'Rusizi', 'Nyamasheke', 'Rutsiro', 'Ngororero', 'Nyabihu'],
  };

  final Map<String, List<String>> _sectorsByDistrict = {
    'Musanze': ['Busogo', 'Cyuve', 'Gataraga', 'Muhoza', 'Kinigi'],
    'Burera': ['Cyeru', 'Gahunga', 'Gatebe'],
    'Huye': ['Mbazi', 'Tumba', 'Ngoma', 'Mukura'],
    'Nyamagabe': ['Gasaka', 'Tare', 'Kitabi'],
    'Nyarugenge': ['Kanyinya', 'Kigali', 'Nyamirambo'],
    'Gasabo': ['Kinyinya', 'Gisozi', 'Ndera'],
    'Rwamagana': ['Fumbwe', 'Gishari', 'Karenge'],
    'Bugesera': ['Nyamata', 'Gashora', 'Mayange'],
    'Rubavu': ['Gisenyi', 'Rugerero', 'Nyamyumba'],
    'Nyamasheke': ['Kagano', 'Bushekeri', 'Shangi'],
  };

  final Map<String, List<String>> _cellsBySector = {
    'Busogo': ['Ruhengeri', 'Gisesero', 'Sahara'],
    'Muhoza': ['Mpenge', 'Kigombe', 'Ruhengeri'],
    'Tumba': ['Gitwa', 'Cyarwa', 'Rango'],
    'Nyamata': ['Nyamata Ville', 'Kanazi', 'Murama'],
    'Gisozi': ['Ruhango', 'Musezero'],
    'Gishari': ['Bwiza', 'Shywa'],
    'Gisenyi': ['Nengo', 'Mbugangari'],
  };

  // AI yield estimation inputs
  double _hectares = 1.0;
  String _soilType = 'Volcanic';
  double _estimatedYield = 3.5;
  double _estimatedRevenue = 3250000;

  @override
  void initState() {
    super.initState();
    _projectTypeController.addListener(_updateAIPrediction);
    _capitalController.addListener(_updateAIPrediction);
    _locationController.text = 'Busogo, Musanze, Northern Province';
  }

  void _updateAIPrediction() {
    double baseYieldPerHectare = 3.0;
    final crop = _projectTypeController.text.trim().toLowerCase();
    if (crop.contains('coffee')) {
      baseYieldPerHectare = 4.2;
    } else if (crop.contains('maize')) {
      baseYieldPerHectare = 3.5;
    } else if (crop.contains('potato')) {
      baseYieldPerHectare = 5.0;
    }

    double soilMultiplier = 1.0;
    if (_soilType == 'Volcanic') {
      soilMultiplier = 1.25;
    } else if (_soilType == 'Clay') {
      soilMultiplier = 0.85;
    } else if (_soilType == 'Sandy') {
      soilMultiplier = 0.70;
    } else if (_soilType == 'Loam') {
      soilMultiplier = 1.10;
    }

    final capNeeded = double.tryParse(_capitalController.text.trim()) ?? 2500000;

    setState(() {
      _estimatedYield = baseYieldPerHectare * _hectares * soilMultiplier;
      _estimatedRevenue = capNeeded * 1.30;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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
            location: '$_selectedSector, $_selectedDistrict, $_selectedProvince',
            landOwnershipType: _landOwnershipType,
            landDocument: _landDocument,
            province: _selectedProvince,
            district: _selectedDistrict,
            sector: _selectedSector,
            cell: _selectedCell,
            projectType: _projectTypeController.text.trim(),
            capitalNeeded: double.tryParse(_capitalController.text.trim()),
            latitude: double.tryParse(_latitudeController.text.trim()) ?? -1.5008,
            longitude: double.tryParse(_longitudeController.text.trim()) ?? 29.6350,
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
    // Dynamically retrieve selections based on state
    final districts = _districtsByProvince[_selectedProvince] ?? [];
    if (!districts.contains(_selectedDistrict) && districts.isNotEmpty) {
      _selectedDistrict = districts.first;
    }

    final sectors = _sectorsByDistrict[_selectedDistrict] ?? [];
    if (!sectors.contains(_selectedSector) && sectors.isNotEmpty) {
      _selectedSector = sectors.first;
    }

    final cells = _cellsBySector[_selectedSector] ?? ['Centre'];
    if (!cells.contains(_selectedCell) && cells.isNotEmpty) {
      _selectedCell = cells.first;
    }

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
              
              // Province & District dropdowns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Province', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedProvince,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedProvince = val;
                                final nextDistricts = _districtsByProvince[val] ?? [];
                                _selectedDistrict = nextDistricts.isNotEmpty ? nextDistricts.first : '';
                                final nextSectors = _sectorsByDistrict[_selectedDistrict] ?? [];
                                _selectedSector = nextSectors.isNotEmpty ? nextSectors.first : '';
                                final nextCells = _cellsBySector[_selectedSector] ?? [];
                                _selectedCell = nextCells.isNotEmpty ? nextCells.first : '';
                                _locationController.text = '$_selectedSector, $_selectedDistrict, $_selectedProvince';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('District', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDistrict = val;
                                final nextSectors = _sectorsByDistrict[val] ?? [];
                                _selectedSector = nextSectors.isNotEmpty ? nextSectors.first : '';
                                final nextCells = _cellsBySector[_selectedSector] ?? [];
                                _selectedCell = nextCells.isNotEmpty ? nextCells.first : '';
                                _locationController.text = '$_selectedSector, $_selectedDistrict, $_selectedProvince';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sector & Cell dropdowns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sector', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSector,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSector = val;
                                final nextCells = _cellsBySector[val] ?? [];
                                _selectedCell = nextCells.isNotEmpty ? nextCells.first : 'Centre';
                                _locationController.text = '$_selectedSector, $_selectedDistrict, $_selectedProvince';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cell', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCell,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          items: cells.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCell = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude (Optional)',
                      hint: '-1.5008',
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
                      label: 'Longitude (Optional)',
                      hint: '29.6350',
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
              const SizedBox(height: 20),

              // AI Predictor confidence bar & calculator on-device widget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'AI Yield Prediction Calculator',
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('92% Confidence', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Land Area (Hectares)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<double>(
                                value: _hectares,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                items: const [
                                  DropdownMenuItem(value: 0.5, child: Text('0.5 Hectare', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 1.0, child: Text('1.0 Hectare', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 2.0, child: Text('2.0 Hectares', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 5.0, child: Text('5.0 Hectares', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _hectares = val;
                                      _updateAIPrediction();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Soil Type', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _soilType,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                items: const [
                                  DropdownMenuItem(value: 'Volcanic', child: Text('Volcanic Soil', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Loam', child: Text('Loam Soil', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Clay', child: Text('Clay Soil', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Sandy', child: Text('Sandy Soil', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _soilType = val;
                                      _updateAIPrediction();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated Yield', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('${_estimatedYield.toStringAsFixed(1)} Tons', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Expected Revenue', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('RWF ${_estimatedRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Land Ownership Type',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _landOwnershipType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'lease', child: Text('Lease')),
                  DropdownMenuItem(value: 'owned', child: Text('Owned')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _landOwnershipType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Land Document picker
              const Text('Land Document', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _landDocument?.path.split('\\').last ?? 'No file chosen (Optional)',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _pickDocument,
                    child: const Text('Pick File'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Project Image picker
              const Text('Project Image', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _projectImage?.path.split('\\').last ?? 'No image chosen (Optional)',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _pickProjectImage,
                    child: const Text('Pick Image'),
                  ),
                ],
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

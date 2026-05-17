import 'package:flutter/material.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';

class ProjectApiService {
  static final List<MockProject> _projects = [...mockProjects];

  Future<List<MockProject>> getMyProjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List<MockProject>.unmodifiable(_projects);
  }

  Future<MockProject> getProjectById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _projects.firstWhere(
      (project) => project.id == id,
      orElse: () => mockProjects.first,
    );
  }

  Future<void> createProject({
    required String title,
    required String description,
    required String location,
    required String landOwnershipType,
    dynamic landDocument,
    String? province,
    String? district,
    String? sector,
    String? cell,
    String? projectType,
    double? latitude,
    double? longitude,
    double? capitalNeeded,
    dynamic projectImage,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final cropType =
        projectType != null && projectType.trim().isNotEmpty
            ? projectType.trim()
            : 'Crop';
    final locationParts = <String>[
      if (sector != null && sector.isNotEmpty) sector,
      if (district != null && district.isNotEmpty) district,
      if (province != null && province.isNotEmpty) province,
    ];

    _projects.insert(
      0,
      MockProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        farmerName: 'You',
        cropType: cropType,
        location:
            locationParts.isNotEmpty ? locationParts.join(', ') : location,
        targetAmount: capitalNeeded ?? 0,
        raisedAmount: 0,
        returnRate: 0,
        durationMonths: 0,
        status: 'pending',
        imageIcon: _iconForCrop(cropType),
      ),
    );
  }

  Future<void> approveProject(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _projects.indexWhere((project) => project.id == id);
    if (index == -1) return;

    final project = _projects[index];
    _projects[index] = MockProject(
      id: project.id,
      title: project.title,
      farmerName: project.farmerName,
      cropType: project.cropType,
      location: project.location,
      targetAmount: project.targetAmount,
      raisedAmount: project.raisedAmount,
      returnRate: project.returnRate,
      durationMonths: project.durationMonths,
      status: 'active',
      imageIcon: project.imageIcon,
    );
  }

  IconData _iconForCrop(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'coffee':
        return Icons.local_cafe;
      case 'avocado':
        return Icons.local_florist;
      case 'potatoes':
      case 'irish potato':
        return Icons.agriculture;
      case 'rice':
        return Icons.grass;
      default:
        return Icons.eco;
    }
  }
}

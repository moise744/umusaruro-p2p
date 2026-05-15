import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/network/api_client.dart';

class ProjectApiService {
  final Dio _dio;

  ProjectApiService(ApiClient client) : _dio = client.dio;

  Future<List<MockProject>> getMyProjects() async {
    final response = await _dio.get('/projects/my');
    final items = _extractList(response.data);
    return items.map((item) => _toProject(_extractMap(item))).toList();
  }

  Future<MockProject> getProjectById(String id) async {
    final response = await _dio.get('/projects/$id');
    return _toProject(_extractMap(response.data));
  }

  Future<void> createProject({
    required String title,
    required String description,
    required String location,
    required String landOwnershipType,
    required File landDocument,
    String? province,
    String? district,
    String? sector,
    String? cell,
    String? projectType,
    double? latitude,
    double? longitude,
    double? capitalNeeded,
    File? projectImage,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'location': location,
      'landOwnershipType': landOwnershipType,
      if (province != null && province.isNotEmpty) 'province': province,
      if (district != null && district.isNotEmpty) 'district': district,
      if (sector != null && sector.isNotEmpty) 'sector': sector,
      if (cell != null && cell.isNotEmpty) 'cell': cell,
      if (projectType != null && projectType.isNotEmpty)
        'projectType': projectType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (capitalNeeded != null) 'capitalNeeded': capitalNeeded,
      'landDocument': await MultipartFile.fromFile(landDocument.path),
      if (projectImage != null)
        'projectImage': await MultipartFile.fromFile(projectImage.path),
    });

    await _dio.post('/projects', data: formData);
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final items = data['data'];
      if (items is List) return items;
      final projects = data['projects'];
      if (projects is List) return projects;
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  MockProject _toProject(Map<String, dynamic> json) {
    final cropType =
        _string(json['cropType']) ?? _string(json['projectType']) ?? 'Crop';
    return MockProject(
      id: _string(json['id']) ?? _string(json['_id']) ?? '',
      title:
          _string(json['title']) ?? _string(json['name']) ?? 'Untitled Project',
      farmerName:
          _string(json['farmerName']) ??
          _string(json['ownerName']) ??
          _string(json['creatorName']) ??
          'Farmer',
      cropType: cropType,
      location:
          _string(json['location']) ??
          [
            _string(json['sector']),
            _string(json['district']),
            _string(json['province']),
          ].whereType<String>().join(', '),
      targetAmount:
          _number(json['targetAmount']) ?? _number(json['capitalNeeded']) ?? 0,
      raisedAmount:
          _number(json['raisedAmount']) ?? _number(json['fundedAmount']) ?? 0,
      returnRate: _number(json['returnRate']) ?? 0,
      durationMonths: _int(json['durationMonths']) ?? 0,
      status: _string(json['status'])?.toLowerCase() ?? 'pending',
      imageIcon: _iconForCrop(cropType),
    );
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  double? _number(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
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

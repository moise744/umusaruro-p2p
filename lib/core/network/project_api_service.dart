import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';

class ProjectApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MockProject>> getMyProjects() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('projects')
          .select('*, users!farmer_id(full_name, location)')
          .eq('farmer_id', currentUserId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => _mapToMockProject(json)).toList();
    } catch (e) {
      debugPrint('Error fetching my projects: $e');
      return [];
    }
  }

  Future<List<MockProject>> getAllProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, users!farmer_id(full_name, location)')
          .order('created_at', ascending: false);
      return (response as List).map((json) => _mapToMockProject(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all projects: $e');
      return [];
    }
  }

  Future<MockProject> getProjectById(String id) async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, users!farmer_id(full_name, location)')
          .eq('id', id)
          .single();
      return _mapToMockProject(response);
    } catch (e) {
      debugPrint('Error fetching project by id: $e');
      throw Exception('Project not found: $e');
    }
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
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not logged in');

      final cropType = projectType != null && projectType.trim().isNotEmpty ? projectType.trim() : 'Crop';
      final locationParts = <String>[
        if (sector != null && sector.isNotEmpty) sector,
        if (district != null && district.isNotEmpty) district,
        if (province != null && province.isNotEmpty) province,
      ];
      final finalLocation = locationParts.isNotEmpty ? locationParts.join(', ') : location;

      await _supabase.from('projects').insert({
        'farmer_id': currentUserId,
        'title': title,
        'description': description,
        'category': cropType,
        'target_amount': capitalNeeded ?? 0,
        'current_amount': 0,
        'status': 'funding',
        'return_rate': 15.0,
        'duration_months': 6,
        'risk_level': 'Medium',
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      debugPrint('Error creating project: $e');
      rethrow;
    }
  }

  Future<void> approveProject(String id) async {
    try {
      await _supabase.from('projects').update({'status': 'active'}).eq('id', id);
    } catch (e) {
      debugPrint('Error approving project: $e');
    }
  }

  MockProject _mapToMockProject(Map<String, dynamic> json) {
    final userMap = json['users'] as Map<String, dynamic>?;
    final farmerName = userMap?['full_name'] as String? ?? 'Unknown';
    final location = userMap?['location'] as String? ?? 'Rwanda';

    return MockProject(
      id: json['id'] as String,
      title: json['title'] as String,
      farmerName: farmerName,
      cropType: json['category'] as String? ?? 'Crop',
      location: location,
      targetAmount: (json['target_amount'] as num? ?? 0).toDouble(),
      raisedAmount: (json['current_amount'] as num? ?? 0).toDouble(),
      returnRate: (json['return_rate'] as num? ?? 0).toDouble(),
      durationMonths: (json['duration_months'] as num? ?? 6).toInt(),
      status: json['status'] as String? ?? 'funding',
      imageIcon: _iconForCrop(json['category'] as String? ?? ''),
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
      case 'tea':
        return Icons.local_cafe;
      default:
        return Icons.eco;
    }
  }
}

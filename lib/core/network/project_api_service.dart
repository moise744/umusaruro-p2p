import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';

class ProjectApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MockProject>> getMyProjects() async {
    try {
      final response = await _supabase.from('projects').select().order('created_at', ascending: false);
      return (response as List).map((json) => _mapToMockProject(json)).toList();
    } catch (e) {
      print('Error fetching projects: \$e');
      return [];
    }
  }

  Future<MockProject> getProjectById(String id) async {
    try {
      final response = await _supabase.from('projects').select().eq('id', id).single();
      return _mapToMockProject(response);
    } catch (e) {
      print('Error fetching project by id: \$e');
      throw Exception('Project not found');
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
      final cropType = projectType != null && projectType.trim().isNotEmpty ? projectType.trim() : 'Crop';
      final locationParts = <String>[
        if (sector != null && sector.isNotEmpty) sector,
        if (district != null && district.isNotEmpty) district,
        if (province != null && province.isNotEmpty) province,
      ];
      final finalLocation = locationParts.isNotEmpty ? locationParts.join(', ') : location;

      await _supabase.from('projects').insert({
        'title': title,
        'description': description,
        'category': cropType,
        'target_amount': capitalNeeded ?? 0,
        'status': 'pending',
        'return_rate': 15.0, // Default for now
        'duration_months': 6, // Default for now
        'risk_level': 'Medium', // Default for now
        'latitude': latitude,
        'longitude': longitude,
        // Optional: Assuming the user is authenticated and we have their farmer_id.
        // For now, if no auth, this might fail unless policies are disabled.
      });
    } catch (e) {
      print('Error creating project: \$e');
      throw e;
    }
  }

  Future<void> approveProject(String id) async {
    try {
      await _supabase.from('projects').update({'status': 'active'}).eq('id', id);
    } catch (e) {
      print('Error approving project: \$e');
    }
  }

  MockProject _mapToMockProject(Map<String, dynamic> json) {
    return MockProject(
      id: json['id'] as String,
      title: json['title'] as String,
      farmerName: 'Kagabo Jean', // Assuming a join with users table could get this
      cropType: json['category'] as String,
      location: 'Musanze', // Or derive from lat/long if location isn't a column
      targetAmount: (json['target_amount'] as num).toDouble(),
      raisedAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      returnRate: (json['return_rate'] as num?)?.toDouble() ?? 0,
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'funding',
      imageIcon: _iconForCrop(json['category'] as String),
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

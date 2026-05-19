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
          .select('*, users!farmer_id(full_name, location_district)')
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
          .select('*, users!farmer_id(full_name, location_district)')
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
          .select('*, users!farmer_id(full_name, location_district)')
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

      final cropType = projectType != null && projectType.trim().isNotEmpty ? projectType.trim() : 'MAIZE';
      
      await _supabase.from('projects').insert({
        'farmer_id': currentUserId,
        'title': title,
        'crop_type': cropType.toUpperCase(),
        'season': 'A',
        'verification_note': description,
        'funding_goal': capitalNeeded ?? 0.0,
        'funding_raised': 0.0,
        'expected_return_percent': 15.0,
        'status': 'PENDING_VERIFICATION',
        'location_district': district ?? 'Musanze',
        'location_sector': sector ?? 'Busogo',
        'location_cell': cell ?? 'Ruhengeri',
        'gps_lat': latitude ?? -1.503,
        'gps_lng': longitude ?? 29.635,
      });
    } catch (e) {
      debugPrint('Error creating project: $e');
      rethrow;
    }
  }

  Future<void> approveProject(String id) async {
    try {
      await _supabase.from('projects').update({'status': 'ACTIVE'}).eq('id', id);
    } catch (e) {
      debugPrint('Error approving project: $e');
    }
  }

  Future<void> submitHarvest(String id, double quantity, double price) async {
    try {
      await _supabase.from('projects').update({
        'status': 'COMPLETED',
        'harvest_yield_kg': quantity,
        'harvest_revenue': price * quantity,
      }).eq('id', id);
    } catch (e) {
      debugPrint('Error submitting harvest: $e');
      rethrow;
    }
  }

  Future<void> investInProject(String projectId, double amount) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not logged in');

      // Insert investment record
      await _supabase.from('investments').insert({
        'project_id': projectId,
        'investor_id': currentUserId,
        'amount_invested': amount,
        'status': 'ACTIVE',
      });

      // Update project funding_raised
      final projectData = await _supabase.from('projects').select('funding_raised').eq('id', projectId).single();
      final currentAmount = (projectData['funding_raised'] as num?)?.toDouble() ?? 0;
      await _supabase.from('projects').update({
        'funding_raised': currentAmount + amount,
      }).eq('id', projectId);

    } catch (e) {
      debugPrint('Error investing in project: $e');
      rethrow;
    }
  }

  MockProject _mapToMockProject(Map<String, dynamic> json) {
    final userMap = json['users'] as Map<String, dynamic>?;
    final farmerName = userMap?['full_name'] as String? ?? 'Unknown';
    final location = userMap?['location_district'] as String? ?? 'Musanze';

    return MockProject(
      id: json['id'] as String,
      title: json['title'] as String,
      farmerName: farmerName,
      cropType: json['crop_type'] as String? ?? 'Crop',
      location: location,
      targetAmount: (json['funding_goal'] as num? ?? 0).toDouble(),
      raisedAmount: (json['funding_raised'] as num? ?? 0).toDouble(),
      returnRate: (json['expected_return_percent'] as num? ?? 0).toDouble(),
      durationMonths: 6,
      status: json['status'] as String? ?? 'DRAFT',
      imageIcon: _iconForCrop(json['crop_type'] as String? ?? ''),
      latitude: json['gps_lat'] != null ? (json['gps_lat'] as num).toDouble() : null,
      longitude: json['gps_lng'] != null ? (json['gps_lng'] as num).toDouble() : null,
    );
  }

  IconData _iconForCrop(String cropType) {
    switch (cropType.toLowerCase()) {
      case 'coffee':
        return Icons.local_cafe;
      case 'avocado':
        return Icons.local_florist;
      case 'potatoes':
      case 'potato':
      case 'potatoes':
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

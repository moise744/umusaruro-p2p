import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Build dynamic notifications from investments and projects
    final List<Map<String, dynamic>> items = [];

    try {
      // Check investments for this user
      final investments = await _supabase
          .from('investments')
          .select('*, projects(title, category)')
          .eq('investor_id', userId)
          .order('created_at', ascending: false);

      for (final inv in investments as List) {
        final project = inv['projects'] as Map<String, dynamic>?;
        items.add({
          'title': 'Investment Confirmed',
          'body': 'Your investment in "${project?['title'] ?? 'a project'}" has been confirmed.',
          'time': _formatTime(inv['created_at'] as String),
          'type': 'investment',
          'isRead': true,
        });
      }

      // Check user's own projects (farmer)
      final projects = await _supabase
          .from('projects')
          .select('title, status, created_at')
          .eq('farmer_id', userId)
          .order('created_at', ascending: false);

      for (final p in projects as List) {
        final status = p['status'] as String;
        String title = 'Project Created';
        String body = 'Your project "${p['title']}" has been created.';
        if (status == 'active') {
          title = 'Project Active';
          body = 'Your project "${p['title']}" is now active.';
        } else if (status == 'completed') {
          title = 'Project Completed';
          body = 'Your project "${p['title']}" has been completed.';
        }
        items.add({
          'title': title,
          'body': body,
          'time': _formatTime(p['created_at'] as String),
          'type': 'harvest',
          'isRead': false,
        });
      }

      // Add a static welcome notification
      items.add({
        'title': 'Welcome to Umusaruro P2P!',
        'body': 'Your account has been verified. Start exploring projects or create your own.',
        'time': 'When you registered',
        'type': 'verification',
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'investment': return Icons.trending_up;
      case 'harvest': return Icons.agriculture;
      case 'verification': return Icons.verified_user;
      case 'funding': return Icons.account_balance_wallet;
      default: return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'investment': return AppColors.primary;
      case 'harvest': return AppColors.secondary;
      case 'verification': return AppColors.info;
      case 'funding': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadNotifications();
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('No notifications yet.', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final color = _colorForType(n['type'] as String);
                    final isRead = n['isRead'] as bool;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: isRead ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_iconForType(n['type'] as String), color: color, size: 20),
                        ),
                        title: Text(n['title'] as String, style: AppTextStyles.labelLarge),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(n['body'] as String, style: AppTextStyles.bodySmall),
                            const SizedBox(height: 4),
                            Text(n['time'] as String, style: AppTextStyles.caption),
                          ],
                        ),
                        trailing: !isRead
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  String _fullName = 'Loading...';
  String _role = '';
  String _location = 'Not provided';
  String _kycStatus = 'PENDING';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    _email = _supabase.auth.currentUser?.email ?? '';
    if (currentUserId == null) return;

    try {
      final response = await _supabase
          .from('users')
          .select('full_name, role, location_district, kyc_status')
          .eq('id', currentUserId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _fullName = response['full_name'] as String? ?? 'Unknown';
          _role = (response['role'] as String? ?? '').replaceAll('_', ' ');
          _location = response['location_district'] as String? ?? 'Not provided';
          _kycStatus = response['kyc_status'] as String? ?? 'PENDING';
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We will send a password reset link to your email.'),
            const SizedBox(height: 12),
            Text(_email, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _supabase.auth.resetPasswordForEmail(_email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Password reset email sent! Check your inbox.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showKYCDialog() {
    File? kycFront;
    File? kycBack;
    bool kycSubmitted = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Text('KYC Verification', style: AppTextStyles.headingSmall),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Upload your Front and Back National ID or Passport to verify your investor account.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              if (kycSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Documents Uploaded!', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Your identity verification is currently being reviewed. This usually takes 1-2 hours.', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                const Text('Front Side of ID card', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(type: FileType.image, withData: false);
                    final path = result?.files.single.path;
                    if (path != null) {
                      setDialogState(() => kycFront = File(path));
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: kycFront != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '📷 ${kycFront!.path.split('\\').last}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.textHint, size: 24),
                              SizedBox(height: 4),
                              Text('Select Front Image', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Back Side of ID card', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(type: FileType.image, withData: false);
                    final path = result?.files.single.path;
                    if (path != null) {
                      setDialogState(() => kycBack = File(path));
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: kycBack != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '📷 ${kycBack!.path.split('\\').last}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.textHint, size: 24),
                              SizedBox(height: 4),
                              Text('Select Back Image', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: kycFront != null && kycBack != null
                        ? () async {
                            final currentUserId = _supabase.auth.currentUser?.id;
                            if (currentUserId != null) {
                              try {
                                await _supabase
                                    .from('users')
                                    .update({'kyc_status': 'PENDING'})
                                    .eq('id', currentUserId);
                                _fetchProfile();
                              } catch (e) {
                                debugPrint('Error updating KYC: $e');
                              }
                            }
                            setDialogState(() {
                              kycSubmitted = true;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Verification Documents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _fullName.isNotEmpty && _fullName != 'Loading...'
        ? _fullName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_fullName, style: AppTextStyles.headingMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${_role.toUpperCase()} • $_location',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(_email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: 8),
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kycStatus == 'VERIFIED'
                          ? AppColors.statusActive
                          : _kycStatus == 'PENDING'
                              ? Colors.orange.withOpacity(0.15)
                              : AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _kycStatus == 'VERIFIED'
                          ? '✓ Verified'
                          : _kycStatus == 'PENDING'
                              ? '⌛ Pending Verification'
                              : '✗ Rejected',
                      style: AppTextStyles.caption.copyWith(
                        color: _kycStatus == 'VERIFIED'
                            ? AppColors.statusActiveText
                            : _kycStatus == 'PENDING'
                                ? Colors.orange[800]
                                : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Account Section
            _Section(title: 'Account', items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                  if (updated == true) _fetchProfile();
                },
              ),
              _MenuItem(
                icon: Icons.verified_user_outlined,
                label: 'Investor KYC Verification',
                onTap: _showKYCDialog,
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                label: 'Security / Change Password',
                onTap: _changePassword,
              ),
              _MenuItem(
                icon: Icons.language,
                label: 'Language',
                trailing: 'Kinyarwanda',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => SimpleDialog(
                      title: const Text('Select Language'),
                      children: ['Kinyarwanda', 'English', 'Français'].map((lang) {
                        return SimpleDialogOption(
                          child: Text(lang),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Language set to $lang')),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Notifications'),
                      content: const Text('Push notifications will be sent for new messages, investments, and harvest updates.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                      ],
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 8),

            // Support Section
            _Section(title: 'Support', items: [
              _MenuItem(
                icon: Icons.help_outline,
                label: 'Help & FAQ',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Help & FAQ'),
                      content: const SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q: How do I invest?', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('A: Browse projects and tap Invest on any project card.'),
                            SizedBox(height: 8),
                            Text('Q: How do I receive money?', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('A: Funds are transferred to your registered mobile money account after the funding target is met.'),
                            SizedBox(height: 8),
                            Text('Q: Who can I contact for help?', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('A: Email us at support@umusaruro.rw'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.chat_bubble_outline,
                label: 'Contact Support',
                onTap: () async {
                  final uri = Uri(scheme: 'mailto', path: 'support@umusaruro.rw', query: 'subject=Support Request');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email: support@umusaruro.rw')),
                      );
                    }
                  }
                },
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Umusaruro P2P is committed to protecting your privacy.\n\n'
                          '• We collect your name, email, and project data only to provide our service.\n'
                          '• Your data is stored securely on Supabase servers.\n'
                          '• We never sell your personal information to third parties.\n'
                          '• You may request deletion of your account at any time by contacting support.\n\n'
                          'For more information, contact: support@umusaruro.rw',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 8),

            // Logout
            Padding(
              padding: const EdgeInsets.all(24),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _supabase.auth.signOut();
                  final secureStorage = ref.read(secureStorageServiceProvider);
                  await secureStorage.clearAll();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text('Logout', style: AppTextStyles.button.copyWith(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textHint)),
          ),
          ...items,
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: trailing != null
          ? Text(trailing!, style: AppTextStyles.bodySmall)
          : const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final user = auth.user;
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Account',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile Header ──
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: BrandColors.gold,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF5D4037),
                    child: Text(
                      _initials(profile?.displayName ?? user?.displayName ?? '?'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: BrandColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.displayName ?? user?.displayName ?? 'User',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    color: BrandColors.brownMid,
                  ),
                ),
                if (profile?.isAdmin == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrandColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BrandColors.gold),
                    ),
                    child: Text('Admin',
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.gold,
                        )),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Account Info ──
          _sectionTitle('Account', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Display Name'),
                  subtitle: Text(
                      profile?.displayName ?? user?.displayName ?? 'Not set'),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _editName(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Member Since'),
                  subtitle: Text(profile != null
                      ? _formatDate(profile.createdAt)
                      : 'Unknown'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Data Sync ──
          _sectionTitle('Data & Sync', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Sync Bookmarks & Notes'),
                  subtitle: const Text('Coming soon — backup to cloud'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: false,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Coming soon — restore from cloud'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Security ──
          _sectionTitle('Security', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changePassword(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Sign Out ──
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text('Sign Out',
                  style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _editName(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(authProvider).profile?.displayName ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Name', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.lora(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(authProvider.notifier).updateProfile(displayName: name);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: BrandColors.gold),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context, WidgetRef ref) {
    final email = ref.read(authProvider).user?.email;
    if (email != null) {
      ref.read(authProvider.notifier).resetPassword(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

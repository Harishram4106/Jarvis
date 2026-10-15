import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../models/app_models.dart';
import '../../../../services/providers.dart';

/// One dialog for all three profile fields — three separate editors would be
/// three times the code for the same two taps.
Future<void> _editProfile(
    BuildContext context, WidgetRef ref, UserProfile current) async {
  final name = TextEditingController(text: current.name);
  final tagline = TextEditingController(text: current.tagline);
  final email = TextEditingController(text: current.email);

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: tagline,
              decoration: const InputDecoration(labelText: 'Tagline'),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (saved != true) return;

  await ref.read(userRepositoryProvider).updateProfile(UserProfile(
        name: name.text.trim(),
        tagline: tagline.text.trim(),
        email: email.text.trim(),
      ));
  ref.invalidate(userProfileProvider);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull ??
        const UserProfile(name: '', tagline: '', email: '');
    final conversations =
        ref.watch(conversationsProvider).valueOrNull?.length ?? 0;
    final saved = ref.watch(savedItemsProvider).valueOrNull?.length ?? 0;
    final facts = ref.watch(memoriesProvider).length;
    final initial =
        profile.name.trim().isEmpty ? '?' : profile.name.trim()[0].toUpperCase();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editProfile(context, ref, profile),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceHighlight,
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.displayMedium.copyWith(color: AppColors.primaryCyan),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Name and Title
              Text(profile.name, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Text(profile.tagline, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: AppSpacing.md),
              Text(profile.email, style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(value: '$conversations', label: 'Chats'),
                  _StatItem(value: '$saved', label: 'Saved'),
                  _StatItem(value: '$facts', label: 'Facts'),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xxxl),
              
              // List Options
              JarvisCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileListTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () => _editProfile(context, ref, profile)),
                    const Divider(height: 1),
                    _ProfileListTile(icon: Icons.history, title: 'History', onTap: () => context.push('/history')),
                    const Divider(height: 1),
                    _ProfileListTile(icon: Icons.bookmark_border, title: 'Saved', onTap: () => context.push('/saved')),
                    const Divider(height: 1),
                    _ProfileListTile(icon: Icons.psychology_outlined, title: 'Knowledge Base', onTap: () => context.push('/knowledge')),
                    const Divider(height: 1),
                    _ProfileListTile(icon: Icons.settings_outlined, title: 'Preferences', onTap: () => context.push('/settings')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileListTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTypography.bodyLarge),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

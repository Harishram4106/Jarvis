import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../models/app_models.dart';
import '../../../../repositories/openrouter_repository.dart';
import '../../../../repositories/tools.dart';
import '../../../../services/providers.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Writes the key main() reads back on the next launch; the provider update
/// makes it take effect now (aiRepositoryProvider watches it).
Future<void> _editApiKey(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController(text: ref.read(apiKeyProvider) ?? '');
  final key = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('OpenRouter API key'),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        decoration: const InputDecoration(hintText: 'sk-or-...'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (key == null) return;

  if (key.isEmpty) {
    await _storage.delete(key: apiKeyStorageKey);
  } else {
    await _storage.write(key: apiKeyStorageKey, value: key);
  }
  ref.read(apiKeyProvider.notifier).state = key.isEmpty ? null : key;
}

/// Only free models are ever offered — [freeModels] filters on price, and
/// [isFree] is the offline backstop if that list can't be fetched.
Future<void> _pickModel(BuildContext context, WidgetRef ref) async {
  final current = ref.read(modelProvider);
  final chosen = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => FutureBuilder<List<FreeModel>>(
      future: OpenRouterAiRepository.freeModels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textTertiary),
                ),
              ),
            ),
          );
        }
        final models = snapshot.data ?? const <FreeModel>[];
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: models.length,
            itemBuilder: (context, i) => ListTile(
              onTap: () => Navigator.pop(sheetContext, models[i].id),
              title: Text(models[i].name, style: AppTypography.bodyMedium),
              subtitle: Text(
                models[i].id,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
              trailing: models[i].id == current
                  ? const Icon(Icons.check, color: AppColors.primaryCyan)
                  : null,
            ),
          ),
        );
      },
    ),
  );
  if (chosen == null || !OpenRouterAiRepository.isFree(chosen)) return;

  await _storage.write(key: modelStorageKey, value: chosen);
  ref.read(modelProvider.notifier).state = chosen;
}

Future<void> _pickTextSize(BuildContext context, WidgetRef ref) async {
  final current = ref.read(fontSizeProvider);
  final chosen = await showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Chat text size'),
      children: [
        for (final (i, label) in ['Small', 'Medium', 'Large'].indexed)
          ListTile(
            onTap: () => Navigator.pop(dialogContext, i),
            title: Text(label),
            trailing: i == current
                ? const Icon(Icons.check, color: AppColors.primaryCyan)
                : null,
          ),
      ],
    ),
  );
  if (chosen == null) return;

  await ref.read(prefsStoreProvider).setFontSize(chosen);
  ref.read(fontSizeProvider.notifier).state = chosen;
}

Future<void> _editSystemPrompt(BuildContext context, WidgetRef ref) async {
  final controller =
      TextEditingController(text: ref.read(systemPromptProvider));
  final prompt = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('System prompt'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Extra instructions added to every conversation',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (prompt == null) return;

  await ref.read(prefsStoreProvider).setSystemPrompt(prompt);
  ref.read(systemPromptProvider.notifier).state = prompt;
}

/// Voices the platform actually has; empty on a device with no TTS data.
Future<void> _pickVoice(BuildContext context, WidgetRef ref) async {
  final raw = await FlutterTts().getVoices as List<dynamic>?;
  final names = <String>{
    for (final v in raw ?? const [])
      if (v is Map && v['name'] is String) v['name'] as String,
  }.toList()
    ..sort();

  if (!context.mounted) return;
  final current = ref.read(ttsVoiceProvider);
  final chosen = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => names.isEmpty
        ? SizedBox(
            height: 160,
            child: Center(
              child: Text(
                'No text-to-speech voices installed on this device.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
        : DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            builder: (context, scrollController) => ListView.builder(
              controller: scrollController,
              itemCount: names.length,
              itemBuilder: (context, i) => ListTile(
                onTap: () => Navigator.pop(sheetContext, names[i]),
                title: Text(names[i], style: AppTypography.bodyMedium),
                trailing: names[i] == current
                    ? const Icon(Icons.check, color: AppColors.primaryCyan)
                    : null,
              ),
            ),
          ),
  );
  if (chosen == null) return;

  await ref.read(prefsStoreProvider).setTtsVoice(chosen);
  ref.read(ttsVoiceProvider.notifier).state = chosen;
}

/// Which of the assistant's tools it may call. Disabling one drops it from
/// aiRepositoryProvider's tool list on the next message.
Future<void> _editTools(BuildContext context, WidgetRef ref) async {
  final all = buildTools(search: ref.read(webSearchProvider));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => Consumer(
      builder: (context, sheetRef, _) {
        final disabled = sheetRef.watch(disabledToolsProvider);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: all.length,
            itemBuilder: (context, i) {
              final tool = all[i];
              return SwitchListTile(
                value: !disabled.contains(tool.name),
                title: Text(tool.name.replaceAll('_', ' '),
                    style: AppTypography.bodyMedium),
                subtitle: Text(
                  tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                ),
                onChanged: (enabled) async {
                  final next = [
                    ...disabled.where((n) => n != tool.name),
                    if (!enabled) tool.name,
                  ];
                  await sheetRef.read(prefsStoreProvider).setDisabledTools(next);
                  sheetRef.read(disabledToolsProvider.notifier).state = next;
                },
              );
            },
          ),
        );
      },
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull ??
        const UserProfile(name: '', tagline: '', email: '');
    final hasKey = (ref.watch(apiKeyProvider) ?? '').isNotEmpty;
    final model = ref.watch(modelProvider);
    final textSize = ['Small', 'Medium', 'Large'][ref.watch(fontSizeProvider)];
    final voice = ref.watch(ttsVoiceProvider);
    final disabledCount = ref.watch(disabledToolsProvider).length;
    final initial =
        profile.name.trim().isEmpty ? '?' : profile.name.trim()[0].toUpperCase();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JarvisCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceHighlight,
                        border: Border.all(
                            color:
                                AppColors.primaryCyan.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: AppTypography.titleLarge
                              .copyWith(color: AppColors.primaryCyan),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name,
                              style: AppTypography.titleMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(profile.email,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              JarvisCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsListTile(
                      icon: Icons.key_outlined,
                      title: 'OpenRouter API key',
                      trailingText: hasKey ? 'Set' : 'Not set',
                      onTap: () => _editApiKey(context, ref),
                    ),
                    const Divider(height: 1),
                    _SettingsListTile(
                      icon: Icons.memory_outlined,
                      title: 'Model',
                      trailingText: model.split('/').last,
                      onTap: () => _pickModel(context, ref),
                    ),
                    const Divider(height: 1),
                    _SettingsListTile(
                      icon: Icons.text_fields,
                      title: 'Chat text size',
                      trailingText: textSize,
                      onTap: () => _pickTextSize(context, ref),
                    ),
                    const Divider(height: 1),
                    _SettingsListTile(
                      icon: Icons.tune,
                      title: 'System prompt',
                      trailingText: ref.watch(systemPromptProvider).isEmpty
                          ? 'Default'
                          : 'Custom',
                      onTap: () => _editSystemPrompt(context, ref),
                    ),
                    const Divider(height: 1),
                    _SettingsListTile(
                      icon: Icons.record_voice_over_outlined,
                      title: 'Voice',
                      trailingText: voice ?? 'Device default',
                      onTap: () => _pickVoice(context, ref),
                    ),
                    const Divider(height: 1),
                    _SettingsListTile(
                      icon: Icons.handyman_outlined,
                      title: 'Tools',
                      trailingText:
                          disabledCount == 0 ? 'All on' : '$disabledCount off',
                      onTap: () => _editTools(context, ref),
                    ),
                    const Divider(height: 1),
                    _SettingsListTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'JARVIS',
                        applicationVersion: '1.0.0',
                        children: [
                          Text(
                            'A personal assistant that runs on free OpenRouter '
                            'models. Conversations, notes and memories stay on '
                            'this device.',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
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

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTypography.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                trailingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
      onTap: onTap,
    );
  }
}

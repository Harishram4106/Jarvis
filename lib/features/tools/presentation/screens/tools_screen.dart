import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../core/widgets/glass_app_bar.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search tools...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: true),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Create'),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Analyze'),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Plan'),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(label: 'Code'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _ToolListItem(
                    icon: Icons.notes,
                    iconColor: Colors.amber,
                    title: 'Summarizer',
                    prompt: 'Summarise this for me:\n\n',
                    subtitle: 'Turn long content into insights',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ToolListItem(
                    icon: Icons.image_outlined,
                    iconColor: Colors.blue,
                    title: 'Image Generator',
                    prompt: 'Describe an image I want you to help me design: ',
                    subtitle: 'Create images from ideas',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ToolListItem(
                    icon: Icons.explore_outlined,
                    iconColor: Colors.amber,
                    title: 'Research Agent',
                    prompt: 'Research this topic and cite sources: ',
                    subtitle: 'Deep research on any topic',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ToolListItem(
                    icon: Icons.description_outlined,
                    iconColor: Colors.purpleAccent,
                    title: 'Document Assistant',
                    prompt: 'Help me work through this document:\n\n',
                    subtitle: 'Read, analyze, edit documents',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ToolListItem(
                    icon: Icons.calendar_today_outlined,
                    iconColor: Colors.blueAccent,
                    title: 'Planner',
                    prompt: 'Help me plan: ',
                    subtitle: 'Plan tasks, goals and schedules',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ToolListItem(
                    icon: Icons.bar_chart,
                    iconColor: Colors.greenAccent,
                    title: 'Data Analyzer',
                    prompt: 'Analyse this data and tell me what stands out:\n\n',
                    subtitle: 'Analyze data and generate insights',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.background : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _ToolListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  /// Seed text for the chat composer — every tool is a prompt, not a screen.
  final String prompt;

  const _ToolListItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/chat?draft=${Uri.encodeQueryComponent(prompt)}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

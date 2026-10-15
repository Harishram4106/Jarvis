import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/jarvis_logo_orb.dart';
import '../../../../core/widgets/jarvis_card.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../../../models/conversation.dart';
import '../../../../services/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? initialPrompt;

  /// Text put in the composer for the user to finish, rather than sent —
  /// used by Tools, whose prompts are openings the user has to complete.
  final String? initialDraft;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.initialPrompt,
    this.initialDraft,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft?.isNotEmpty == true) {
      _controller.text = widget.initialDraft!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.conversationId != null) {
        _loadConversation();
      } else {
        ref.read(chatProvider.notifier).startNewConversation();
        if (widget.initialPrompt?.isNotEmpty == true) {
          ref.read(chatProvider.notifier).sendMessage(widget.initialPrompt!);
        }
      }
    });
  }

  Future<void> _loadConversation() async {
    final repo = ref.read(conversationRepositoryProvider);
    final conv = await repo.getConversation(widget.conversationId!);
    if (conv != null && mounted) {
      ref.read(chatProvider.notifier).setConversation(conv);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _controller.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.conversation?.messages ?? [];
    final isEmpty = messages.isEmpty && !chatState.isTyping;

    ref.listen(chatProvider, (prev, next) {
      if ((next.conversation?.messages.length ?? 0) >
          (prev?.conversation?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Chat'),
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
            Expanded(
              child: isEmpty
                  ? _ChatEmptyState(
                      onSuggestionTap: (s) {
                        ref.read(chatProvider.notifier).sendMessage(s);
                        _scrollToBottom();
                      },
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: messages.length + (chatState.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _AssistantMessage(
                            content: chatState.streamingContent ?? '',
                            isStreaming: true,
                          );
                        }
                        final message = messages[index];
                        if (message.role == MessageRole.user) {
                          return _UserMessage(content: message.content);
                        } else {
                          return _AssistantMessage(
                            content: message.content,
                            isStreaming: false,
                          );
                        }
                      },
                    ),
            ),
            // Failures used to vanish silently — every error path in
            // ChatNotifier sets state.error and nothing rendered it.
            if (chatState.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(chatProvider.notifier).retry(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            _ChatComposer(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _send,
              onStop: ref.read(chatProvider.notifier).stop,
              isTyping: chatState.isTyping,
              onVoice: () => context.push('/voice'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  final void Function(String) onSuggestionTap;

  const _ChatEmptyState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const JarvisLogoOrb(size: 140, animate: false),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'How can I help you today?',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          JarvisCard(
            onTap: () => onSuggestionTap('Explain a concept'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Text('Explain a concept', style: AppTypography.bodyMedium)),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          JarvisCard(
            onTap: () => onSuggestionTap('Give me ideas'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Text('Give me ideas', style: AppTypography.bodyMedium)),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          JarvisCard(
            onTap: () => onSuggestionTap('Write code'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Text('Write code', style: AppTypography.bodyMedium)),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Inline markdown -> spans. Models emit **bold**, *italic* and `code`
/// constantly, and a plain Text widget shows the raw asterisks.
///
/// Inline only, plus leading #/>/bullet markers cleaned up. No
/// tables, links or images — add a markdown package if replies ever need
/// block layout.
List<TextSpan> markdownSpans(String text, TextStyle base) {
  final cleaned = text
      .replaceAll(RegExp(r'^[ \t]{0,3}#{1,6}[ \t]*', multiLine: true), '')
      .replaceAll(RegExp(r'^[ \t]*>[ \t]?', multiLine: true), '')
      .replaceAllMapped(
          RegExp(r'^([ \t]*)[-*+][ \t]+', multiLine: true), (m) => '${m[1]}• ');

  // Bold is listed first so ** wins over * at the same position.
  final pattern = RegExp(r'\*\*(.+?)\*\*|\*([^*\n]+)\*|`([^`]+)`', dotAll: true);
  final spans = <TextSpan>[];
  var i = 0;
  for (final m in pattern.allMatches(cleaned)) {
    if (m.start > i) {
      spans.add(TextSpan(text: cleaned.substring(i, m.start), style: base));
    }
    if (m.group(1) != null) {
      spans.add(TextSpan(
          text: m.group(1), style: base.copyWith(fontWeight: FontWeight.w700)));
    } else if (m.group(2) != null) {
      spans.add(TextSpan(
          text: m.group(2), style: base.copyWith(fontStyle: FontStyle.italic)));
    } else {
      spans.add(TextSpan(
          text: m.group(3),
          style: base.copyWith(fontFamily: 'monospace', letterSpacing: 0)));
    }
    i = m.end;
  }
  if (i < cleaned.length) {
    spans.add(TextSpan(text: cleaned.substring(i), style: base));
  }
  return spans;
}

class _UserMessage extends ConsumerWidget {
  final String content;
  const _UserMessage({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = AppTypography.bodyMedium
        .copyWith(fontSize: chatFontSize(ref.watch(fontSizeProvider)));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Align(
        alignment: Alignment.centerRight,
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppRadius.lg,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
          borderColor: AppColors.primaryBlue.withValues(alpha: 0.3),
          child: Text(content, style: style),
        ),
      ),
    );
  }
}

class _AssistantMessage extends ConsumerWidget {
  final String content;
  final bool isStreaming;
  const _AssistantMessage({required this.content, required this.isStreaming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = AppTypography.bodyMedium
        .copyWith(fontSize: chatFontSize(ref.watch(fontSizeProvider)));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceHighlight,
            child: const Icon(Icons.blur_on, size: 18, color: AppColors.primaryCyan),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: markdownSpans(
                      content.isEmpty && isStreaming ? '...' : content,
                      style,
                    ),
                  ),
                ),
                if (!isStreaming) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isTyping;
  final VoidCallback onVoice;

  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onStop,
    required this.isTyping,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: GlassInput(
          controller: controller,
          focusNode: focusNode,
          hintText: 'Ask anything...',
          onSubmit: onSend,
          suffixWidgets: [
            IconButton(
              icon: const Icon(Icons.mic_none, color: AppColors.textSecondary),
              onPressed: onVoice,
            ),
            GlassCircleButton(
              icon: isTyping ? Icons.stop : Icons.arrow_upward,
              iconColor: AppColors.primaryCyan,
              onTap: isTyping ? onStop : onSend,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

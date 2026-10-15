import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../repositories/repository_interfaces.dart';
import '../repositories/tools.dart';
import '../repositories/web_search.dart';
import '../repositories/openrouter_repository.dart';
import '../secrets.dart';
import '../repositories/conversation_store.dart';
import '../repositories/memory_store.dart';
import '../repositories/mock_repositories.dart';
import '../repositories/prefs_store.dart';
import '../repositories/profile_store.dart';
import '../repositories/saved_store.dart';
import '../models/conversation.dart';
import '../models/app_models.dart';

// ── Repository Providers ────────────────────────────────────────────────────

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationStore(),
);

final savedRepositoryProvider = Provider<SavedRepository>(
  (ref) => SavedStore(),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => ProfileStore(),
);

const apiKeyStorageKey = 'openrouter_api_key';
const modelStorageKey = 'openrouter_model';

/// Falls back to the key in lib/secrets.dart; main() overrides this with
/// anything saved in Settings, so the on-device value wins.
final apiKeyProvider = StateProvider<String?>(
  (ref) => openRouterApiKey.isEmpty ? null : openRouterApiKey,
);

final memoryStoreProvider = Provider((ref) => MemoryStore());

final webSearchProvider = Provider((ref) => WebSearch());

/// Overridden in main() with what's on disk.
final memoriesProvider = StateProvider<List<String>>((ref) => const []);

/// Overridden in main() from secure storage.
final modelProvider =
    StateProvider<String>((ref) => OpenRouterAiRepository.defaultModel);

// ── Preferences ────────────────────────────────────────────────────────────

final prefsStoreProvider = Provider((ref) => PrefsStore());

/// 0 = small (12px), 1 = medium (14px, default), 2 = large (16px)
final fontSizeProvider = StateProvider<int>((ref) => 1);

/// Custom system prompt prepended to the AI's instructions.
final systemPromptProvider = StateProvider<String>((ref) => '');

/// TTS voice name. Null = platform default.
final ttsVoiceProvider = StateProvider<String?>((ref) => null);

/// Tool IDs the user has disabled.
final disabledToolsProvider = StateProvider<List<String>>((ref) => const []);

/// Map font-size index to actual pixel value.
double chatFontSize(int index) => const [12.0, 14.0, 16.0][index.clamp(0, 2)];

/// A real open model when a key is set, canned replies otherwise — so the app
/// is still usable before you paste a key in.
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final key = ref.watch(apiKeyProvider);
  if (key == null || key.isEmpty) return MockAiRepository();
  final disabled = ref.watch(disabledToolsProvider);
  final allTools = buildTools(search: ref.read(webSearchProvider));
  final tools = disabled.isEmpty
      ? allTools
      : allTools.where((t) => !disabled.contains(t.name)).toList();
  return OpenRouterAiRepository(
    apiKey: key,
    model: ref.watch(modelProvider),
    // read, not watch: see OpenRouterAiRepository._memories
    memories: () => ref.read(memoriesProvider),
    customSystemPrompt: ref.watch(systemPromptProvider),
    tools: tools,
  );
});

// ── Conversation Providers ──────────────────────────────────────────────────

final conversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getConversations();
});

final conversationProvider =
    FutureProvider.family<Conversation?, String>((ref, id) async {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getConversation(id);
});

// ── Active Chat State ───────────────────────────────────────────────────────

class ChatState {
  final Conversation? conversation;

  /// null = idle, '' = awaiting first chunk, non-empty = partial reply.
  final String? streamingContent;
  final String? error;

  const ChatState({this.conversation, this.streamingContent, this.error});

  bool get isTyping => streamingContent != null;
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ConversationRepository _repo;
  final AiRepository _ai;

  /// Called when the user asks JARVIS to remember something. Null in tests.
  final Future<void> Function(String fact)? onRemember;

  /// Fired after every write, so History, Saved and the profile counts don't
  /// serve a cached list from before this message. Null in tests.
  final void Function()? onConversationsChanged;

  bool _stopping = false;

  ChatNotifier(
    this._repo,
    this._ai, {
    this.onRemember,
    this.onConversationsChanged,
  }) : super(const ChatState());

  void setConversation(Conversation? conv) {
    state = ChatState(conversation: conv);
  }

  void startNewConversation() {
    _stopping = true; // kill any in-flight stream
    state = const ChatState();
  }

  /// Halt the current stream, commit whatever has arrived so far.
  void stop() {
    _stopping = true;
  }

  Future<void> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    _stopping = false;

    var conv = state.conversation ??
        await _repo.createConversation(
          text.length > 40 ? '${text.substring(0, 40)}...' : text,
        );

    onConversationsChanged?.call();
    conv = await _repo.addMessage(
      conv.id,
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    );
    state = ChatState(conversation: conv, streamingContent: '');

    // Best-effort, and only once the message is safely committed — a failed
    // memory write must never cost the user their message.
    final fact = rememberedFact(text);
    if (fact != null && onRemember != null) {
      try {
        await onRemember!(fact);
      } catch (_) {
        /* memory is secondary to the conversation */
      }
    }

    final buffer = StringBuffer();
    try {
      await for (final chunk in _ai.send(conv.messages)) {
        if (_stopping) break;
        buffer.write(chunk);
        state = ChatState(
          conversation: conv,
          streamingContent: buffer.toString(),
        );
      }
    } catch (e) {
      state = ChatState(
        conversation: conv,
        error: e is AiException ? e.message : 'JARVIS could not respond.',
      );
      return;
    }

    if (buffer.isEmpty) {
      state = ChatState(
        conversation: conv,
        error: 'The model returned nothing. Try another one in Settings.',
      );
      return;
    }

    conv = await _repo.addMessage(
      conv.id,
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        content: buffer.toString(),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
    state = ChatState(conversation: conv);
    onConversationsChanged?.call();
  }

  void toggleLike(String id) => _rate(id, like: true);

  void toggleDislike(String id) => _rate(id, like: false);

  /// Resend the last user message after an error.
  Future<void> retry() async {
    final msgs = state.conversation?.messages ?? [];
    // Clear the error, keep the conversation, and re-stream from history.
    state = ChatState(conversation: state.conversation, streamingContent: '');
    final buffer = StringBuffer();
    try {
      await for (final chunk in _ai.send(msgs)) {
        if (_stopping) break;
        buffer.write(chunk);
        state = ChatState(
          conversation: state.conversation,
          streamingContent: buffer.toString(),
        );
      }
    } catch (e) {
      state = ChatState(
        conversation: state.conversation,
        error: e is AiException ? e.message : 'JARVIS could not respond.',
      );
      return;
    }
    if (buffer.isEmpty) {
      state = ChatState(
        conversation: state.conversation,
        error: 'The model returned nothing. Try another one in Settings.',
      );
      return;
    }
    final conv = await _repo.addMessage(
      state.conversation!.id,
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: buffer.toString(),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
    state = ChatState(conversation: conv);
  }

  void _rate(String messageId, {required bool like}) {
    final conv = state.conversation;
    if (conv == null) return;
    final messages = conv.messages.map((m) {
      if (m.id != messageId) return m;
      return like
          ? m.copyWith(isLiked: !m.isLiked, isDisliked: false)
          : m.copyWith(isDisliked: !m.isDisliked, isLiked: false);
    }).toList();
    state = ChatState(
      conversation: conv.copyWith(messages: messages),
      streamingContent: state.streamingContent,
      error: state.error,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(conversationRepositoryProvider),
    ref.watch(aiRepositoryProvider),
    onRemember: (fact) async {
      final facts = await ref.read(memoryStoreProvider).add(fact);
      ref.read(memoriesProvider.notifier).state = facts;
    },
    onConversationsChanged: () {
      ref.invalidate(conversationsProvider);
      ref.invalidate(savedItemsProvider);
    },
  );
});

// ── Saved Items Provider ────────────────────────────────────────────────────

final savedItemsProvider = FutureProvider<List<SavedItem>>((ref) async {
  final conversations =
      await ref.watch(conversationRepositoryProvider).getConversations();
  final notes = await ref.watch(savedRepositoryProvider).getSavedItems();
  return mergeSaved(conversations, notes);
});

// ── User Profile Provider ───────────────────────────────────────────────────

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile();
});

// ── Voice Mode State ────────────────────────────────────────────────────────

enum VoiceState { idle, listening, processing, speaking, unavailable }

/// Markdown reads terribly aloud — "asterisk asterisk qubits asterisk
/// asterisk". Strip it before handing text to the speech engine.
String speakable(String markdown) => markdown
    .replaceAll(RegExp(r'```[\s\S]*?```'), ' code block. ')
    .replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m[1]!)
    .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
    .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
    .replaceAll(RegExp(r'^[ \t]{0,3}#{1,6}[ \t]*', multiLine: true), '')
    .replaceAll(RegExp(r'^[ \t]*[-*+][ \t]+', multiLine: true), '')
    .replaceAll(RegExp(r'\*\*|__|\*|_|~~'), '')
    .replaceAll(RegExp(r'^[ \t]*>[ \t]?', multiLine: true), '')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

/// Speech in, model, speech out — all on-device except the model call, and
/// routed through [chatProvider] so voice turns land in History like any
/// other conversation.
class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier(this._ref) : super(VoiceState.idle);

  final Ref _ref;
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();

  bool _ready = false;

  /// Bumped on every interruption so an in-flight sequence knows it is stale.
  int _run = 0;

  /// What the recogniser has heard so far, for the screen to display.
  String heard = '';

  Future<void> startListening() async {
    final run = ++_run;
    heard = '';

    if (!_ready) {
      // Asks for the microphone permission on first use.
      _ready = await _speech.initialize(
        onError: (_) => _fail(run),
        onStatus: (status) {
          // The recogniser stops itself after a pause in speech.
          if (status == 'done' && state == VoiceState.listening) {
            _submit(run);
          }
        },
      );
      if (!_ready) {
        state = VoiceState.unavailable;
        return;
      }
      await _tts.awaitSpeakCompletion(true);
    }

    if (run != _run) return;
    state = VoiceState.listening;
    await _speech.listen(
      onResult: (r) {
        heard = r.recognizedWords;
        if (r.finalResult) _submit(run);
        // Nudge listeners so the transcript repaints.
        if (state == VoiceState.listening) state = VoiceState.listening;
      },
      listenOptions: stt.SpeechListenOptions(partialResults: true),
    );
  }

  /// Hand what was heard to the model, then speak the reply.
  Future<void> _submit(int run) async {
    if (run != _run) return;
    final text = heard.trim();
    await _speech.stop();

    if (text.isEmpty) {
      state = VoiceState.idle;
      return;
    }

    state = VoiceState.processing;
    await _ref.read(chatProvider.notifier).sendMessage(text);
    if (run != _run) return;

    final chat = _ref.read(chatProvider);
    if (chat.error != null) {
      state = VoiceState.idle;
      return;
    }

    final last = chat.conversation?.messages.last;
    if (last == null || last.role != MessageRole.assistant) {
      state = VoiceState.idle;
      return;
    }

    state = VoiceState.speaking;
    final voice = _ref.read(ttsVoiceProvider);
    if (voice != null) {
      await _tts.setVoice({'name': voice, 'locale': ''});
    }
    await _tts.speak(speakable(last.content));
    if (run != _run) return;
    state = VoiceState.idle;
  }

  void _fail(int run) {
    if (run != _run) return;
    state = VoiceState.idle;
  }

  Future<void> stopListening() => _submit(_run);

  Future<void> pause() async {
    _run++;
    await _speech.stop();
    await _tts.stop();
    state = VoiceState.idle;
  }

  Future<void> cancel() async {
    _run++;
    heard = '';
    await _speech.cancel();
    await _tts.stop();
    state = VoiceState.idle;
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>(
  (ref) => VoiceNotifier(ref),
);

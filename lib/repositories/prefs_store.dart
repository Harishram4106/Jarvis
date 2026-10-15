import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lightweight key-value prefs backed by secure storage.
/// Single blob, split to per-key if prefs exceed ~20 entries.
class PrefsStore {
  static const _key = 'jarvis_prefs';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _all() async {
    if (_cache != null) return _cache!;
    final raw = await _storage.read(key: _key);
    _cache = (raw != null && raw.isNotEmpty)
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    return _cache!;
  }

  Future<void> _flush() =>
      _storage.write(key: _key, value: jsonEncode(_cache!));

  Future<T?> get<T>(String key) async => (await _all())[key] as T?;

  Future<void> set(String key, dynamic value) async {
    (await _all())[key] = value;
    await _flush();
  }

  // ── Typed accessors ──────────────────────────────────────────────────────

  /// 0 = small (12), 1 = medium (14, default), 2 = large (16)
  Future<int> getFontSize() async => (await get<int>('fontSize')) ?? 1;
  Future<void> setFontSize(int v) => set('fontSize', v);

  Future<String> getSystemPrompt() async =>
      (await get<String>('systemPrompt')) ?? '';
  Future<void> setSystemPrompt(String v) => set('systemPrompt', v);

  Future<String?> getTtsVoice() => get<String>('ttsVoice');
  Future<void> setTtsVoice(String v) => set('ttsVoice', v);

  /// Tool IDs that the user has disabled. Empty = all enabled.
  Future<List<String>> getDisabledTools() async {
    final raw = await get<List<dynamic>>('disabledTools');
    return raw?.cast<String>() ?? [];
  }

  Future<void> setDisabledTools(List<String> v) => set('disabledTools', v);
}

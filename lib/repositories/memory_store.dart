import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Facts the user has asked JARVIS to remember, carried across conversations.
///
/// A JSON blob in secure storage. Right for the tens of facts a
/// personal assistant accumulates; move to sqflite if it ever reaches
/// thousands, or if you need to search them rather than send them all.
class MemoryStore {
  static const _key = 'jarvis_memories';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Enough to keep the system prompt small — free models have modest
  /// context and every fact is sent on every message.
  static const maxFacts = 50;

  Future<List<String>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return []; // corrupt blob shouldn't brick the assistant
    }
  }

  Future<List<String>> add(String fact) async {
    final facts = await load();
    final trimmed = fact.trim();
    if (trimmed.isEmpty) return facts;

    // Newest last, no duplicates, oldest dropped past the cap.
    facts
      ..removeWhere((f) => f.toLowerCase() == trimmed.toLowerCase())
      ..add(trimmed);
    while (facts.length > maxFacts) {
      facts.removeAt(0);
    }
    await _storage.write(key: _key, value: jsonEncode(facts));
    return facts;
  }

  Future<List<String>> removeAt(int index) async {
    final facts = await load();
    if (index < 0 || index >= facts.length) return facts;
    facts.removeAt(index);
    await _storage.write(key: _key, value: jsonEncode(facts));
    return facts;
  }

  Future<List<String>> clear() async {
    await _storage.delete(key: _key);
    return [];
  }
}

/// Pulls the fact out of an explicit instruction to remember something.
///
/// Returns null when the message isn't asking JARVIS to remember anything —
/// "do you remember X?" is a question, not an instruction.
String? rememberedFact(String message) {
  final text = message.trim();

  // Questions ask about memory, they don't write to it.
  if (text.endsWith('?')) return null;

  final match = RegExp(
    r"^(?:please\s+)?(?:remember|note|keep in mind|don'?t forget)"
    r"(?:\s+that)?[:,]?\s+(.+)$",
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(text);

  if (match == null) return null;

  final fact = match.group(1)!.trim().replaceAll(RegExp(r'[.\s]+$'), '');
  return fact.isEmpty ? null : fact;
}

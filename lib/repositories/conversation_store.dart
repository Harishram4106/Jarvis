import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import 'mock_repositories.dart' show buildSampleConversations;
import 'repository_interfaces.dart';

const _uuid = Uuid();

/// Conversations that survive restarts.
///
/// Held in memory and written through on every change — reads stay instant,
/// and a crash loses at most the message in flight.
///
/// The whole list is re-encoded on each write. Fine at the scale a
/// phone assistant reaches (see [maxConversations]); move to sqflite with
/// per-row writes if history ever needs to grow past that.
class ConversationStore implements ConversationRepository {
  static const _key = 'jarvis_conversations';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Bounds the blob so writes stay quick. Oldest conversations fall off.
  static const maxConversations = 100;

  List<Conversation>? _cache;

  /// Newest first, oldest dropped past the cap.
  static List<Conversation> capped(List<Conversation> all) {
    final sorted = [...all]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.length <= maxConversations
        ? sorted
        : sorted.sublist(0, maxConversations);
  }

  Future<List<Conversation>> _all() async {
    if (_cache != null) return _cache!;

    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      _cache = buildSampleConversations(); // first run
      await _flush();
      return _cache!;
    }

    try {
      _cache = (jsonDecode(raw) as List)
          .map((j) => Conversation.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // A corrupt blob must not brick the app; better an empty history than
      // no app at all.
      _cache = [];
    }
    return _cache!;
  }

  Future<void> _flush() async {
    _cache = capped(_cache!);
    await _storage.write(
      key: _key,
      value: jsonEncode(_cache!.map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<List<Conversation>> getConversations() async =>
      List.unmodifiable(await _all());

  @override
  Future<Conversation?> getConversation(String id) async {
    final all = await _all();
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<Conversation> createConversation(String title) async {
    final all = await _all();
    final now = DateTime.now();
    final conv = Conversation(
      id: _uuid.v4(),
      title: title,
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );
    all.insert(0, conv);
    await _flush();
    return conv;
  }

  @override
  Future<Conversation> addMessage(
      String conversationId, ChatMessage message) async {
    final all = await _all();
    final i = all.indexWhere((c) => c.id == conversationId);
    if (i == -1) throw Exception('Conversation not found');

    final updated = all[i].copyWith(
      messages: [...all[i].messages, message],
      updatedAt: DateTime.now(),
    );
    all[i] = updated;
    await _flush();
    return updated;
  }

  @override
  Future<void> deleteConversation(String id) async {
    final all = await _all();
    all.removeWhere((c) => c.id == id);
    await _flush();
  }

  @override
  Future<void> saveConversation(String id, bool saved) async {
    final all = await _all();
    final i = all.indexWhere((c) => c.id == id);
    if (i == -1) return;
    all[i] = all[i].copyWith(isSaved: saved);
    await _flush();
  }

  @override
  Future<void> renameConversation(String id, String title) async {
    final all = await _all();
    final i = all.indexWhere((c) => c.id == id);
    if (i == -1) return;
    all[i] = all[i].copyWith(title: title);
    await _flush();
  }
}

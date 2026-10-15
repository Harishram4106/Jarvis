import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_models.dart';
import '../models/conversation.dart';
import 'repository_interfaces.dart';

/// Standalone saved notes — replies the user kept for later.
///
/// Saved *conversations* are not stored here: they are derived from
/// [Conversation.isSaved], so there is one source of truth and deleting a
/// conversation removes it from Saved without any sync code.
class SavedStore implements SavedRepository {
  static const _key = 'jarvis_saved_notes';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<SavedItem>? _cache;

  Future<List<SavedItem>> _all() async {
    if (_cache != null) return _cache!;
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    try {
      _cache = (jsonDecode(raw) as List)
          .map((j) => SavedItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cache = []; // a corrupt blob must not brick the screen
    }
    return _cache!;
  }

  Future<void> _flush() async => _storage.write(
        key: _key,
        value: jsonEncode(_cache!.map((i) => i.toJson()).toList()),
      );

  @override
  Future<List<SavedItem>> getSavedItems() async =>
      List.unmodifiable(await _all());

  @override
  Future<void> saveItem(SavedItem item) async {
    final all = await _all();
    all.insert(0, item);
    await _flush();
  }

  @override
  Future<void> removeSavedItem(String id) async {
    final all = await _all();
    all.removeWhere((i) => i.id == id);
    await _flush();
  }
}

/// The Saved screen's contents: starred conversations plus standalone notes,
/// newest first.
List<SavedItem> mergeSaved(
  List<Conversation> conversations,
  List<SavedItem> notes,
) {
  final items = <SavedItem>[
    for (final c in conversations.where((c) => c.isSaved))
      SavedItem(
        id: 'conv:${c.id}',
        title: c.title,
        description: c.lastMessagePreview,
        type: SavedItemType.chat,
        savedAt: c.updatedAt,
        conversationId: c.id,
      ),
    ...notes,
  ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return items;
}

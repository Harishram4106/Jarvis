import '../models/conversation.dart';
import '../models/app_models.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getConversations();
  Future<Conversation?> getConversation(String id);
  Future<Conversation> createConversation(String title);
  Future<Conversation> addMessage(String conversationId, ChatMessage message);
  Future<void> deleteConversation(String id);
  Future<void> saveConversation(String id, bool saved);
  Future<void> renameConversation(String id, String title);
}

abstract class SavedRepository {
  Future<List<SavedItem>> getSavedItems();
  Future<void> saveItem(SavedItem item);
  Future<void> removeSavedItem(String id);
}

abstract class UserRepository {
  Future<UserProfile> getProfile();
  Future<void> updateProfile(UserProfile profile);
}

abstract class AiRepository {
  /// Streams the assistant reply in chunks. Real models stream; the mock does
  /// too, so the streaming path is exercised before a backend exists.
  /// [context] carries reference material (e.g. web search results) that is
  /// not part of the conversation itself.
  Stream<String> send(List<ChatMessage> history, {String? context});
}

/// A failure worth showing the user verbatim.
class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => message;
}

import 'package:flutter/foundation.dart';

@immutable
class SavedItem {
  final String id;
  final String title;
  final String description;
  final SavedItemType type;
  final DateTime savedAt;
  final String? conversationId;

  const SavedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.savedAt,
    this.conversationId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'savedAt': savedAt.toIso8601String(),
        'conversationId': conversationId,
      };

  factory SavedItem.fromJson(Map<String, dynamic> json) => SavedItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: SavedItemType.values.byName(json['type'] as String),
        savedAt: DateTime.parse(json['savedAt'] as String),
        conversationId: json['conversationId'] as String?,
      );
}

enum SavedItemType { chat, note, prompt }

@immutable
class ExploreCategory {
  final String id;
  final String label;

  const ExploreCategory({required this.id, required this.label});
}

@immutable
class ExploreCard {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String category;

  const ExploreCard({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
  });
}

@immutable
class UserProfile {
  final String name;
  final String tagline;
  final String email;

  const UserProfile({
    required this.name,
    required this.tagline,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'tagline': tagline,
        'email': email,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String,
        tagline: json['tagline'] as String,
        email: json['email'] as String,
      );
}

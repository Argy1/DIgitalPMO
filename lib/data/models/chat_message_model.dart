import 'package:hive_flutter/hive_flutter.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 9)
class ChatMessageModel {
  @HiveField(0)
  final String id;

  /// 'user' or 'ai'
  @HiveField(1)
  final String role;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime timestamp;

  /// True while the AI response is still streaming / typing
  @HiveField(4)
  final bool isLoading;

  /// One of: 'emergency', 'education', 'motivation', or null for plain text
  @HiveField(5)
  final String? cardType;

  /// Extra structured payload for the embedded card (bullets, progress, etc.)
  @HiveField(6)
  final Map<String, dynamic>? cardData;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.cardType,
    this.cardData,
  });

  bool get isUser => role == 'user';
  bool get isAI => role == 'ai';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : json['timestamp'] as DateTime,
      isLoading: json['isLoading'] as bool? ?? false,
      cardType: json['cardType'] as String?,
      cardData: json['cardData'] != null
          ? Map<String, dynamic>.from(json['cardData'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'cardType': cardType,
      'cardData': cardData,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isLoading,
    String? cardType,
    Map<String, dynamic>? cardData,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      cardType: cardType ?? this.cardType,
      cardData: cardData ?? this.cardData,
    );
  }

  @override
  String toString() => 'ChatMessageModel(id: $id, role: $role)';
}

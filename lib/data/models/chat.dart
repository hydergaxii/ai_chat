import 'dart:convert';
import 'message.dart';

class Chat {
  final String id;
  String title;
  List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  Chat({
    required this.id,
    this.title = 'New conversation',
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Chat copyWith({
    String? title,
    List<Message>? messages,
    DateTime? updatedAt,
  }) =>
      Chat(
        id: id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String get subtitle {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    final preview = last.content.length > 60
        ? '${last.content.substring(0, 60)}…'
        : last.content;
    return preview.replaceAll('\n', ' ');
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  // Messages stored separately in messages table
  Map<String, dynamic> toMapWithMessages() => {
        ...toMap(),
        'messages': jsonEncode(
          messages.map((m) => m.toMap()).toList(),
        ),
      };

  factory Chat.fromMap(Map<String, dynamic> map,
      {List<Message>? messages}) =>
      Chat(
        id: map['id'] as String,
        title: map['title'] as String,
        messages: messages ?? [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] as int,
        ),
      );
}

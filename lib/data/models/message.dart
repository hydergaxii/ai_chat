import 'dart:convert';
import 'attachment.dart';

enum MessageRole { user, assistant }

class Message {
  final String id;
  final MessageRole role;
  String content;
  final List<Attachment> attachments;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.attachments = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  Message copyWith({String? content}) => Message(
        id: id,
        role: role,
        content: content ?? this.content,
        attachments: attachments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.name,
        'content': content,
        'attachments': jsonEncode(
          attachments.map((a) => a.toMap()).toList(),
        ),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Message.fromMap(Map<String, dynamic> map) {
    final attList = <Attachment>[];
    try {
      final raw = jsonDecode(map['attachments'] as String? ?? '[]') as List;
      for (final item in raw) {
        attList.add(Attachment.fromMap(item as Map<String, dynamic>));
      }
    } catch (_) {}

    return Message(
      id: map['id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      content: map['content'] as String,
      attachments: attList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int,
      ),
    );
  }
}

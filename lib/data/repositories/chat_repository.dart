import 'package:sqflite/sqflite.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../db/database_helper.dart';

class ChatRepository {
  final DatabaseHelper _db;

  ChatRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  // ─── Chats ────────────────────────────────────────────────────────────────

  Future<List<Chat>> getAllChats() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableChats,
      orderBy: 'updatedAt DESC',
    );

    final chats = <Chat>[];
    for (final row in rows) {
      final messages = await getMessagesForChat(row['id'] as String);
      chats.add(Chat.fromMap(row, messages: messages));
    }
    return chats;
  }

  Future<Chat?> getChatById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableChats,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    final messages = await getMessagesForChat(id);
    return Chat.fromMap(rows.first, messages: messages);
  }

  Future<void> saveChat(Chat chat) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableChats,
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateChatTitle(String chatId, String title) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableChats,
      {
        'title': title,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> updateChatTimestamp(String chatId) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableChats,
      {'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> deleteChat(String chatId) async {
    final db = await _db.database;
    // Messages deleted via CASCADE
    await db.delete(
      DatabaseHelper.tableChats,
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> clearChatMessages(String chatId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableMessages,
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
    await updateChatTimestamp(chatId);
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  Future<List<Message>> getMessagesForChat(String chatId) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableMessages,
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  Future<void> insertMessage(String chatId, Message message) async {
    final db = await _db.database;
    final map = message.toMap();
    map['chatId'] = chatId;
    await db.insert(
      DatabaseHelper.tableMessages,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await updateChatTimestamp(chatId);
  }

  Future<void> updateMessage(Message message) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.tableMessages,
      {
        'content': message.content,
        'attachments': message.toMap()['attachments'],
      },
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableMessages,
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessagesAfter(String chatId, String messageId) async {
    final db = await _db.database;
    // Get the createdAt of the given message
    final rows = await db.query(
      DatabaseHelper.tableMessages,
      columns: ['createdAt'],
      where: 'id = ?',
      whereArgs: [messageId],
    );
    if (rows.isEmpty) return;
    final ts = rows.first['createdAt'] as int;
    await db.delete(
      DatabaseHelper.tableMessages,
      where: 'chatId = ? AND createdAt >= ?',
      whereArgs: [chatId, ts],
    );
  }
}

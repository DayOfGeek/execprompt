// ExecPrompt - AI LLM Mobile Client
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Conversations table
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get modelName => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Messages table
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text().nullable()();
  TextColumn get thinking => text().nullable()();
  TextColumn get images => text().nullable()(); // JSON array of base64 strings
  TextColumn get toolCalls => text().nullable()(); // JSON array of tool call objects
  TextColumn get toolName => text().nullable()(); // For role: "tool" messages
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Conversations, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // Conversation queries
  Future<List<Conversation>> getAllConversations() {
    return (select(conversations)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<Conversation> getConversation(int id) {
    return (select(conversations)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> createConversation(ConversationsCompanion conversation) {
    return into(conversations).insert(conversation);
  }

  Future<bool> updateConversation(Conversation conversation) {
    return update(conversations).replace(conversation);
  }

  Future<int> deleteConversation(int id) {
    return (delete(conversations)..where((t) => t.id.equals(id))).go();
  }

  // Message queries
  Future<List<Message>> getMessagesForConversation(int conversationId) {
    return (select(messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> addMessage(MessagesCompanion message) async {
    // Insert message
    final messageId = await into(messages).insert(message);
    
    // Update conversation's updatedAt
    final conversationId = message.conversationId.value;
    final conversation = await getConversation(conversationId);
    await updateConversation(
      conversation.copyWith(updatedAt: DateTime.now()),
    );
    
    return messageId;
  }

  Future<int> deleteMessage(int id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteMessagesForConversation(int conversationId) {
    return (delete(messages)
          ..where((t) => t.conversationId.equals(conversationId)))
        .go();
  }

  // Statistics queries
  Future<int> getConversationCount() async {
    final count = countAll();
    final query = selectOnly(conversations)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> getMessageCount() async {
    final count = countAll();
    final query = selectOnly(messages)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Search conversations by title or message content.
  /// Returns conversations ordered by updatedAt DESC where the query
  /// matches the title or any message content (SQL LIKE, case-insensitive).
  Future<List<Conversation>> searchConversations(String query) async {
    final pattern = '%$query%';
    // Drift raw query: find conversations where title matches OR any message content matches.
    final results = await customSelect(
      'SELECT DISTINCT c.* FROM conversations c '
      'LEFT JOIN messages m ON m.conversation_id = c.id '
      'WHERE c.title LIKE ? COLLATE NOCASE '
      'OR m.content LIKE ? COLLATE NOCASE '
      'ORDER BY c.updated_at DESC',
      variables: [Variable.withString(pattern), Variable.withString(pattern)],
      readsFrom: {conversations, messages},
    ).get();

    return results.map((row) => Conversation(
      id: row.read<int>('id'),
      title: row.read<String>('title'),
      modelName: row.read<String>('model_name'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    )).toList();
  }

  /// Find the first matching message snippet for a conversation + query.
  /// Returns a short excerpt (~80 chars) or null if no message matched.
  Future<String?> searchSnippet(int conversationId, String query) async {
    final pattern = '%$query%';
    final results = await customSelect(
      'SELECT content FROM messages '
      'WHERE conversation_id = ? AND content LIKE ? COLLATE NOCASE '
      'LIMIT 1',
      variables: [
        Variable.withInt(conversationId),
        Variable.withString(pattern),
      ],
      readsFrom: {messages},
    ).get();

    if (results.isEmpty) return null;
    final content = results.first.read<String?>('content');
    if (content == null) return null;

    // Extract snippet around the match
    final lowerContent = content.toLowerCase();
    final idx = lowerContent.indexOf(query.toLowerCase());
    if (idx < 0) return null;

    const snippetLen = 80;
    final start = (idx - 20).clamp(0, content.length);
    final end = (start + snippetLen).clamp(0, content.length);
    final snippet = content.substring(start, end).replaceAll('\n', ' ');
    return '${start > 0 ? '...' : ''}$snippet${end < content.length ? '...' : ''}';
  }

  /// Export a single conversation and its messages as a serializable JSON map.
  Future<Map<String, dynamic>> exportConversation(int id) async {
    final conv = await getConversation(id);
    final msgs = await getMessagesForConversation(id);
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'conversations': [
        {
          'title': conv.title,
          'modelName': conv.modelName,
          'createdAt': conv.createdAt.toIso8601String(),
          'updatedAt': conv.updatedAt.toIso8601String(),
          'messages': msgs.map((m) => {
            'role': m.role,
            'content': m.content,
            'thinking': m.thinking,
            'images': m.images,
            'toolCalls': m.toolCalls,
            'toolName': m.toolName,
            'createdAt': m.createdAt.toIso8601String(),
          }).toList(),
        },
      ],
    };
  }

  /// Export a single conversation as a Markdown-formatted string.
  Future<String> exportConversationAsMarkdown(int id) async {
    final conv = await getConversation(id);
    final msgs = await getMessagesForConversation(id);
    final buf = StringBuffer();

    buf.writeln('# ${conv.title}');
    buf.writeln();
    buf.writeln('**Model:** ${conv.modelName}');
    buf.writeln('**Created:** ${conv.createdAt.toIso8601String()}');
    buf.writeln('**Updated:** ${conv.updatedAt.toIso8601String()}');
    buf.writeln();
    buf.writeln('---');
    buf.writeln();

    for (final m in msgs) {
      final roleLabel = m.role[0].toUpperCase() + m.role.substring(1);
      buf.writeln('## $roleLabel');
      buf.writeln();
      if (m.content != null && m.content!.isNotEmpty) {
        buf.writeln(m.content);
        buf.writeln();
      }
      if (m.thinking != null && m.thinking!.isNotEmpty) {
        buf.writeln('<details>');
        buf.writeln('<summary>Thinking</summary>');
        buf.writeln();
        buf.writeln(m.thinking);
        buf.writeln();
        buf.writeln('</details>');
        buf.writeln();
      }
      buf.writeln('---');
      buf.writeln();
    }

    return buf.toString();
  }

  /// Export all conversations and messages as a serializable map
  Future<Map<String, dynamic>> exportAllData() async {
    final allConversations = await getAllConversations();
    final exportData = <Map<String, dynamic>>[];

    for (final conv in allConversations) {
      final msgs = await getMessagesForConversation(conv.id);
      exportData.add({
        'title': conv.title,
        'modelName': conv.modelName,
        'createdAt': conv.createdAt.toIso8601String(),
        'updatedAt': conv.updatedAt.toIso8601String(),
        'messages': msgs.map((m) => {
          'role': m.role,
          'content': m.content,
          'thinking': m.thinking,
          'images': m.images,
          'toolCalls': m.toolCalls,
          'toolName': m.toolName,
          'createdAt': m.createdAt.toIso8601String(),
        }).toList(),
      });
    }

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'conversations': exportData,
    };
  }

  /// Import conversations and messages from exported JSON map
  Future<int> importData(Map<String, dynamic> data) async {
    final conversationsList = data['conversations'] as List<dynamic>? ?? [];
    int imported = 0;

    for (final convData in conversationsList) {
      final conv = convData as Map<String, dynamic>;
      final convId = await createConversation(ConversationsCompanion.insert(
        title: conv['title'] as String? ?? 'Imported',
        modelName: conv['modelName'] as String? ?? 'unknown',
        createdAt: DateTime.tryParse(conv['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(conv['updatedAt'] as String? ?? '') ?? DateTime.now(),
      ));

      final msgs = conv['messages'] as List<dynamic>? ?? [];
      for (final msgData in msgs) {
        final msg = msgData as Map<String, dynamic>;
        await into(messages).insert(MessagesCompanion.insert(
          conversationId: convId,
          role: msg['role'] as String? ?? 'user',
          content: Value(msg['content'] as String?),
          thinking: Value(msg['thinking'] as String?),
          images: Value(msg['images'] as String?),
          toolCalls: Value(msg['toolCalls'] as String?),
          toolName: Value(msg['toolName'] as String?),
          createdAt: DateTime.tryParse(msg['createdAt'] as String? ?? '') ?? DateTime.now(),
        ));
      }
      imported++;
    }

    return imported;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'execprompt_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

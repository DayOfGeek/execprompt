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


import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';

/// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

/// Current conversation ID provider
final currentConversationIdProvider = StateProvider<int?>((ref) => null);

/// Conversations list provider (ordered by updatedAt desc)
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.conversations)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
});

/// Conversation search query
final conversationSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered conversations (search applied).
/// When the query is non-empty, performs a full-text SQL search across
/// conversation titles AND message content.
final filteredConversationsProvider = Provider<AsyncValue<List<Conversation>>>((ref) {
  final query = ref.watch(conversationSearchQueryProvider).trim();
  if (query.isEmpty) {
    return ref.watch(conversationsProvider);
  }
  // Non-empty query: use the DB full-text search
  return ref.watch(searchResultsProvider);
});

/// Full-text search results — queries the DB for title + message content matches.
final searchResultsProvider = FutureProvider<List<Conversation>>((ref) async {
  final query = ref.watch(conversationSearchQueryProvider).trim();
  if (query.isEmpty) return [];
  final db = ref.read(databaseProvider);
  return db.searchConversations(query);
});

/// Search snippet for a specific conversation (when search is active).
final searchSnippetProvider = FutureProvider.family<String?, int>((ref, conversationId) async {
  final query = ref.watch(conversationSearchQueryProvider).trim();
  if (query.isEmpty) return null;
  final db = ref.read(databaseProvider);
  return db.searchSnippet(conversationId, query);
});

/// Current conversation messages provider
final currentMessagesProvider = StreamProvider<List<Message>>((ref) {
  final conversationId = ref.watch(currentConversationIdProvider);
  if (conversationId == null) {
    return Stream.value([]);
  }
  
  final database = ref.watch(databaseProvider);
  return (database.select(database.messages)
        ..where((t) => t.conversationId.equals(conversationId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();
});


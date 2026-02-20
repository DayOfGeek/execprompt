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


import 'package:dio/dio.dart';
import 'web_search_service.dart';

/// Ollama Cloud search via POST https://ollama.com/api/web_search
class OllamaCloudSearchService extends WebSearchService {
  final String apiKey;
  final Dio _dio;

  OllamaCloudSearchService({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://ollama.com',
          headers: {'Authorization': 'Bearer $apiKey'},
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  @override
  String get providerName => 'Ollama Cloud';

  @override
  Future<List<SearchResult>> search({
    required String query,
    int maxResults = 5,
  }) async {
    try {
      final response = await _dio.post('/api/web_search', data: {
        'query': query,
      });

      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];

      return results
          .take(maxResults)
          .map((r) {
            final item = r as Map<String, dynamic>;
            return SearchResult(
              title: item['title'] as String? ?? '',
              url: item['url'] as String? ?? '',
              content: item['content'] as String? ?? '',
            );
          })
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Ollama Cloud: Invalid API key');
      }
      throw Exception('Ollama Cloud search failed: ${e.message}');
    }
  }
}

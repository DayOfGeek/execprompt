/// Normalized search result — same shape regardless of provider.
class SearchResult {
  final String title;
  final String url;
  final String content;
  final double? score;

  const SearchResult({
    required this.title,
    required this.url,
    required this.content,
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'content': content,
        if (score != null) 'score': score,
      };

  @override
  String toString() => 'SearchResult(title: $title, url: $url)';
}

/// Abstract interface — swap providers without changing tool logic.
abstract class WebSearchService {
  /// Search the web and return normalized results.
  Future<List<SearchResult>> search({
    required String query,
    int maxResults = 5,
  });

  /// Human-readable name for logging/UI.
  String get providerName;
}

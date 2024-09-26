import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'dart:async';

class ScraperService {
  final String _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';

  Future<String> fetchArticleContent(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        var document = html.parse(response.body);
        return _extractContent(document);
      } else if (response.statusCode == 403) {
        // If forbidden, try to extract content from the API description
        return 'Access to full article content is restricted. Summary: ${await _getFallbackContent(url)}';
      } else {
        throw Exception('Failed to load article: ${response.reasonPhrase}');
      }
    } on TimeoutException {
      return 'Article content could not be retrieved due to a timeout. Summary: ${await _getFallbackContent(url)}';
    } catch (e) {
      return 'Error fetching article: $e. Summary: ${await _getFallbackContent(url)}';
    }
  }

  String _extractContent(Document document) {
    final List<String> contentSelectors = [
      'article', '.article-body', '.story-body', '#content', '.post-content', '.entry-content',
    ];

    for (var selector in contentSelectors) {
      var element = document.querySelector(selector);
      if (element != null) {
        return _cleanText(element.text);
      }
    }

    // If no matching selector found, try to get all paragraph text
    var paragraphs = document.querySelectorAll('p');
    if (paragraphs.isNotEmpty) {
      return paragraphs.map((p) => _cleanText(p.text)).join('\n\n');
    }

    return 'Failed to extract article content.';
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\n\r]+'), '\n')
        .trim();
  }

  Future<String> _getFallbackContent(String url) async {
    // This method tries to get content from the original API response
    // You'll need to modify your NewsService to store the original description
    // For now, we'll return a placeholder
    return 'Original article summary not available.';
  }
}
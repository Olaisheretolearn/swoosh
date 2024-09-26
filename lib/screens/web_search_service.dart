import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';
import 'package:html/dom.dart';
import 'dart:developer' as developer;

class WebSearchService {
  final String _googleSearchEngineId = '';
  final String _googleApiKey = '';
  final String _braveApiKey = '';

  
  Future<String> searchAndExtractContent(String title, String description) async {
    String content = await _googleSearch(title, description);
    if (content.startsWith('Error:')) {
      developer.log('Google Search failed, falling back to Brave Search');
      content = await _braveSearch(title, description);
    }
    return content;
  }

  Future<String> _googleSearch(String title, String description) async {
    try {
      final query = Uri.encodeComponent('$title $description');
      final url = 'https://www.googleapis.com/customsearch/v1?key=$_googleApiKey&cx=$_googleSearchEngineId&q=$query';
      developer.log('Google API Request URL: $url');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Use a custom reviver function with correct type annotations
        final data = json.decode(response.body, reviver: (Object? key, Object? value) {
          if (value is String) {
            // Handle potential issues with string values
            return value.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
          }
          return value;
        });
        developer.log('Google API Response: ${json.encode(data)}');

        if (data['items'] != null && data['items'].isNotEmpty) {
          final firstResultUrl = data['items'][0]['link'];
          developer.log('First result URL: $firstResultUrl');

          String content = await _extractContent(firstResultUrl);
          developer.log('Extracted content length: ${content.length}');
          return content;
        } else {
          developer.log('No search results found');
          return 'No search results found.';
        }
      } else if (response.statusCode == 429) {
        developer.log('Rate limit exceeded. Immediately falling back to Brave Search.');
        return 'Error: Rate limit exceeded';
      } else {
        developer.log('Google API request failed with status code: ${response.statusCode}');
        return 'Error: Failed to fetch search results. Status code: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Error in Google searchAndExtractContent: $e');
      return 'Error: Error searching for content: $e';
    }
  }

  Future<String> _braveSearch(String title, String description) async {
    try {
      final query = Uri.encodeComponent('$title $description');
      final url = 'https://api.search.brave.com/res/v1/web/search?q=$query';
      developer.log('Brave API Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip',
          'X-Subscription-Token': _braveApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Brave API Response: ${json.encode(data)}');

        if (data['web'] != null && data['web']['results'] != null && data['web']['results'].isNotEmpty) {
          final firstResultUrl = data['web']['results'][0]['url'];
          developer.log('First result URL from Brave: $firstResultUrl');

          String content = await _extractContent(firstResultUrl);
          developer.log('Extracted content length: ${content.length}');
          return content;
        } else {
          developer.log('No search results found in Brave Search');
          return 'No search results found.';
        }
      } else {
        developer.log('Brave API request failed with status code: ${response.statusCode}');
        return 'Error: Failed to fetch search results from Brave. Status code: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Error in Brave searchAndExtractContent: $e');
      return 'Error: Error searching for content with Brave: $e';
    }
  }

  Future<String> _extractContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var document = html.parse(response.body);
        return _findArticleContent(document);
      } else {
        developer.log('Failed to load article content. Status code: ${response.statusCode}');
        return 'Failed to load article content.';
      }
    } catch (e) {
      developer.log('Error in _extractContent: $e');
      return 'Error extracting content: $e';
    }
  }

  String _findArticleContent(Document document) {
    final List<String> contentSelectors = [
      'article', '.article-body', '.story-body', '#content', '.post-content', '.entry-content',
      'main', '.main-content', '.article-content', '.content-area'
    ];

    for (var selector in contentSelectors) {
      var element = document.querySelector(selector);
      if (element != null) {
        String content = _extractTextFromElement(element);
        developer.log('Found content with selector $selector. Length: ${content.length}');
        if (content.length > 100) {
          return content;
        }
      }
    }

    var paragraphs = document.querySelectorAll('p');
    if (paragraphs.isNotEmpty) {
      String content = paragraphs
          .map((p) => _cleanText(p.text))
          .where((text) => text.split(' ').length > 5)
          .join('\n\n');
      developer.log('Found content from paragraphs. Length: ${content.length}');
      if (content.length > 100) {
        return content;
      }
    }

    developer.log('Failed to extract article content');
    return 'Failed to extract article content.';
  }

  String _extractTextFromElement(Element element) {
    element.querySelectorAll('script, style').forEach((el) => el.remove());
    return _cleanText(element.text);
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\n\r]+'), '\n')
        .trim();
  }
}

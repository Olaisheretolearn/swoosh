import 'dart:convert';
import 'package:http/http.dart' as http;
import 'scraper_service.dart';

class NewsService {
  final String apiKey = '832444950e42438f96338d8b6047ba3a';
  final String baseUrl = 'https://newsapi.org/v2/top-headlines';

  // Modify the fetchNews method to accept an optional category parameter
  Future<List<NewsItem>> fetchNews({String category = 'general'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?country=us&category=$category&apiKey=$apiKey')
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['articles'];
        return articles.map((article) => NewsItem.fromJson(article)).toList();
      } else {
        throw Exception('Failed to load news: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}




class NewsItem {
  final String title;
  String description;
  String fullArticle;
  final String author;
  final String imageUrl;
  final String url;
  final String authorImageUrl;
  final String originalDescription; // Store the original description from the API

  NewsItem({
    required this.title,
    required this.description,
    this.fullArticle = '',
    required this.author,
    required this.imageUrl,
    required this.url,
    required this.authorImageUrl,
    required this.originalDescription,
  });

  void updateDescription(String newDescription) {
    this.description = newDescription;
  }

  void updateFullArticle(String newArticle) {
    this.fullArticle = newArticle;
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      author: json['author'] ?? 'Unknown',
      imageUrl: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
      authorImageUrl: json['authorImageUrl'] ?? 'assets/images/defaultImage.png',
      originalDescription: json['description'] ?? 'No Description',
    );
  }

  Future<void> fetchFullArticle() async {
    final scraperService = ScraperService();
    this.fullArticle = await scraperService.fetchArticleContent(url);
    // If scraping fails, use the original description
    if (this.fullArticle.startsWith('Error fetching article') || 
        this.fullArticle.startsWith('Failed to extract article content')) {
      this.fullArticle = this.originalDescription;
    }
  }

   Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'fullArticle': fullArticle,
      'author': author,
      'imageUrl': imageUrl,
      'url': url,
      'authorImageUrl': authorImageUrl,
      'originalDescription': originalDescription,
    };
  }
}
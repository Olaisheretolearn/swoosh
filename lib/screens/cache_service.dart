import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swoosh/screens/news_service.dart'; 

class CacheService {
  static const String _cacheKey = 'news_cache';

  Future<void> cacheNews(List<NewsItem> news) async {
    final prefs = await SharedPreferences.getInstance();
    final String newsJson = json.encode(news.map((item) => item.toJson()).toList());
    await prefs.setString(_cacheKey, newsJson);
  }

  Future<List<NewsItem>?> getCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? newsJson = prefs.getString(_cacheKey);
    if (newsJson != null) {
      final List<dynamic> newsData = json.decode(newsJson);
      return newsData.map((item) => NewsItem.fromJson(item)).toList();
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String source;
  final String publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      source: json['source']?['name'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
    );
  }
}

final newsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  const apiKey = '43a4b4ba122d1c27864f2d94b47ba404';
  const url =
      'https://gnews.io/api/v4/search?q=financas+investimento&lang=pt&country=br&max=8&apikey=$apiKey';

  try {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final articles = data['articles'] as List<dynamic>;
      return articles.map((a) => NewsArticle.fromJson(a)).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});


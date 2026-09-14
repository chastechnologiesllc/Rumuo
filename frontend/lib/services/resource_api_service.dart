import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ResourceRecord {
  final String id;
  final String title;
  final String summary;
  final Uri url;
  final String contentType;
  final String publisher;
  final String region;
  final String? license;
  final String trustState;
  final Uri provenanceUrl;
  final DateTime? verifiedAt;

  const ResourceRecord({required this.id, required this.title, required this.summary, required this.url, required this.contentType, required this.publisher, required this.region, required this.license, required this.trustState, required this.provenanceUrl, required this.verifiedAt});

  factory ResourceRecord.fromJson(Map<String, dynamic> json) => ResourceRecord(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    url: Uri.parse(json['url'] as String),
    contentType: json['content_type'] as String? ?? 'resource',
    publisher: json['publisher'] as String? ?? 'Unknown publisher',
    region: json['region'] as String? ?? 'global',
    license: json['license'] as String?,
    trustState: json['trust_state'] as String? ?? 'unreviewed',
    provenanceUrl: Uri.parse(json['provenance_url'] as String? ?? json['url'] as String),
    verifiedAt: DateTime.tryParse(json['verified_at'] as String? ?? ''),
  );
}

class ResourceApiService {
  const ResourceApiService();

  Future<List<ResourceRecord>> list({required String subcategory, String query = ''}) async {
    final base = AppConfig.resourceApiBaseUrl.trim();
    if (base.isEmpty) return const [];
    final uri = Uri.parse(base).replace(queryParameters: {
      'subcategory': subcategory,
      if (query.trim().isNotEmpty) 'q': query.trim(),
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception('Resource service returned ${response.statusCode}');
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = payload['data'] as List<dynamic>? ?? const [];
    return rows.whereType<Map<String, dynamic>>().map(ResourceRecord.fromJson).toList(growable: false);
  }
}

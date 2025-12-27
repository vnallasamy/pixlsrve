import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class APIClient extends ChangeNotifier {
  String? _baseUrl;
  String? _apiToken;
  bool _isVPNMode = false;

  String? get baseUrl => _baseUrl;
  bool get isVPNMode => _isVPNMode;
  bool get isConfigured => _apiToken != null && _baseUrl != null;

  void configure({
    required String baseUrl,
    required String apiToken,
    required bool isVPNMode,
  }) {
    _baseUrl = baseUrl;
    _apiToken = apiToken;
    _isVPNMode = isVPNMode;
    notifyListeners();
  }

  void switchToLAN(String lanAddress) {
    _baseUrl = 'http://$lanAddress:8080';
    _isVPNMode = false;
    notifyListeners();
  }

  void switchToVPN() {
    _baseUrl = 'http://10.100.0.1:8080';
    _isVPNMode = true;
    notifyListeners();
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_apiToken != null) 'Authorization': 'Bearer $_apiToken',
    };
  }

  // Public method to get auth headers for image requests
  Map<String, String> getAuthHeaders() {
    return {
      if (_apiToken != null) 'Authorization': 'Bearer $_apiToken',
    };
  }

  Future<Map<String, dynamic>> getDiscoveryInfo() async {
    if (_baseUrl == null) throw Exception('API not configured');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/discovery/info'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get discovery info: ${response.statusCode}');
    }
  }

  Future<List<Album>> getAlbums() async {
    if (_baseUrl == null) throw Exception('API not configured');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/albums'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final albumsJson = data['albums'] as List;
      return albumsJson.map((json) => Album.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - token expired or revoked');
    } else {
      throw Exception('Failed to get albums: ${response.statusCode}');
    }
  }

  Future<List<Photo>> getAlbumPhotos(String albumId) async {
    if (_baseUrl == null) throw Exception('API not configured');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/albums/$albumId/photos'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final photosJson = data['photos'] as List;
      return photosJson.map((json) => Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get photos: ${response.statusCode}');
    }
  }

  String getThumbnailUrl(String photoId, {String size = 'medium'}) {
    return '$_baseUrl/api/v1/photos/$photoId/thumbnail?size=$size';
  }

  String getFullPhotoUrl(String photoId) {
    return '$_baseUrl/api/v1/photos/$photoId/full';
  }

  Future<Map<String, dynamic>> getHostStatus() async {
    if (_baseUrl == null) throw Exception('API not configured');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/host/status'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get host status: ${response.statusCode}');
    }
  }
}

class Album {
  final String id;
  final String name;
  final String path;
  final int photoCount;
  final int sizeBytes;
  final String? coverPhotoId;
  final String? coverThumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Album({
    required this.id,
    required this.name,
    required this.path,
    required this.photoCount,
    required this.sizeBytes,
    this.coverPhotoId,
    this.coverThumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      photoCount: json['photo_count'] as int,
      sizeBytes: json['size_bytes'] as int,
      coverPhotoId: json['cover_photo_id'] as String?,
      coverThumbnailUrl: json['cover_thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class Photo {
  final String id;
  final String filename;
  final String albumId;
  final int sizeBytes;
  final int width;
  final int height;
  final String format;
  final DateTime? takenAt;
  final DateTime createdAt;
  final String thumbnailUrl;

  Photo({
    required this.id,
    required this.filename,
    required this.albumId,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.format,
    this.takenAt,
    required this.createdAt,
    required this.thumbnailUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      filename: json['filename'] as String,
      albumId: json['album_id'] as String,
      sizeBytes: json['size_bytes'] as int,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      format: json['format'] as String,
      takenAt: json['taken_at'] != null 
          ? DateTime.parse(json['taken_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      thumbnailUrl: json['thumbnail_url'] as String,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';

class AlbumPhotosScreen extends StatefulWidget {
  final Album album;

  const AlbumPhotosScreen({super.key, required this.album});

  @override
  State<AlbumPhotosScreen> createState() => _AlbumPhotosScreenState();
}

class _AlbumPhotosScreenState extends State<AlbumPhotosScreen> {
  List<Photo>? _photos;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = context.read<APIClient>();
      final photos = await apiClient.getAlbumPhotos(widget.album.id);
      
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPhotos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_photos == null || _photos!.isEmpty) {
      return const Center(
        child: Text('No photos in this album'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _photos!.length,
      itemBuilder: (context, index) {
        final photo = _photos![index];
        return _buildPhotoThumbnail(photo);
      },
    );
  }

  Widget _buildPhotoThumbnail(Photo photo) {
    final apiClient = context.read<APIClient>();

    return InkWell(
      onTap: () {
        _showPhotoDetail(photo);
      },
      child: Image.network(
        apiClient.getThumbnailUrl(photo.id, size: 'small'),
        fit: BoxFit.cover,
        headers: {'Authorization': 'Bearer ${apiClient._apiToken}'},
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          );
        },
      ),
    );
  }

  void _showPhotoDetail(Photo photo) {
    final apiClient = context.read<APIClient>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(photo.filename),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                apiClient.getFullPhotoUrl(photo.id),
                headers: {'Authorization': 'Bearer ${apiClient._apiToken}'},
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48),
                      SizedBox(height: 16),
                      Text('Failed to load photo'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

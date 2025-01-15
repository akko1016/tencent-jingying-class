import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../db/database_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/cached_photo_image.dart';

class SavedPhotosPage extends StatefulWidget {
  const SavedPhotosPage({super.key});

  @override
  State<SavedPhotosPage> createState() => _SavedPhotosPageState();
}

class _SavedPhotosPageState extends State<SavedPhotosPage> {
  late Future<List<Photo>> _savedPhotos;

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
  }

  void _loadSavedPhotos() {
    _savedPhotos = DatabaseHelper.instance.getSavedPhotos();
  }

  Future<void> _deletePhoto(Photo photo) async {
    await DatabaseHelper.instance.deletePhoto(photo.id);
    setState(() {
      _loadSavedPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('已保存的图片'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Photo>>(
        future: _savedPhotos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final photos = snapshot.data ?? [];
          
          if (photos.isEmpty) {
            return const Center(child: Text('没有保存的图片'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Card(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.asset(
                  photo.assetPath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            photo.author,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deletePhoto(photo),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
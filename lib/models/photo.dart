class Photo {
  final String id;
  final String author;
  final String assetPath;

  Photo({
    required this.id,
    required this.author,
    required this.assetPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author': author,
      'assetPath': assetPath,
    };
  }

  static Photo fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      author: map['author'],
      assetPath: map['assetPath'],
    );
  }
} 
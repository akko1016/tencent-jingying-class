import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('photos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print('数据库路径: $path'); // 调试信息

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: (db, version) async {
        print('正在创建数据库...'); // 调试信息
        await _createDB(db, version);
        print('数据库创建完成'); // 调试信息
      },
      onOpen: (db) async {
        // 验证表是否存在
        final tables = await db.query('sqlite_master', 
            where: 'type = ? AND name = ?',
            whereArgs: ['table', 'photos']);
        print('数据库表检查: ${tables.isNotEmpty ? "photos表存在" : "photos表不存在"}');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // 添加错误处理
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS photos (
          id TEXT PRIMARY KEY,
          author TEXT NOT NULL,
          assetPath TEXT NOT NULL
        )
      ''');
    } catch (e) {
      print('数据库创建错误: $e');
      rethrow;
    }
  }

  Future<bool> isPhotoSaved(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  Future<int> savePhoto(Photo photo) async {
    final db = await instance.database;
    return await db.insert('photos', photo.toMap());
  }

  Future<int> deletePhoto(String id) async {
    final db = await instance.database;
    return await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Photo>> getSavedPhotos() async {
    final db = await instance.database;
    final result = await db.query('photos');
    return result.map((map) => Photo.fromMap(map)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
} 
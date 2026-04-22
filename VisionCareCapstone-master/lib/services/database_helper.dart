import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'corn_disease.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnoses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disease TEXT,
        image_path TEXT,
        date TEXT
      )
    ''');
  }

  Future<int> insertDiagnosis(String disease, String imagePath) async {
    Database db = await database;
    return await db.insert(
      'diagnoses',
      {
        'disease': disease,
        'image_path': imagePath,
        'date': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getDiagnoses() async {
    Database db = await database;
    return await db.query('diagnoses', orderBy: 'date DESC');
  }

  Future<String> saveImage(File imageFile) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = '$path/$fileName';

    // Copy the file to the documents directory
    await imageFile.copy(filePath);

    return filePath;
  }
}

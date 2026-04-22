import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

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
    String path = join(documentsDirectory.path, 'diagnoses.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnoses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disease TEXT NOT NULL,
        date TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        confidence REAL,
        patientName TEXT,
        patientId TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN confidence REAL');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientName TEXT');
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientId TEXT');
      } catch (e) {
        print("Database upgrade error: $e");
      }
    }
  }

  /// Returns only the last 10 diagnoses
  Future<List<Map<String, dynamic>>> getDiagnoses() async {
    final db = await database;
    // Strictly limit to 10 for "Recent Results"
    return await db.query('diagnoses', orderBy: 'id DESC', limit: 10);
  }

  Future<void> ensureSchemaUpdated() async {
    final db = await database;
    try {
      var columns = await db.rawQuery('PRAGMA table_info(diagnoses)');
      if (!columns.any((column) => column['name'] == 'confidence')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN confidence REAL');
      }
      if (!columns.any((column) => column['name'] == 'patientName')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientName TEXT');
      }
      if (!columns.any((column) => column['name'] == 'patientId')) {
        await db.execute('ALTER TABLE diagnoses ADD COLUMN patientId TEXT');
      }
    } catch (e) {
      print("Error ensuring schema updated: $e");
    }
  }

  /// Inserts a new diagnosis and automatically deletes the oldest if count > 10
  Future<int> insertDiagnosis(String disease, String imagePath, double confidence, {String? patientName, String? patientId}) async {
    final db = await database;
    await ensureSchemaUpdated();

    // AUTO-DELETE LOGIC: Maintain only 10 most recent entries
    final List<Map<String, dynamic>> currentEntries = await db.query('diagnoses', orderBy: 'id DESC');
    
    if (currentEntries.length >= 10) {
      // Get all IDs except the 9 most recent ones to be safe
      // but strictly we delete anything beyond the 9th to make room for the 10th
      final idsToDelete = currentEntries.sublist(9).map((e) => e['id']).toList();
      
      for (var id in idsToDelete) {
        final entry = currentEntries.firstWhere((e) => e['id'] == id);
        String? oldPath = entry['imagePath'];
        if (oldPath != null && oldPath.isNotEmpty) {
          try {
            final file = File(oldPath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
        await db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
      }
      print("Auto-deleted ${idsToDelete.length} old entries to maintain 10-limit.");
    }

    return await db.insert(
      'diagnoses',
      {
        'disease': disease,
        'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()), // Using standard format for sorting
        'imagePath': imagePath,
        'confidence': confidence,
        'patientName': patientName,
        'patientId': patientId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> saveImage(File image) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    String path = join(documentsDirectory.path, fileName);
    await image.copy(path);
    return path;
  }

  Future<void> deleteDiagnosis(int id) async {
    final db = await database;
    await db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
  }
}

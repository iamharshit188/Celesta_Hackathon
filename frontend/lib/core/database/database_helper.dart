import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'wpfactcheck.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Articles table
    await db.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        content TEXT NOT NULL,
        url TEXT NOT NULL,
        urlToImage TEXT,
        publishedAt TEXT NOT NULL,
        sourceName TEXT NOT NULL,
        sourceId TEXT,
        author TEXT,
        category TEXT NOT NULL,
        isBookmarked INTEGER DEFAULT 0,
        cachedAt TEXT
      )
    ''');

    // Fact check results table
    await db.execute('''
      CREATE TABLE fact_check_results (
        id TEXT PRIMARY KEY,
        inputText TEXT NOT NULL,
        sourceUrl TEXT,
        verdict TEXT NOT NULL,
        confidenceScore REAL NOT NULL,
        explanation TEXT NOT NULL,
        sources TEXT NOT NULL,
        keyPoints TEXT NOT NULL,
        analyzedAt TEXT NOT NULL,
        isFromCache INTEGER DEFAULT 0,
        modelVersion TEXT
      )
    ''');

    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        displayName TEXT NOT NULL,
        email TEXT,
        avatarUrl TEXT,
        createdAt TEXT NOT NULL,
        lastLoginAt TEXT NOT NULL,
        isOnboardingCompleted INTEGER DEFAULT 0,
        preferences TEXT NOT NULL,
        totalAnalyses INTEGER DEFAULT 0,
        totalBookmarks INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_articles_category ON articles(category)');
    await db.execute('CREATE INDEX idx_articles_published ON articles(publishedAt)');
    await db.execute('CREATE INDEX idx_articles_bookmarked ON articles(isBookmarked)');
    await db.execute('CREATE INDEX idx_fact_check_analyzed ON fact_check_results(analyzedAt)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Batch operations
  Future<void> executeBatch(List<String> statements) async {
    final db = await database;
    final batch = db.batch();
    
    for (final statement in statements) {
      batch.execute(statement);
    }
    
    await batch.commit();
  }

  // Cleanup operations
  Future<void> cleanupOldArticles() async {
    final db = await database;
    
    // Keep only the latest articles based on the limit
    await db.execute('''
      DELETE FROM articles 
      WHERE id NOT IN (
        SELECT id FROM articles 
        ORDER BY publishedAt DESC 
        LIMIT ${AppConstants.maxCachedArticles}
      )
    ''');
  }

  Future<void> cleanupOldAnalyses() async {
    final db = await database;
    
    // Keep only the latest analyses based on the limit
    await db.execute('''
      DELETE FROM fact_check_results 
      WHERE id NOT IN (
        SELECT id FROM fact_check_results 
        ORDER BY analyzedAt DESC 
        LIMIT ${AppConstants.maxCachedAnalyses}
      )
    ''');
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<int> getDatabaseSize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'wpfactcheck.db');
    final file = await File(path).stat();
    return file.size;
  }

  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();
    
    batch.delete('articles');
    batch.delete('fact_check_results');
    batch.delete('user_profiles');
    
    await batch.commit();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}


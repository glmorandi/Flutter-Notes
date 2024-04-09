import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:notes_trab/models/note.dart';

class DatabaseHelper {
  static const _databaseName = "notes_database.db";
  static const _databaseVersion = 1;

  static const table = 'notes';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnContent = 'content';
  static const columnlastUpdate = 'lastUpdate';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnContent TEXT NOT NULL,
            $columnlastUpdate TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Note note) async {
    Database db = await database;
    return await db.insert(table, note.toMap());
  }

  Future<List<Note>> getAllNotes() async {
    Database db = await database;
    List<Map> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i][columnId],
        title: maps[i][columnTitle],
        content: maps[i][columnContent],
        lastUpdate: maps[i][columnlastUpdate],
      );
    });
  }

  Future<List<Note>> searchNotes(String query) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
        lastUpdate: maps[i]['lastUpdate'],
      );
    });
  }

  Future<int> update(Note note) async {
    Database db = await database;
    return await db.update(table, note.toMap(),
        where: '$columnId = ?', whereArgs: [note.id]);
  }

  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> deleteAllNotes() async {
    Database db = await database;
    await db.delete(table);
  }

  Future<void> deleteDatabase() async {
    Database db = await database;
    if (_database != null) {
      await db.close();
      _database = null;
    }
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, _databaseName);
    if (await File(path).exists()) {
      File(path).delete();
    }
  }
}

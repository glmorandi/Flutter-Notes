import 'dart:async';
import 'dart:io';

import 'package:notes_trab/models/note_tag.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:notes_trab/models/note.dart';
import 'package:notes_trab/models/tag.dart';

class DatabaseHelper {
  static const _databaseName = "notes_database.db";
  static const _databaseVersion = 1;

  static const notesTable = 'notes';
  static const tagsTable = 'tags';
  static const noteTagsTable = 'note_tags';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnContent = 'content';
  static const columnlastUpdate = 'lastUpdate';

  static const tagsColumnId = 'id';
  static const tagsColumnName = 'name';

  static const noteTagsColumnNoteId = 'noteId';
  static const noteTagsColumnTagId = 'tagId';

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
          CREATE TABLE $notesTable (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnContent TEXT NOT NULL,
            $columnlastUpdate TEXT NOT NULL
          )
          ''');

    await db.execute('''
      CREATE TABLE $tagsTable (
        $tagsColumnId INTEGER PRIMARY KEY,
        $tagsColumnName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $noteTagsTable (
        $noteTagsColumnNoteId INTEGER,
        $noteTagsColumnTagId INTEGER,
        PRIMARY KEY ($noteTagsColumnNoteId, $noteTagsColumnTagId),
        FOREIGN KEY ($noteTagsColumnNoteId) REFERENCES $notesTable($columnId),
        FOREIGN KEY ($noteTagsColumnTagId) REFERENCES $tagsTable($tagsColumnId)
      )
    ''');
  }

  Future<int> insert(Note note) async {
    Database db = await database;
    return await db.insert(notesTable, note.toMap());
  }

  Future<int> insertTag(String name) async {
    Database db = await database;
    Map<String, dynamic> row = {tagsColumnName: name};
    int id = await db.insert(tagsTable, row);
    return id;
  }

  Future<List<Tag>> getAllTagsById(int tagId) async {
    Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(tagsTable,
        columns: [tagsColumnId, tagsColumnName],
        where: '$tagsColumnId = ?',
        whereArgs: [tagId]);
    return List.generate(rows.length, (i) {
      return Tag(
        id: rows[i][tagsColumnId],
        name: rows[i][tagsColumnName],
      );
    });
  }

  Future<List<NoteTag>> getAllNoteTagsForNote(int noteId) async {
    Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(noteTagsTable,
        columns: [noteTagsColumnNoteId, noteTagsColumnTagId],
        where: '$noteTagsColumnNoteId = ?',
        whereArgs: [noteId]);
    return List.generate(rows.length, (i) {
      return NoteTag(
        noteId: rows[i][noteTagsColumnNoteId],
        tagId: rows[i][noteTagsColumnTagId],
      );
    });
  }

  Future<bool> tagExists(int tagId) async {
    Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(tagsTable,
        columns: [tagsColumnId],
        where: '$tagsColumnId = ?',
        whereArgs: [tagId]);
    return rows.isNotEmpty;
  }

  Future<bool> noteTagExists(int noteId, int tagId) async {
    Database db = await database;
    List<Map<String, dynamic>> rows = await db.query(
      noteTagsTable,
      where: '$noteTagsColumnNoteId = ? AND $noteTagsColumnTagId = ?',
      whereArgs: [noteId, tagId],
    );
    return rows.isNotEmpty;
  }

  Future<int> insertNoteTag(NoteTag noteTag) async {
    Database db = await database;
    int id = await db.insert(noteTagsTable, noteTag.toMap());
    return id;
  }

  Future<void> deleteNoteTagsForNote(int noteId) async {
    Database db = await database;
    await db.delete(
      noteTagsTable,
      where: '$noteTagsColumnNoteId = ?',
      whereArgs: [noteId],
    );
  }

  Future<List<Note>> getAllNotes() async {
    Database db = await database;
    List<Map> maps = await db.query(notesTable);
    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i][columnId],
        title: maps[i][columnTitle],
        content: maps[i][columnContent],
        lastUpdate: maps[i][columnlastUpdate],
      );
    });
  }

  Future<List<Tag>> getAllTagsForNote(int noteId) async {
    Database db = await database;
    List<Map<String, dynamic>> noteTagMaps = await db.query(
      noteTagsTable,
      where: '$noteTagsColumnNoteId = ?',
      whereArgs: [noteId],
    );

    List<Tag> tags = [];
    for (var noteTagMap in noteTagMaps) {
      int tagId = noteTagMap[noteTagsColumnTagId];
      List<Map<String, dynamic>> tagMaps = await db.query(
        tagsTable,
        where: '$tagsColumnId = ?',
        whereArgs: [tagId],
      );
      if (tagMaps.isNotEmpty) {
        Tag tag = Tag.fromMap(tagMaps.first);
        tags.add(tag);
      }
    }
    return tags;
  }

  Future<List<Note>> searchNotes(String query) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT DISTINCT notes.* FROM notes
    LEFT JOIN note_tags ON notes.id = note_tags.noteId
    LEFT JOIN tags ON note_tags.tagId = tags.id
    WHERE notes.title LIKE ? OR notes.content LIKE ? OR tags.name LIKE ?
  ''', ['%$query%', '%$query%', '%$query%']);
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
    return await db.update(notesTable, note.toMap(),
        where: '$columnId = ?', whereArgs: [note.id]);
  }

  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(notesTable, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteAllNotes() async {
    Database db = await database;
    return await db.delete(notesTable);
  }

  Future<int> deleteTag(int id) async {
    Database db = await database;
    return await db
        .delete(tagsTable, where: '$tagsColumnId = ?', whereArgs: [id]);
  }

  Future<int> deleteNoteTag(int noteId, int tagId) async {
    Database db = await database;
    return await db.delete(
      noteTagsTable,
      where: '$noteTagsColumnNoteId = ? AND $noteTagsColumnTagId = ?',
      whereArgs: [noteId, tagId],
    );
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

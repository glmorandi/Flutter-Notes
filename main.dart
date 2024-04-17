import 'package:notes_trab/db/database_helper.dart';
import 'package:notes_trab/models/note.dart';
import 'package:flutter/material.dart';
import 'package:notes_trab/models/note_tag.dart';
import 'package:notes_trab/models/tag.dart';
import 'dart:math';

import 'package:notes_trab/screens/about.dart';
import 'package:notes_trab/screens/note_details.dart';
import 'package:notes_trab/screens/search.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  var dbHelper = DatabaseHelper.instance;
  final List<Note> _notes = [];

  void loadNotes() async {
    var n = await dbHelper.getAllNotes();

    setState(() {
      _notes.clear();
      _notes.addAll(n);
    });
  }

  String randomString() {
    var random = Random();

    const availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

    var length = random.nextInt(100);

    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();

    return randomString;
  }

  Future<void> insertRandomNote() async {
    var random = Random();
    DatabaseHelper databaseHelper = DatabaseHelper.instance;

    Note randomNote = Note(
      title: 'Random Note ${random.nextInt(100)}',
      content: randomString(),
      lastUpdate: DateTime.now().toString(),
    );

    final id = await databaseHelper.insert(randomNote);

    print('Note added with ID $id');

    loadNotes();
  }

  Future<void> deleteAllNotes() async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;

    await databaseHelper.deleteAllNotes();

    loadNotes();
  }

  Future<void> deleteDatabase() async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;

    await databaseHelper.deleteDatabase();

    loadNotes();
  }

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  void _openAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutPage(),
      ),
    );
  }

  void _openSearch(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
    loadNotes();
  }

  Future<List<String>> _getTagsForNote(int noteId) async {
    List<String> tags = [];
    List<NoteTag> noteTags =
        await DatabaseHelper.instance.getAllNoteTagsForNote(noteId);
    for (var noteTag in noteTags) {
      List<Tag> tag =
          await DatabaseHelper.instance.getAllTagsById(noteTag.tagId!);
      for (Tag t in tag) {
        tags.add(t.name ?? '');
      }
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Notes'),
          actions: [
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                    onPressed: () => _openSearch(context),
                    icon: const Icon(Icons.search));
              },
            ),
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                    onPressed: () => _openAbout(context),
                    icon: const Icon(Icons.info_outline));
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3.0, horizontal: 6.0),
                        child: ListTile(
                          title: Text(_notes[index].title ?? 'No title'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_notes[index].lastUpdate ?? ''),
                              FutureBuilder<List<String>>(
                                future: _getTagsForNote(_notes[index].id!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.waiting ||
                                      !snapshot.hasData) {
                                    return const SizedBox();
                                  } else {
                                    return Wrap(
                                      spacing: 4,
                                      children: snapshot.data!
                                          .map((tag) => Chip(
                                                label: Text(tag),
                                              ))
                                          .toList(),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            var param = _notes[index];
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            NoteDetail(noteDetails: param)))
                                .then((value) {
                              loadNotes();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  insertRandomNote();
                                },
                                child: const Text('Random Note')),
                            ElevatedButton(
                                onPressed: () {
                                  deleteDatabase();
                                },
                                child: const Text('Delete database')),
                          ],
                        ),
                        Builder(
                          builder: (BuildContext context) {
                            return FloatingActionButton(
                              child: const Icon(Icons.note_add),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NoteDetail(
                                      noteDetails: null,
                                    ),
                                  ),
                                ).then((value) {
                                  loadNotes();
                                });
                              },
                            );
                          },
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

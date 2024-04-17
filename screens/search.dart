import 'package:flutter/material.dart';
import 'package:notes_trab/db/database_helper.dart';
import 'package:notes_trab/models/note.dart';
import 'package:notes_trab/models/note_tag.dart';
import 'package:notes_trab/models/tag.dart';
import 'package:notes_trab/screens/note_details.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final note = _searchResults[index];
                  return ListTile(
                    title: Text(note.title ?? 'No Title'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.content ?? 'No Content'),
                        const SizedBox(height: 4),
                        FutureBuilder<List<String>>(
                          future: _getTagsForNote(note.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                !snapshot.hasData) {
                              return const SizedBox();
                            } else {
                              return Wrap(
                                spacing: 4,
                                children: snapshot.data!
                                    .map((tag) => Chip(label: Text(tag)))
                                    .toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(noteDetails: note),
                        ),
                      );
                      if(result != null && result as bool){
                        _searchResults.clear();
                        _search();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _search() async {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      List<Note> results = await DatabaseHelper.instance.searchNotes(query);
      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
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
}

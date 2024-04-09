import 'package:flutter/material.dart';
import 'package:notes_trab/db/database_helper.dart';
import 'package:notes_trab/models/note.dart';
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
                    subtitle: Text(note.content ?? 'No Content'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(noteDetails: note),
                        ),
                      );
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

  void _search() async {
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
}

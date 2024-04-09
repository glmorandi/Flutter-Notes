import 'package:flutter/material.dart';
import 'package:notes_trab/db/database_helper.dart';
import 'package:notes_trab/models/note.dart';

class NoteDetail extends StatefulWidget {
  const NoteDetail({super.key, required this.noteDetails});

  final Note? noteDetails;

  @override
  State<NoteDetail> createState() => _NoteDetailState();
}

class _NoteDetailState extends State<NoteDetail> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.noteDetails?.title ?? '');
    _contentController =
        TextEditingController(text: widget.noteDetails?.content ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleController.value.text.isNotEmpty
            ? _titleController.value.text
            : 'New note'),
        actions: [
          IconButton(
            onPressed: () {
              _deleteNote();
            },
            icon: const Icon(Icons.delete),
          ),
          IconButton(
              onPressed: () {
                _saveNote();
              },
              icon: const Icon(Icons.save))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    final updatedNote = Note(
      id: widget.noteDetails?.id,
      title: _titleController.text,
      content: _contentController.text,
      lastUpdate: DateTime.now().toIso8601String(),
    );
    if (updatedNote.id != null) {
      databaseHelper.update(updatedNote);
      print('Note saved: $updatedNote');
    } else {
      final newNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        lastUpdate: DateTime.now().toIso8601String(),
      );
      databaseHelper.insert(newNote);
      print('New note created: $newNote');
    }
  }

  void _deleteNote() {
    final id = widget.noteDetails?.id;
    if (id != null) {
      databaseHelper.delete(id);
    }
    print('Note deleted: ${widget.noteDetails?.id}');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:notes_trab/db/database_helper.dart';
import 'package:notes_trab/models/note.dart';
import 'package:notes_trab/models/tag.dart';
import 'package:notes_trab/models/note_tag.dart';

class NoteDetail extends StatefulWidget {
  const NoteDetail({Key? key, required this.noteDetails}) : super(key: key);

  final Note? noteDetails;

  @override
  State<NoteDetail> createState() => _NoteDetailState();
}

class _NoteDetailState extends State<NoteDetail> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<Tag> _tags = [];
  String _tagInput = '';
  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.noteDetails?.title ?? '');
    _contentController =
        TextEditingController(text: widget.noteDetails?.content ?? '');
    if (widget.noteDetails != null) {
      _loadTags();
    }
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
            icon: const Icon(Icons.save),
          ),
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
            const SizedBox(height: 8),
            _buildTagInput(),
            const SizedBox(height: 8),
            _buildTagsChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              setState(() {
                _tagInput = value;
              });
            },
            onSubmitted: (_) {
              _addTag();
            },
            decoration: const InputDecoration(
              labelText: 'Tag',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsChips() {
    return Wrap(
      spacing: 8,
      children: _tags.map((tag) {
        return InputChip(
          label: Text(tag.name!),
          onDeleted: () {
            _removeTag(tag);
          },
        );
      }).toList(),
    );
  }

  void _addTag() async {
    if (_tagInput.isNotEmpty) {
      final insertedTagId = await databaseHelper.insertTag(_tagInput);
      final newTag = Tag(id: insertedTagId, name: _tagInput);
      setState(() {
        _tags.add(newTag);
        _tagInput = '';
      });
    }
  }

  void _removeTag(Tag tag) async {
    print('Removing tag');
    setState(() {
      _tags.remove(tag);
    });

    if (widget.noteDetails != null && tag.id != null) {
      await DatabaseHelper.instance
          .deleteNoteTag(widget.noteDetails!.id!, tag.id!);
    }
  }

  void _loadTags() async {
    final List<NoteTag> noteTags =
        await databaseHelper.getAllNoteTagsForNote(widget.noteDetails!.id!);
    List<Tag> tags = [];
    for (var noteTag in noteTags) {
      final List<Tag> tag = await databaseHelper.getAllTagsById(noteTag.tagId!);
      tags.addAll(tag);
    }
    setState(() {
      _tags = tags;
    });
  }

  void _saveNote() async {
    final updatedNote = Note(
      id: widget.noteDetails?.id,
      title: _titleController.text,
      content: _contentController.text,
      lastUpdate: DateTime.now().toIso8601String(),
    );

    if (updatedNote.id != null) {
      await databaseHelper.update(updatedNote);
      for (var tag in _tags) {
        int tagId = tag.id!;
        if (!(await databaseHelper.noteTagExists(updatedNote.id!, tagId))) {
          if (!(await databaseHelper.tagExists(tagId))) {
            tagId = await databaseHelper.insertTag(tag.name!);
          }
          final insertedNoteTagId = await databaseHelper
              .insertNoteTag(NoteTag(noteId: updatedNote.id!, tagId: tagId));
          print('Note-Tag relation created: $insertedNoteTagId');
        }
      }
      print('Note saved: $updatedNote');
    } else {
      final newNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        lastUpdate: DateTime.now().toIso8601String(),
      );
      final insertedNoteId = await databaseHelper.insert(newNote);
      print('New note created: $newNote');

      for (var tag in _tags) {
        final insertedNoteTagId = await databaseHelper
            .insertNoteTag(NoteTag(noteId: insertedNoteId, tagId: tag.id!));
        print('Note-Tag relation created: $insertedNoteTagId');
      }
    }
    Navigator.pop(context);
  }

  void _deleteNote() async {
    final id = widget.noteDetails?.id;
    if (id != null) {
      await databaseHelper.delete(id);
      await databaseHelper.deleteNoteTagsForNote(id);
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

class NoteTag {
  int? noteId;
  int? tagId;

  NoteTag({
    this.noteId,
    this.tagId,
  });

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'tagId': tagId,
    };
  }

  static NoteTag fromMap(Map<String, dynamic> map) {
    return NoteTag(
      noteId: map['noteId'],
      tagId: map['tagId'],
    );
  }
}

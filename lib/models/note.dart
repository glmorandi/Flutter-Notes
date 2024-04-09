class Note {
  int? id;
  String? title;
  String? content;
  String? lastUpdate;

  Note({
    this.id,
    this.title,
    this.content,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'lastUpdate': lastUpdate,
    };
  }

  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      lastUpdate: map['lastUpdate'],
    );
  }
}

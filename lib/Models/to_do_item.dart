class ToDoItem {
  final String id;
  final String listId;
  final String title;
  final String content;
  bool done;
  int index;

  ToDoItem({
    required this.id,
    required this.listId,
    required this.title,
    required this.content,
    required this.done,
    required this.index,
  });
}

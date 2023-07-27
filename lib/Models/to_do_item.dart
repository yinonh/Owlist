class ToDoItem {
  final String id;
  final String listId;
  final String title;
  final String description;
  bool done;
  int index;

  ToDoItem({
    required this.id,
    required this.listId,
    required this.title,
    required this.description,
    required this.done,
    required this.index,
  });
}

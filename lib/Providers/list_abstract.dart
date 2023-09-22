import '../Models/to_do_list.dart';

abstract class ListProviderAbstract {
  List<ToDoList>? _activeItemsCache;
  List<ToDoList>? _achievedItemsCache;
  List<ToDoList>? _withoutDeadlineItemsCache;

  Future<List<ToDoList>> getActiveItems();
  Future<List<ToDoList>> getAchievedItems();
  // Future<void> add_new_list(ToDoList newList);
  Future<void> createNewList(String title, DateTime deadline, bool hasDeadline);
  Future<void> deleteList(String listId);
  Future<String?> getItemTitleById(String id);
  Future<bool> isListDone(String listId);
  Future<void> editDeadline(String listId, DateTime? newDeadline);
  Future<void> editTitle(String listId, String? newTitle);
}

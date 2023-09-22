import '../Models/to_do_item.dart';

abstract class ItemsAbstract {
  Future<List<ToDoItem>> itemsByListId(String listId);
  Future<ToDoItem?> addNewItem(String listId, String title);
  Future<void> deleteItemById(String id, bool isDone);
  Future<void> toggleItemDone(String itemId, String listId, bool isDone);
  Future<void> editIndex(String itemId, int newIndex);
}

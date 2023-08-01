import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/to_do_item.dart';
import '../Providers/lists_provider.dart';

class ItemProvider with ChangeNotifier {
  Future<List<ToDoItem>> itemsByListId(String listId) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('todoItems')
          .where('listId', isEqualTo: listId)
          .get();

      return snapshot.docs.map((doc) {
        return ToDoItem(
          id: doc.id,
          listId: doc['listId'],
          title: doc['title'],
          content: doc['content'],
          done: doc['done'],
          index: doc['index'],
        );
      }).toList();
    } catch (error) {
      print("Error fetching data: $error");
      return [];
    }
  }

  Future<void> addNewItem(String listId, String title) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('todoItems')
          .where('listId', isEqualTo: listId)
          .orderBy('index', descending: true)
          .limit(1)
          .get();

      int newIndex = 0;

      if (snapshot.docs.isNotEmpty) {
        final highestIndexItem = snapshot.docs.first;
        final highestIndex = highestIndexItem['index'] as int;
        newIndex = highestIndex + 1;
      }

      final newItemData = {
        'listId': listId,
        'title': title,
        'content': '',
        'done': false,
        'index': newIndex,
      };

      await FirebaseFirestore.instance.collection('todoItems').add(newItemData);

      // Update totalItems in todo_lists collection
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);
      await listRef.update({'totalItems': FieldValue.increment(1)});

      notifyListeners();
    } catch (error) {
      print("Error adding new item: $error");
    }
  }

  Future<void> deleteItemById(String id, bool isDone) async {
    try {
      final itemSnapshot = await FirebaseFirestore.instance
          .collection('todoItems')
          .doc(id)
          .get();
      final listId = itemSnapshot['listId'] as String;

      await FirebaseFirestore.instance.collection('todoItems').doc(id).delete();

      // Update totalItems and accomplishedItems in todo_lists collection
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);

      final Map<String, dynamic> listData = {};
      if (isDone) {
        listData['accomplishedItems'] = FieldValue.increment(-1);
      }
      listData['totalItems'] = FieldValue.increment(-1);

      await listRef.update(listData);

      print('Item with ID $id deleted successfully!');
    } catch (e) {
      print('Error deleting item: $e');
    }
    notifyListeners();
  }
}

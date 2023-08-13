import 'dart:math';

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

  Future<ToDoItem?> addNewItem(String listId, String title) async {
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

      final newItemRef = await FirebaseFirestore.instance
          .collection('todoItems')
          .add(newItemData);

      // Update totalItems in todo_lists collection
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);
      await listRef.update({'totalItems': FieldValue.increment(1)});

      final newItem = ToDoItem(
        id: newItemRef.id,
        listId: listId,
        title: title,
        content: '',
        done: false,
        index: newIndex,
      );

      notifyListeners();

      return newItem;
    } catch (error) {
      print("Error adding new item: $error");
      return null;
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

  Future<void> toggleItemDone(String itemId, String listId, bool isDone) async {
    try {
      final itemRef =
          FirebaseFirestore.instance.collection('todoItems').doc(itemId);

      // Fetch the current item data
      final DocumentSnapshot<Map<String, dynamic>> itemSnapshot =
          await itemRef.get();
      final bool currentDoneValue = itemSnapshot.data()!['done'] as bool;

      // Toggle the 'done' field value
      await itemRef.update({'done': !currentDoneValue});

      // Fetch the list data to update 'accomplishedItems'
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);
      final DocumentSnapshot<Map<String, dynamic>> listSnapshot =
          await listRef.get();
      int accomplishedItems = listSnapshot.data()!['accomplishedItems'] as int;

      if (currentDoneValue) {
        accomplishedItems--;
      } else {
        accomplishedItems++;
      }

      await listRef.update({'accomplishedItems': accomplishedItems});

      notifyListeners();
    } catch (error) {
      print("Error toggling item's done state: $error");
    }
  }

  Future<void> editIndex(String itemId, int newIndex) async {
    print(itemId + " " + newIndex.toString());
    try {
      final itemRef =
          FirebaseFirestore.instance.collection('todoItems').doc(itemId);

      // Update the 'index' field value
      await itemRef.update({'index': newIndex});

      // Notify listeners or perform any other necessary actions
      notifyListeners();
    } catch (error) {
      print("Error editing item index: $error");
    }
  }
}

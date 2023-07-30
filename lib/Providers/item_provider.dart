import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/to_do_item.dart';

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
          .orderBy('index',
              descending: true) // Order by index in descending order
          .limit(1) // Limit to the first item (which has the highest index)
          .get();

      int newIndex = 0; // Default index if no items are found

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
      notifyListeners();
    } catch (error) {
      print("Error adding new item: $error");
    }
  }
}

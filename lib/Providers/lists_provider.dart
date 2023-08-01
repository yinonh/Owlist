import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Models/to_do_list.dart';

class ListsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ToDoList>? _activeItemsCache;
  List<ToDoList>? _achievedItemsCache;

  Future<List<ToDoList>> getActiveItems() async {
    if (_activeItemsCache != null) {
      return _activeItemsCache!;
    }

    DateTime currentDate = DateTime.now();
    String userId = _auth.currentUser!.uid;

    QuerySnapshot snapshot = await _firestore
        .collection('todo_lists')
        .where('userID', isEqualTo: userId)
        .get();

    _activeItemsCache = snapshot.docs
        .where((doc) {
          var deadline = DateTime.parse(doc['deadline']);
          return (doc['accomplishedItems'] < doc['totalItems'] ||
                  doc['totalItems'] == 0) &&
              deadline.isAfter(currentDate);
        })
        .map((doc) => ToDoList.fromSnapshot(doc))
        .toList();

    return _activeItemsCache!;
  }

  Future<List<ToDoList>> getAchievedItems() async {
    if (_achievedItemsCache != null) {
      return _achievedItemsCache!;
    }

    DateTime currentDate = DateTime.now();
    String userId = _auth.currentUser!.uid;

    QuerySnapshot snapshot = await _firestore
        .collection('todo_lists')
        .where('userID', isEqualTo: userId)
        .get();

    _achievedItemsCache = snapshot.docs
        .where((doc) {
          var deadline = DateTime.parse(doc['deadline']);
          return (doc['accomplishedItems'] == doc['totalItems'] &&
                  doc['totalItems'] > 0) ||
              deadline.isBefore(currentDate);
        })
        .map((doc) => ToDoList.fromSnapshot(doc))
        .toList();

    return _achievedItemsCache!;
  }

  Future<void> add_new_list(ToDoList newList) async {
    try {
      await _firestore.collection('todo_lists').add(newList.toMap());
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
  }

  Future<void> createNewList(String title, DateTime deadline) async {
    String userId = _auth.currentUser!.uid;

    ToDoList newList = ToDoList(
      id: '', // Empty ID, as Firestore will generate a new ID when adding the document
      userID: userId,
      title: title,
      creationDate: DateTime.now(),
      deadline: deadline,
      totalItems: 0,
      accomplishedItems: 0,
    );

    await add_new_list(newList).then((_) {
      invalidateCache();
      notifyListeners();
    });
  }

  Future<void> deleteList(String listId) async {
    try {
      final QuerySnapshot itemSnapshot = await _firestore
          .collection('todoItems')
          .where('listId', isEqualTo: listId)
          .get();

      // Delete each item that matches the listId
      for (final doc in itemSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the list itself
      await _firestore.collection('todo_lists').doc(listId).delete();

      invalidateCache();
      notifyListeners();
    } catch (e) {
      print('Error deleting list and its items: $e');
    }
  }

  Future<String?> getItemTitleById(String id) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('todo_lists')
              .doc(id)
              .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data()!;
        String title = data['title'];
        return title;
      } else {
        print('Item with ID $id not found!');
        return null;
      }
    } catch (e) {
      print('Error fetching item: $e');
      return null;
    }
  }
}

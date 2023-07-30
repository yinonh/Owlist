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

  // Method to add a new list to Firebase Cloud Firestore
  Future<void> add_new_list(ToDoList newList) async {
    try {
      await _firestore.collection('todo_lists').add(newList.toMap());
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  // Method to invalidate the cache and clear the stored data
  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
  }

  // Function to create and add a new list item to Firestore
  Future<void> createNewList(String title, DateTime deadline) async {
    String userId = _auth.currentUser!.uid;

    // Create a new ToDoList object
    ToDoList newList = ToDoList(
      id: '', // Empty ID, as Firestore will generate a new ID when adding the document
      userID: userId,
      title: title,
      creationDate: DateTime.now(), // Use the current date as the creation date
      deadline: deadline,
      totalItems: 0, // Initialize total items to 0
      accomplishedItems: 0, // Initialize accomplished items to 0
    );

    // Add the new list to Firestore
    await add_new_list(newList).then((_) {
      invalidateCache();
      notifyListeners();
    });

    // Invalidate the cache to reflect the updated data
  }

  // Function to delete a list item from Firestore by its ID
  Future<void> deleteList(String listId) async {
    try {
      // Fetch the items with the matching listId
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
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/to_do_list.dart';

class ListsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ToDoList>> getActiveItems() async {
    DateTime currentDate = DateTime.now();
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot deadlineSnapshot = await FirebaseFirestore.instance
        .collection('todo_lists')
        .where('userID', isEqualTo: userId)
        .where('deadline', isGreaterThan: currentDate)
        .get();

    QuerySnapshot accomplishedSnapshot = await FirebaseFirestore.instance
        .collection('todo_lists')
        .where('userID', isEqualTo: userId)
        .where('accomplishedItems', isLessThan: 'totalItems')
        .get();

    // Combine the results of both queries
    List<ToDoList> activeItems = [];
    activeItems
        .addAll(deadlineSnapshot.docs.map((doc) => ToDoList.fromSnapshot(doc)));
    activeItems.addAll(
        accomplishedSnapshot.docs.map((doc) => ToDoList.fromSnapshot(doc)));

    return activeItems;
  }

  // Method to get achieved items that have passed the deadline or are fully accomplished
  Future<List<ToDoList>> getAchievedItems() async {
    DateTime currentDate = DateTime.now();

    QuerySnapshot snapshot = await _firestore
        .collection('todo_lists')
        .where('userID', isEqualTo: _auth.currentUser!.uid)
        .where('deadline', isLessThanOrEqualTo: currentDate)
        .get();

    return snapshot.docs.map((doc) => ToDoList.fromSnapshot(doc)).toList();
  }

  // Method to add a new list to Firebase Cloud Firestore
  Future<void> add_new_list(ToDoList newList) async {
    try {
      await _firestore.collection('todo_lists').add(newList.toMap());
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  // Modify existingItems to a stream that listens to changes in Firestore
  Stream<List<ToDoList>> get existingItemsStream {
    return _firestore
        .collection('todo_lists')
        .where('userID', isEqualTo: _auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ToDoList.fromSnapshot(doc)).toList());
  }
}

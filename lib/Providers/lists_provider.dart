import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
// import 'package:workmanager/workmanager.dart';

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
    if (_activeItemsCache != null)
      _activeItemsCache!
          .sort((a, b) => a.notificationIndex.compareTo(b.notificationIndex));

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

    if (_achievedItemsCache != null)
      _achievedItemsCache!
          .sort((a, b) => a.notificationIndex.compareTo(b.notificationIndex));

    return _achievedItemsCache!;
  }

  Future<void> add_new_list(ToDoList newList) async {
    try {
      await _firestore.collection('todo_lists').add(newList.toMap());
      if (newList.hasDeadline) {
        // && newList.deadline.isAfter(DateTime.now().add(Duration(days: 7)))) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: newList.notificationIndex,
            channelKey: 'task_deadline_channel',
            title: '${newList.title}',
            body: 'Task deadline is about to end',
            color: Color(0xFF635985),
            // groupKey: "1",
          ),
          schedule: NotificationCalendar.fromDate(
            date: DateTime.now().add(
              Duration(seconds: 30),
            ),
          ),
        );
        // final selectedDate = DateTime.now().add(Duration(seconds: 30));
        // final isoFormattedDate = selectedDate.toIso8601String();
        // Workmanager().registerOneOffTask(
        //   '12',
        //   '23',
        //   inputData: {
        //     'notificationDate': isoFormattedDate,
        //   },
        // );
      }
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
  }

  // int generateUniqueNumber() {
  //   DateTime now = DateTime.now();
  //   int year = now.year % 100; // Use only the last two digits
  //   int month = now.month;
  //   int day = now.day;
  //   int minutes = now.minute;
  //   int seconds = now.second;
  //
  //   int uniqueNumber = year * 100000000 +
  //       month * 1000000 +
  //       day * 10000 +
  //       minutes * 100 +
  //       seconds;
  //
  //   return uniqueNumber;
  // }

  Future<void> createNewList(
      String title, DateTime deadline, bool hasDeadline) async {
    try {
      String userId = _auth.currentUser!.uid;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('todo_lists')
          .where('userID', isEqualTo: userId)
          .orderBy('notification_index', descending: true)
          .limit(1)
          .get();

      int notificationIndex = 0;

      if (snapshot.docs.isNotEmpty) {
        final highestIndexItem = snapshot.docs.first;
        final highestIndex = highestIndexItem['notification_index'] as int;
        notificationIndex = highestIndex + 1;
      }

      ToDoList newList = ToDoList(
        id: '',
        userID: userId,
        notificationIndex: notificationIndex,
        hasDeadline: hasDeadline,
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
    } catch (error) {
      print("Error adding new item: $error");
      return null;
    }
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

  Future<bool> isListDone(String listId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('todo_lists')
              .doc(listId)
              .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data()!;
        int totalItems = data['totalItems'];
        int accomplishedItems = data['accomplishedItems'];
        DateTime deadline = DateTime.parse(data['deadline']);

        bool allItemsAccomplished =
            totalItems > 0 && accomplishedItems == totalItems;
        bool deadlinePassed = deadline.isBefore(DateTime.now());

        return allItemsAccomplished || deadlinePassed;
      } else {
        print('Item with ID $listId not found!');
        return false;
      }
    } catch (e) {
      print('Error fetching item: $e');
      return false;
    }
  }

  Future<void> editDeadline(String listId, DateTime? newDeadline) async {
    if (newDeadline == null) {
      return;
    }

    try {
      // Fetch the document snapshot of the specified to-do list
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('todo_lists')
              .doc(listId)
              .get();

      if (snapshot.exists) {
        // Convert the snapshot data to a map
        Map<String, dynamic> data = snapshot.data()!;

        // Update the 'deadline' field with the new deadline
        data['deadline'] = DateFormat('yyyy-MM-dd').format(newDeadline);

        // Update the document in Firestore
        await _firestore.collection('todo_lists').doc(listId).update(data);

        // Invalidate cache and notify listeners to reflect the changes
        invalidateCache();
        notifyListeners();
      } else {
        print('Item with ID $listId not found!');
      }
    } catch (e) {
      print('Error updating the deadline: $e');
    }
  }

  Future<void> editTitle(String listId, String? newTitle) async {
    if (newTitle == null) {
      return;
    }

    try {
      // Fetch the document snapshot of the specified to-do list
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('todo_lists')
              .doc(listId)
              .get();

      if (snapshot.exists) {
        // Convert the snapshot data to a map
        Map<String, dynamic> data = snapshot.data()!;

        // Update the 'title' field with the new newTitle
        data['title'] = newTitle;

        // Update the document in Firestore
        await _firestore.collection('todo_lists').doc(listId).update(data);

        // Invalidate cache and notify listeners to reflect the changes
        invalidateCache();
        notifyListeners();
      } else {
        print('Item with ID $listId not found!');
      }
    } catch (e) {
      print('Error updating the deadline: $e');
    }
  }
}

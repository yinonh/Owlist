/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../Models/to_do_list.dart';
import './list_abstract.dart';

class ListsProvider extends ListProviderAbstract with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ToDoList>? _activeItemsCache;
  List<ToDoList>? _achievedItemsCache;
  List<ToDoList>? _withoutDeadlineItemsCache;

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
          return (doc['hasDeadline'] == 1) &&
              (doc['accomplishedItems'] < doc['totalItems'] ||
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

  Future<List<ToDoList>> getWithoutDeadlineItems() async {
    if (_withoutDeadlineItemsCache != null) {
      return _withoutDeadlineItemsCache!;
    }

    String userId = _auth.currentUser!.uid;

    QuerySnapshot snapshot = await _firestore
        .collection('todo_lists')
        .where('userID', isEqualTo: userId)
        .get();

    _withoutDeadlineItemsCache = snapshot.docs
        .where((doc) {
          return !(doc['hasDeadline'] == 1) &&
              (doc['accomplishedItems'] < doc['totalItems'] ||
                  doc['totalItems'] == 0);
        })
        .map((doc) => ToDoList.fromSnapshot(doc))
        .toList();

    return _withoutDeadlineItemsCache!;
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
      }
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
    _withoutDeadlineItemsCache = null;
  }


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
}*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;
import 'package:awesome_notifications/awesome_notifications.dart';

import '../Models/to_do_list.dart';
import './list_abstract.dart';

const VERSION = 1;

class ListsProvider extends ListProviderAbstract with ChangeNotifier {
  Database? _database;
  List<ToDoList>? _activeItemsCache;
  List<ToDoList>? _achievedItemsCache;
  List<ToDoList>? _withoutDeadlineItemsCache;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    return await sql.openDatabase(
      path.join(await sql.getDatabasesPath(), 'to_do.db'),
      onCreate: (db, version) async {
        print('Creating tables...');
        await db.execute('''
          CREATE TABLE todo_lists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userID TEXT,
            title TEXT,
            creationDate TEXT,
            deadline TEXT,
            hasDeadline INTEGER,
            totalItems INTEGER,
            notificationIndex INTEGER,
            accomplishedItems INTEGER
          )
        ''');
        await db.execute('''
        CREATE TABLE todo_items(
          id TEXT PRIMARY KEY, 
          listId TEXT, 
          title TEXT, 
          content TEXT, 
          done INTEGER, 
          itemIndex INTEGER
          );
        ''');
      },
      version: VERSION,
    );
  }

  Future<void> printTableColumns(String tableName) async {
    try {
      // Open or create the SQLite database
      final Database db = await database;

      // Query the SQLite database to fetch the table columns
      List<Map<String, dynamic>> columns =
          await db.rawQuery('PRAGMA table_info($tableName)');

      // Print the column names
      for (var column in columns) {
        print('Column Name: ${column['name']}');
      }

      // Close the database
      // await db.close();
    } catch (error) {
      print("Error printing table columns: $error");
    }
  }

  // Future<Database> get database async {
  //   if (_database != null) return _database!;
  //   _database = await initDB();
  //   return _database!;
  // }
  //
  // initDB() async {
  //   return await sql.openDatabase(
  //     path.join(await sql.getDatabasesPath(), 'to_do.db'),
  //     onCreate: (db, version) async {
  //       await db.execute('''
  //         CREATE TABLE todo_lists(
  //           id TEXT PRIMARY KEY,
  //           title TEXT,
  //           creationDate TEXT,
  //           deadline TEXT,
  //           hasDeadline INTEGER,
  //           totalItems INTEGER,
  //           accomplishedItems INTEGER
  //         )
  //       ''');
  //     },
  //     version: 1,
  //   );
  // }

  Future<List<ToDoList>> getActiveItems() async {
    if (_activeItemsCache != null) {
      return _activeItemsCache!;
    }

    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT *
    FROM todo_lists
    WHERE hasDeadline = 1
      AND (accomplishedItems < totalItems OR totalItems = 0)
      AND deadline > ?
  ''', [DateTime.now().toIso8601String()]);

    _activeItemsCache = List.generate(maps.length, (i) {
      var deadline = DateTime.parse(maps[i]['deadline']);
      return ToDoList(
        id: maps[i]['id'].toString(),
        title: maps[i]['title'],
        creationDate: DateTime.parse(maps[i]['creationDate']),
        deadline: deadline,
        hasDeadline: maps[i]['hasDeadline'] == 1,
        totalItems: maps[i]['totalItems'],
        accomplishedItems: maps[i]['accomplishedItems'],
        userID: maps[i]['userID'],
        notificationIndex: maps[i]['notificationIndex'],
      );
    });

    return _activeItemsCache ?? [];
  }

  Future<List<ToDoList>> getAchievedItems() async {
    if (_achievedItemsCache != null) {
      return _achievedItemsCache!;
    }

    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT *
    FROM todo_lists
    WHERE (accomplishedItems >= totalItems AND totalItems > 0)
        OR deadline < ?
  ''', [DateTime.now().toIso8601String()]);

    _achievedItemsCache = List.generate(maps.length, (i) {
      var deadline = DateTime.parse(maps[i]['deadline']);
      return ToDoList(
        id: maps[i]['id'].toString(),
        title: maps[i]['title'],
        creationDate: DateTime.parse(maps[i]['creationDate']),
        deadline: deadline,
        hasDeadline: maps[i]['hasDeadline'] == 1,
        totalItems: maps[i]['totalItems'],
        accomplishedItems: maps[i]['accomplishedItems'],
        userID: maps[i]['userID'],
        notificationIndex: maps[i]['notificationIndex'],
      );
    });

    return _achievedItemsCache ?? [];
  }

  Future<List<ToDoList>> getWithoutDeadlineItems() async {
    if (_withoutDeadlineItemsCache != null) {
      return _withoutDeadlineItemsCache!;
    }

    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT *
    FROM todo_lists
    WHERE hasDeadline = 0
    AND (accomplishedItems < totalItems OR totalItems = 0)
      AND deadline > ?
  ''', [DateTime.now().toIso8601String()]);

    _withoutDeadlineItemsCache = List.generate(maps.length, (i) {
      var deadline = DateTime.parse(maps[i]['deadline']);
      return ToDoList(
        id: maps[i]['id'].toString(),
        title: maps[i]['title'],
        creationDate: DateTime.parse(maps[i]['creationDate']),
        deadline: deadline,
        hasDeadline: maps[i]['hasDeadline'] == 1,
        totalItems: maps[i]['totalItems'],
        accomplishedItems: maps[i]['accomplishedItems'],
        userID: maps[i]['userID'],
        notificationIndex: maps[i]['notificationIndex'],
      );
    });

    return _withoutDeadlineItemsCache ?? [];
  }

  Future<void> addNewList(ToDoList newList) async {
    try {
      final Database db = await database;
      // Insert the new list into the SQLite database
      await db.insert('todo_lists', newList.toMap());

      if (newList.hasDeadline) {
        // Add local notification logic using flutter_local_notifications package.
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
      }
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  Future<void> createNewList(
      String title, DateTime deadline, bool hasDeadline) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> snapshot = await db.rawQuery(
          'SELECT MAX(notificationIndex) as maxIndex FROM todo_lists');

      int notificationIndex = (snapshot[0]['maxIndex'] as int? ?? 0) + 1;

      ToDoList newList = ToDoList(
        id: '0',
        // SQLite will auto-generate the ID
        userID: '1', // FirebaseAuth.instance.currentUser!.uid,
        notificationIndex: notificationIndex,
        hasDeadline: hasDeadline,
        title: title,
        creationDate: DateTime.now(),
        deadline: deadline,
        totalItems: 0,
        accomplishedItems: 0,
      );

      await addNewList(newList).then((_) {
        invalidateCache();
        notifyListeners();
      });
    } catch (error) {
      print("Error adding new item: $error");
    }
  }

  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
    _withoutDeadlineItemsCache = null;
  }

  Future<void> deleteList(String listId) async {
    try {
      final Database db = await database;

      // Delete items associated with the list from the SQLite database
      await db.delete(
        'todo_items',
        where: 'listId = ?',
        whereArgs: [listId],
      );

      // Delete the list itself from the SQLite database
      await db.delete(
        'todo_lists',
        where: 'id = ?',
        whereArgs: [listId],
      );

      // Close the database
      // await db.close();

      invalidateCache();
      notifyListeners();
    } catch (e) {
      print('Error deleting list and its items: $e');
    }
  }

  Future<String?> getItemTitleById(String id) async {
    try {
      final Database db = await database;
      // Query the SQLite database to fetch the title by ID
      List<Map<String, dynamic>> result = await db.query(
        'todo_lists',
        columns: ['title'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        return result[0]['title'];
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
      final Database db = await database;

      // Query the SQLite database to fetch list information by ID
      List<Map<String, dynamic>> result = await db.query(
        'todo_lists',
        columns: ['totalItems', 'accomplishedItems', 'deadline'],
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (result.isNotEmpty) {
        int totalItems = result[0]['totalItems'];
        int accomplishedItems = result[0]['accomplishedItems'];
        DateTime deadline = DateTime.parse(result[0]['deadline']);

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
      final Database db = await database;

      // Fetch the current deadline from the SQLite database
      List<Map<String, dynamic>> result = await db.query(
        'todo_lists',
        columns: ['deadline'],
        where: 'id = ?',
        whereArgs: [listId],
      );

      if (result.isNotEmpty) {
        String currentDeadline = result[0]['deadline'];

        // Update the 'deadline' field with the new deadline
        await db.update(
          'todo_lists',
          {
            'deadline': DateFormat('yyyy-MM-dd').format(newDeadline),
          },
          where: 'id = ?',
          whereArgs: [listId],
        );

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
      final Database db = await database;

      // Update the 'title' field with the new newTitle in the SQLite database
      await db.update(
        'todo_lists',
        {
          'title': newTitle,
        },
        where: 'id = ?',
        whereArgs: [listId],
      );

      // Invalidate cache and notify listeners to reflect the changes
      invalidateCache();
      notifyListeners();
    } catch (e) {
      print('Error updating the title: $e');
    }
  }
}

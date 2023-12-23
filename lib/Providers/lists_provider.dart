import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;
// import 'package:awesome_notifications/awesome_notifications.dart';

import '../Providers/notification_provider.dart';
import '../Models/to_do_list.dart';

const VERSION = 1;

class ListsProvider extends ChangeNotifier {
  Database? _database;
  List<ToDoList>? _activeItemsCache;
  List<ToDoList>? _achievedItemsCache;
  List<ToDoList>? _withoutDeadlineItemsCache;
  late NotificationProvider notificationProvider;
  late BuildContext context;

  initialization(BuildContext context) async {
    this.context = context;
    notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.setUpNotifications();
  }

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

  Future<ToDoList?> getListById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todo_lists',
      where: 'id = ?',
      whereArgs: [id],
    );
    final map = maps.first;
    var deadline = DateTime.parse(map['deadline']);
    if (maps.isNotEmpty) {
      return ToDoList(
        id: map['id'].toString(),
        title: map['title'],
        creationDate: DateTime.parse(map['creationDate']),
        deadline: deadline,
        hasDeadline: map['hasDeadline'] == 1,
        totalItems: map['totalItems'],
        accomplishedItems: map['accomplishedItems'],
        userID: map['userID'],
        notificationIndex: map['notificationIndex'],
      );
      //return ToDoList.fromMap(maps.first);
    }

    return null; // Return null if no matching ToDoList is found.
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
        OR (hasDeadline = 1 AND deadline < ?)
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
  ''');

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
      return null;
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  Future<String?> createNewList(
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
      if (newList.hasDeadline) {
        notificationProvider.isAndroidPermissionGranted();
        notificationProvider.requestPermissions();
        return await notificationProvider.scheduleNotification(newList);
      }
    } catch (error) {
      print("Error adding new item: $error");
    }
  }

  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
    _withoutDeadlineItemsCache = null;
  }

  Future<void> deleteList(ToDoList list) async {
    try {
      final Database db = await database;

      // Delete items associated with the list from the SQLite database
      await db.delete(
        'todo_items',
        where: 'listId = ?',
        whereArgs: [list.id],
      );

      // Delete the list itself from the SQLite database
      await db.delete(
        'todo_lists',
        where: 'id = ?',
        whereArgs: [list.id],
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

  Future<void> editDeadline(ToDoList list, DateTime? newDeadline) async {
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
        whereArgs: [list.id],
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
          whereArgs: [list.id],
        );

        notificationProvider.cancelNotification(list.notificationIndex);
        notificationProvider.scheduleNotification(list);

        // Invalidate cache and notify listeners to reflect the changes
        invalidateCache();
        notifyListeners();
      } else {
        print('Item with ID ${list.id} not found!');
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

  Future<void> editItemTitle(String itemId, String? newTitle) async {
    if (newTitle == null) {
      return;
    }
    try {
      final Database db = await database;

      // Update the 'title' field with the new newTitle in the SQLite database
      await db.update(
        'todo_items',
        {
          'title': newTitle,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      invalidateCache();
      notifyListeners();
    } catch (e) {
      print('Error updating the title: $e');
    }
  }

  Future<Map<String, int>> updateStatistics() async {
    final activeItems = await getActiveItems();
    final achievedItems = await getAchievedItems();
    final withoutDeadlineLists = await getWithoutDeadlineItems();

    var totalItems =
        activeItems.fold(0, (total, list) => total + list.totalItems);
    totalItems = achievedItems.fold(
        totalItems, (total, list) => total + list.totalItems);
    totalItems = withoutDeadlineLists.fold(
        totalItems, (total, list) => total + list.totalItems);

    var itemsDone =
        activeItems.fold(0, (total, list) => total + list.accomplishedItems);
    itemsDone = achievedItems.fold(
        itemsDone, (total, list) => total + list.accomplishedItems);
    itemsDone = withoutDeadlineLists.fold(
        itemsDone, (total, list) => total + list.accomplishedItems);

    final itemsDelayed = achievedItems.fold(
        0, (total, list) => total + list.totalItems - list.accomplishedItems);

    final itemsNotDone = totalItems - itemsDone - itemsDelayed;

    final statistics = {
      'totalLists': activeItems.length +
          achievedItems.length +
          withoutDeadlineLists.length,
      'listsDone': achievedItems.length,
      'activeLists': activeItems.length,
      'withoutDeadline': withoutDeadlineLists.length,
      'totalItems': totalItems,
      'itemsDone': itemsDone,
      'itemsDelayed': itemsDelayed,
      'itemsNotDone': itemsNotDone
    };
    print(statistics);
    return statistics;
  }
}

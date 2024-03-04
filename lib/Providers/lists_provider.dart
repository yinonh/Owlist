import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;
import 'package:to_do/Utils/notification_time.dart';
import 'package:uuid/uuid.dart';

import '../Models/notification.dart';
import '../Providers/notification_provider.dart';
import '../Models/to_do_list.dart';
import '../Utils/shared_preferences_helper.dart';

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
          id TEXT PRIMARY KEY,
          userID TEXT,
          title TEXT,
          creationDate TEXT,
          deadline TEXT,
          hasDeadline INTEGER,
          totalItems INTEGER,
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
        await db.execute('''
          CREATE TABLE notifications(
            id TEXT PRIMARY KEY,
            listId INTEGER,
            notificationIndex INTEGER,
            notificationDateTime TEXT,
            disabled INTEGER
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE notifications(
            id TEXT PRIMARY KEY,
            listId STRING,
            notificationIndex INTEGER,
            notificationDateTime TEXT,
            disabled INTEGER
          );
        ''');
          NotificationTime notificationTime = NotificationTime.fromInt(
              await SharedPreferencesHelper.instance.getNotificationTime());
          // Migrate existing data from todo_lists to notifications
          List<Map<String, dynamic>> lists = await db.query('todo_lists');
          for (var list in lists) {
            int listId = list['id'];
            int notificationIndex = list['notificationIndex'];
            String deadline = list['deadline'];
            // Calculate notification date one day before the deadline
            DateTime notificationDate = DateFormat('yyyy-MM-dd')
                .parse(deadline)
                .subtract(Duration(days: 1));
            String notificationDateTime = DateFormat('yyyy-MM-dd HH:mm').format(
              DateTime(
                  notificationDate.year,
                  notificationDate.month,
                  notificationDate.day,
                  notificationTime.hour,
                  notificationTime.minute),
            );
            await db.insert('notifications', {
              'id': Uuid().v4(),
              'listId': listId,
              'notificationIndex': notificationIndex,
              'notificationDateTime': notificationDateTime,
              'disabled': 0, // Not disabled by default
            });
          }
          // Remove notificationIndex from todo_lists
          await db.execute('''
          CREATE TABLE todo_lists_temp AS SELECT
            id, userID, title, creationDate, deadline, hasDeadline, totalItems, accomplishedItems
          FROM todo_lists;
        ''');
          await db.execute('DROP TABLE todo_lists;');
          await db.execute('ALTER TABLE todo_lists_temp RENAME TO todo_lists;');
        }
      },
      version: int.parse(dotenv.env['DBVERSION']!),
    );
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
        id: maps[i]['id'],
        title: maps[i]['title'],
        creationDate: DateTime.parse(maps[i]['creationDate']),
        deadline: deadline,
        hasDeadline: maps[i]['hasDeadline'] == 1,
        totalItems: maps[i]['totalItems'],
        accomplishedItems: maps[i]['accomplishedItems'],
        userID: maps[i]['userID'],
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
        id: map['id'],
        title: map['title'],
        creationDate: DateTime.parse(map['creationDate']),
        deadline: deadline,
        hasDeadline: map['hasDeadline'] == 1,
        totalItems: map['totalItems'],
        accomplishedItems: map['accomplishedItems'],
        userID: map['userID'],
      );
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
        id: maps[i]['id'],
        title: maps[i]['title'],
        creationDate: DateTime.parse(maps[i]['creationDate']),
        deadline: deadline,
        hasDeadline: maps[i]['hasDeadline'] == 1,
        totalItems: maps[i]['totalItems'],
        accomplishedItems: maps[i]['accomplishedItems'],
        userID: maps[i]['userID'],
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
      );
    });

    return _withoutDeadlineItemsCache ?? [];
  }

  Future<void> addNewList(ToDoList newList) async {
    try {
      final Database db = await database;
      // Insert the new list into the SQLite database
      await db.insert('todo_lists', newList.toMap());
      return;
    } catch (e) {
      print('Error adding new list: $e');
    }
  }

  Future<bool> createNewList(
      String title, DateTime deadline, bool hasDeadline) async {
    try {
      String newListId = Uuid().v4();
      ToDoList newList = ToDoList(
        id: newListId,
        // SQLite will auto-generate the ID
        userID: '1',
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
        return await notificationProvider.addNotificationDayBeforeDeadline(
            newList,
            SharedPreferencesHelper.instance.selectedLanguage ??
                Localizations.localeOf(context).languageCode);
      }
    } catch (error) {
      print("Error adding new item: $error");
    }
    return false;
  }

  void invalidateCache() {
    _activeItemsCache = null;
    _achievedItemsCache = null;
    _withoutDeadlineItemsCache = null;
  }

  Future<void> deleteList(ToDoList list) async {
    try {
      final Database db = await database;

      // Delete items associated with the list
      await db.delete(
        'todo_items',
        where: 'listId = ?',
        whereArgs: [list.id],
      );

      // Cancel the associated notifications
      List<Notifications> notifications =
          await notificationProvider.getNotificationsByListId(list.id);
      for (var notification in notifications) {
        notificationProvider.cancelNotification(notification.notificationIndex);
      }

      // Delete notifications associated with the list
      await db.delete(
        'notifications',
        where: 'listId = ?',
        whereArgs: [list.id],
      );

      // Delete the list itself
      await db.delete(
        'todo_lists',
        where: 'id = ?',
        whereArgs: [list.id],
      );

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

  Future<bool> editDeadline(ToDoList list, DateTime? newDeadline) async {
    if (newDeadline == null) {
      return false;
    }
    bool notificationDisabled = false;
    try {
      final Database db = await database;

      await db.update(
        'todo_lists',
        {
          'deadline': DateFormat('yyyy-MM-dd').format(newDeadline),
        },
        where: 'id = ?',
        whereArgs: [list.id],
      );

      invalidateCache();
      notifyListeners();
      List<Notifications> notifications =
          await notificationProvider.getNotificationsByListId(list.id);
      for (var notification in notifications) {
        if (newDeadline.isBefore(notification.notificationDateTime)) {
          notificationProvider.disableNotificationById(notification.id);
          notificationDisabled = true;
        }
      }
      notificationProvider.scheduleNotification(
          list,
          SharedPreferencesHelper.instance.selectedLanguage ??
              Localizations.localeOf(context).languageCode);
    } catch (e) {
      print('Error updating the deadline: $e');
    }
    return notificationDisabled;
  }

  Future<void> editTitle(ToDoList list, String? newTitle) async {
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
        whereArgs: [list.id],
      );
      ToDoList newList = list.copyWith(title: newTitle);

      // Invalidate cache and notify listeners to reflect the changes
      invalidateCache();
      notifyListeners();
      notificationProvider.scheduleNotification(
          newList,
          SharedPreferencesHelper.instance.selectedLanguage ??
              Localizations.localeOf(context).languageCode);
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
    return statistics;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../Models/notification.dart';
import '../Models/to_do_item.dart';
import 'notification_provider.dart';

class ItemProvider extends ChangeNotifier {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    return await sql.openDatabase(
      path.join(await sql.getDatabasesPath(), 'to_do.db'),
      version: int.parse(dotenv.env['DBVERSION']!),
    );
  }

  Future<List<ToDoItem>> itemsByListId(String listId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todo_items',
      where: "listId = ?",
      whereArgs: [listId],
    );

    return List.generate(maps.length, (i) {
      return ToDoItem(
        id: maps[i]['id'],
        listId: maps[i]['listId'],
        title: maps[i]['title'],
        content: maps[i]['content'],
        done: maps[i]['done'] == 1,
        itemIndex: maps[i]['itemIndex'],
      );
    });
  }

  Future<ToDoItem> itemById(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todo_items',
      where: "id = ?",
      whereArgs: [id],
    );
    return ToDoItem(
      id: maps[0]['id'].toString(),
      listId: maps[0]['listId'],
      title: maps[0]['title'],
      content: maps[0]['content'],
      done: maps[0]['done'] == 1,
      itemIndex: maps[0]['itemIndex'],
    );
  }

  Future<ToDoItem?> addNewItem(String listId, String title) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todo_items',
      where: "listId = ?",
      whereArgs: [listId],
      orderBy: "itemIndex DESC",
      limit: 1,
    );

    int newIndex = 0;
    if (maps.isNotEmpty) {
      newIndex = maps.first['itemIndex'] + 1;
    }

    final newItemData = {
      'id': DateTime.now().toIso8601String(),
      'listId': listId,
      'title': title,
      'content': '',
      'done': 0,
      'itemIndex': newIndex,
    };

    await db.insert(
      'todo_items',
      newItemData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.transaction((txn) async {
      await txn.rawUpdate(
          'UPDATE todo_lists SET totalItems = totalItems + 1 WHERE id = ?',
          [listId]);
    });

    final newItem = ToDoItem(
      id: newItemData['id'] as String,
      listId: listId,
      title: title,
      content: '',
      done: false,
      itemIndex: newIndex,
    );

    notifyListeners();

    return newItem;
  }

  Future<void> addExistingItem(ToDoItem item) async {
    final Database db = await database;

    final Map<String, dynamic> itemData = {
      'id': item.id,
      'listId': item.listId,
      'title': item.title,
      'content': item.content,
      'done': item.done ? 1 : 0,
      'itemIndex': item.itemIndex,
    };

    await db.insert(
      'todo_items',
      itemData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.transaction((txn) async {
      final String updateQuery = item.done
          ? 'UPDATE todo_lists SET totalItems = totalItems + 1, accomplishedItems = accomplishedItems + 1 WHERE id = ?'
          : 'UPDATE todo_lists SET totalItems = totalItems + 1 WHERE id = ?';

      await txn.rawUpdate(
        updateQuery,
        [item.listId],
      );
    });
  }

  Future<void> deleteItemById(String id, bool isDone) async {
    try {
      final Database db = await database;

      // Fetch the listId of the item from the SQLite database
      List<Map<String, dynamic>> result = await db.query(
        'todo_items',
        columns: ['listId'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        String listId = result[0]['listId'];

        // Delete the item from the SQLite database
        await db.delete(
          'todo_items',
          where: 'id = ?',
          whereArgs: [id],
        );

        // Update totalItems and accomplishedItems in the todo_lists table
        await db.transaction((txn) async {
          await txn.rawUpdate(
              'UPDATE todo_lists SET totalItems = totalItems - 1 WHERE id = ?',
              [listId]);

          if (isDone) {
            await txn.rawUpdate(
                'UPDATE todo_lists SET accomplishedItems = accomplishedItems - 1 WHERE id = ?',
                [listId]);
          }
        });

        print('Item with ID $id deleted successfully!');
      } else {
        print('Item with ID $id not found in the database!');
      }

      // Notify listeners to reflect the changes
      notifyListeners();
    } catch (e) {
      print('Error deleting item: $e');
    }
  }

  Future<void> toggleItemDone(
      String itemId, String listId, bool isDone, BuildContext context) async {
    try {
      // Open or create the SQLite database
      final Database db = await database;

      // Fetch the current item data
      List<Map<String, dynamic>> result = await db.query(
        'todo_items',
        columns: ['done'],
        where: 'id = ?',
        whereArgs: [itemId],
      );

      if (result.isNotEmpty) {
        bool currentDoneValue = result[0]['done'] == 1;

        // Toggle the 'done' field value
        await db.update(
          'todo_items',
          {'done': currentDoneValue ? 0 : 1},
          where: 'id = ?',
          whereArgs: [itemId],
        );

        // Fetch the list data to update 'accomplishedItems'
        List<Map<String, dynamic>> listResult = await db.query(
          'todo_lists',
          columns: ['accomplishedItems', 'totalItems'],
          where: 'id = ?',
          whereArgs: [listId],
        );

        if (listResult.isNotEmpty) {
          int accomplishedItems = listResult[0]['accomplishedItems'] as int;
          int totalItems = listResult[0]['totalItems'] as int;

          if (currentDoneValue) {
            accomplishedItems--;
          } else {
            accomplishedItems++;
          }
          if (accomplishedItems == totalItems) {
            NotificationProvider notificationProvider =
                Provider.of<NotificationProvider>(context, listen: false);
            List<Notifications> notifications =
                await notificationProvider.getNotificationsByListId(listId);
            notifications.forEach((notification) {
              notificationProvider.disableNotificationById(notification.id);
            });
          }

          // Update 'accomplishedItems' in the todo_lists table
          await db.update(
            'todo_lists',
            {'accomplishedItems': accomplishedItems},
            where: 'id = ?',
            whereArgs: [listId],
          );

          notifyListeners();
        }
      }
    } catch (error) {
      print("Error toggling item's done state: $error");
    }
  }

  Future<void> editIndex(String itemId, int newIndex) async {
    final Database db = await database;
    await db.update(
      'todo_items',
      {'itemIndex': newIndex},
      where: "id = ?",
      whereArgs: [itemId],
    );

    notifyListeners();
  }

  Future<void> updateItemContent(String itemId, String newContent) async {
    try {
      final Database db = await database;

      await db.update(
        'todo_items',
        {'content': newContent},
        where: 'id = ?',
        whereArgs: [itemId],
      );

      notifyListeners();
    } catch (error) {
      print("Error updating item's content: $error");
    }
  }
}

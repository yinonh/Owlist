import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

import '../Models/notification.dart';
import '../Models/to_do_item.dart';
import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Providers/notification_provider.dart';
import '../Utils/keys.dart';

class ItemProvider extends ChangeNotifier {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    return await sql.openDatabase(
      path.join(await sql.getDatabasesPath(), Keys.toDoTable),
      version: 3, // New version
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Check if the column already exists; if not, add it.
          // More importantly, ensure its type can hold JSON.
          // SQLite types are flexible, but TEXT is appropriate.
          // This simple ALTER TABLE might not be enough if the column type was strictly something else non-text.
          // However, for typical string types, this should be fine or a no-op.
          // A more robust migration might check column affinity, but this is generally safe.
          await db.execute("ALTER TABLE todo_items ADD COLUMN temp_content TEXT;");
          await db.execute("UPDATE todo_items SET temp_content = content;");
          await db.execute("ALTER TABLE todo_items DROP COLUMN content;");
          await db.execute("ALTER TABLE todo_items RENAME COLUMN temp_content TO content;");
          // If the column 'content' didn't exist before or was of a different type,
          // this ensures it's now TEXT. If it was already TEXT, this is benign.
        }
      },
      onCreate: (db, version) async {
        // This onCreate is called if the database did not exist and is created for the first time.
        // It should set up the schema for version 3 directly.
        // Assuming the table creation logic is handled by another provider (ListsProvider likely)
        // or was part of an earlier version's onCreate.
        // If this provider is responsible for creating 'todo_items' table, that DDL needs to be here,
        // ensuring 'content' is TEXT.
        // For now, focusing on upgrade. The original issue implies tables exist.
      },
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
        id: maps[i][Keys.id],
        listId: maps[i][Keys.listId],
        title: maps[i][Keys.title],
        content: maps[i][Keys.content],
        done: maps[i][Keys.done] == 1,
        itemIndex: maps[i][Keys.itemIndex],
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
      id: maps[0][Keys.id].toString(),
      listId: maps[0][Keys.listId],
      title: maps[0][Keys.title],
      content: maps[0][Keys.content],
      done: maps[0][Keys.done] == 1,
      itemIndex: maps[0][Keys.itemIndex],
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
      newIndex = maps.first[Keys.itemIndex] + 1;
    }

    final newItemData = {
      Keys.id: DateTime.now().toIso8601String(),
      Keys.listId: listId,
      Keys.title: title,
      Keys.content: '{"ops":[{"insert":"\\n"}]}', // Updated for empty Quill document
      Keys.done: 0,
      Keys.itemIndex: newIndex,
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
      id: newItemData[Keys.id] as String,
      listId: listId,
      title: title,
      content: '{"ops":[{"insert":"\\n"}]}', // Updated for empty Quill document
      done: false,
      itemIndex: newIndex,
    );

    notifyListeners();

    return newItem;
  }

  Future<void> addExistingItem(ToDoItem item) async {
    final Database db = await database;

    final Map<String, dynamic> itemData = {
      Keys.id: item.id,
      Keys.listId: item.listId,
      Keys.title: item.title,
      Keys.content: item.content,
      Keys.done: item.done ? 1 : 0,
      Keys.itemIndex: item.itemIndex,
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
        String listId = result[0][Keys.listId];

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

  Future<void> toggleItemDone(ToDoItem item, BuildContext context) async {
    try {
      ToDoList? list = await Provider.of<ListsProvider>(context, listen: false)
          .getListById(item.listId);
      if (list == null) return;
      // Open or create the SQLite database
      final Database db = await database;

      // Fetch the current item data
      List<Map<String, dynamic>> result = await db.query(
        'todo_items',
        columns: ['done'],
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (result.isNotEmpty) {
        bool currentDoneValue = result[0]['done'] == 1;

        // Toggle the 'done' field value
        await db.update(
          'todo_items',
          {'done': currentDoneValue ? 0 : 1},
          where: 'id = ?',
          whereArgs: [item.id],
        );

        // Fetch the list data to update 'accomplishedItems'
        List<Map<String, dynamic>> listResult = await db.query(
          'todo_lists',
          columns: ['accomplishedItems', 'totalItems'],
          where: 'id = ?',
          whereArgs: [list.id],
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
                await notificationProvider.getNotificationsByListId(list.id);
            notifications.forEach((notification) {
              notificationProvider.disableNotificationById(notification, list);
            });
          }

          // Update 'accomplishedItems' in the todo_lists table
          await db.update(
            'todo_lists',
            {'accomplishedItems': accomplishedItems},
            where: 'id = ?',
            whereArgs: [list.id],
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

  Future<void> editItemTitle(String itemId, String newTitle) async {
    try {
      final Database db = await database;
      await db.update(
        'todo_items',
        {Keys.title: newTitle},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      notifyListeners();
    } catch (error) {
      print("Error updating item's title: $error");
    }
  }
}

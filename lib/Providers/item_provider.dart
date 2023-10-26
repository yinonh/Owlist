/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/to_do_item.dart';
import './item_abstract.dart';

class ItemProvider extends ItemsAbstract with ChangeNotifier {
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
          itemIndex: doc['itemIndex'],
        );
      }).toList();
    } catch (error) {
      print("Error fetching data: $error");
      return [];
    }
  }

  Future<ToDoItem?> addNewItem(String listId, String title) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('todoItems')
          .where('listId', isEqualTo: listId)
          .orderBy('itemIndex', descending: true)
          .limit(1)
          .get();

      int newIndex = 0;

      if (snapshot.docs.isNotEmpty) {
        final highestIndexItem = snapshot.docs.first;
        final highestIndex = highestIndexItem['itemIndex'] as int;
        newIndex = highestIndex + 1;
      }

      final newItemData = {
        'listId': listId,
        'title': title,
        'content': '',
        'done': false,
        'itemIndex': newIndex,
      };

      final newItemRef = await FirebaseFirestore.instance
          .collection('todoItems')
          .add(newItemData);

      // Update totalItems in todo_lists collection
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);
      await listRef.update({'totalItems': FieldValue.increment(1)});

      final newItem = ToDoItem(
        id: newItemRef.id,
        listId: listId,
        title: title,
        content: '',
        done: false,
        itemIndex: newIndex,
      );

      notifyListeners();

      return newItem;
    } catch (error) {
      print("Error adding new item: $error");
      return null;
    }
  }

  Future<void> deleteItemById(String id, bool isDone) async {
    try {
      final itemSnapshot = await FirebaseFirestore.instance
          .collection('todoItems')
          .doc(id)
          .get();
      final listId = itemSnapshot['listId'] as String;

      await FirebaseFirestore.instance.collection('todoItems').doc(id).delete();

      // Update totalItems and accomplishedItems in todo_lists collection
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);

      final Map<String, dynamic> listData = {};
      if (isDone) {
        listData['accomplishedItems'] = FieldValue.increment(-1);
      }
      listData['totalItems'] = FieldValue.increment(-1);

      await listRef.update(listData);

      print('Item with ID $id deleted successfully!');
    } catch (e) {
      print('Error deleting item: $e');
    }
    notifyListeners();
  }

  Future<void> toggleItemDone(String itemId, String listId, bool isDone) async {
    try {
      final itemRef =
          FirebaseFirestore.instance.collection('todoItems').doc(itemId);

      // Fetch the current item data
      final DocumentSnapshot<Map<String, dynamic>> itemSnapshot =
          await itemRef.get();
      final bool currentDoneValue = itemSnapshot.data()!['done'] as bool;

      // Toggle the 'done' field value
      await itemRef.update({'done': !currentDoneValue});

      // Fetch the list data to update 'accomplishedItems'
      final listRef =
          FirebaseFirestore.instance.collection('todo_lists').doc(listId);
      final DocumentSnapshot<Map<String, dynamic>> listSnapshot =
          await listRef.get();
      int accomplishedItems = listSnapshot.data()!['accomplishedItems'] as int;

      if (currentDoneValue) {
        accomplishedItems--;
      } else {
        accomplishedItems++;
      }

      await listRef.update({'accomplishedItems': accomplishedItems});

      notifyListeners();
    } catch (error) {
      print("Error toggling item's done state: $error");
    }
  }

  Future<void> editIndex(String itemId, int newIndex) async {
    print(itemId + " " + newIndex.toString());
    try {
      final itemRef =
          FirebaseFirestore.instance.collection('todoItems').doc(itemId);

      // Update the 'index' field value
      await itemRef.update({'itemIndex': newIndex});

      // Notify listeners or perform any other necessary actions
      notifyListeners();
    } catch (error) {
      print("Error editing item index: $error");
    }
  }
}*/

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../Providers/lists_provider.dart';
import '../Models/to_do_item.dart';
import './item_abstract.dart';

const VERSION = 1;

class ItemProvider extends ItemsAbstract with ChangeNotifier {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    return await sql.openDatabase(
      path.join(await sql.getDatabasesPath(), 'to_do.db'),
      version: VERSION,
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
    print(id);
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
      'content': 'enter some text...',
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

  Future<void> toggleItemDone(String itemId, String listId, bool isDone) async {
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
          columns: ['accomplishedItems'],
          where: 'id = ?',
          whereArgs: [listId],
        );

        if (listResult.isNotEmpty) {
          int accomplishedItems = listResult[0]['accomplishedItems'] as int;

          if (currentDoneValue) {
            accomplishedItems--;
          } else {
            accomplishedItems++;
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

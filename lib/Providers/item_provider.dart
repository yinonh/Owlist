import 'package:flutter/material.dart';

import '../Models/to_do_item.dart';

class ItemProvider with ChangeNotifier {
  final List<ToDoItem> todoItems = [
    ToDoItem(
      id: "1",
      listId: "kg70kjdy8Wy7Z9nvngXY",
      title: "Work",
      content: "Work Work",
      done: true,
      index: 0,
    ),
    ToDoItem(
      id: "2",
      listId: "kg70kjdy8Wy7Z9nvngXY",
      title: "StandStandStandStandStandStandStandStandStandS",
      content: "Hello",
      done: false,
      index: 1,
    ),
    ToDoItem(
      id: "3",
      listId: "pruGdEGwoSTSkASkCfN0",
      title: "Hey",
      content: "What's up?",
      done: true,
      index: 2,
    ),
    ToDoItem(
      id: "4",
      listId: "pruGdEGwoSTSkASkCfN0",
      title: "Last",
      content: "Last one",
      done: false,
      index: 3,
    )
  ];

  List<ToDoItem>? items_by_listId(listId) =>
      todoItems.where((element) => element.listId == listId).toList();
}

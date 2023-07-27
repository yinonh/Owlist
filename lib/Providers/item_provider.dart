import 'package:flutter/material.dart';

import '../Models/to_do_item.dart';

class ItemProvider with ChangeNotifier {
  final List<ToDoItem> todoItems = [
    ToDoItem(
      id: "1",
      listId: "1",
      title: "Work",
      description: "Work Work",
      done: true,
      index: 0,
    ),
    ToDoItem(
      id: "2",
      listId: "1",
      title: "StandStandStandStandStandStandStandStandStandS",
      description: "Hello",
      done: false,
      index: 1,
    ),
    ToDoItem(
      id: "3",
      listId: "2",
      title: "Hey",
      description: "What's up?",
      done: true,
      index: 2,
    ),
    ToDoItem(
      id: "4",
      listId: "2",
      title: "Last",
      description: "Last one",
      done: false,
      index: 3,
    )
  ];

  List<ToDoItem>? items_by_listId(listId) =>
      todoItems.where((element) => element.listId == listId).toList();
}

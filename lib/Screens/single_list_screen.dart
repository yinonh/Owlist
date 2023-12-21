import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:great_list_view/great_list_view.dart';
import 'package:to_do/Providers/notification_provider.dart';

import '../Widgets/edit_item_title_popup.dart';
import '../Widgets/item_list.dart';
import '../Widgets/diamond_button.dart';
import '../Models/to_do_item.dart';
import '../Models/to_do_list.dart';
import '../Providers/item_provider.dart';
import '../Providers/lists_provider.dart';

class SingleListScreen extends StatefulWidget {
  final String listId;
  static const routeName = '/single_list_screen';

  SingleListScreen({required this.listId, Key? key}) : super(key: key);

  @override
  State<SingleListScreen> createState() => _SingleListScreenState();
}

class _SingleListScreenState extends State<SingleListScreen> {
  late DateTime newDeadline;
  TextEditingController _titleController = TextEditingController();
  bool isLoading = false;
  late bool editMode;
  late ToDoList? list;
  late List<ToDoItem> currentList;
  late List<ToDoItem> editList;

  @override
  void initState() {
    super.initState();
    initListDate();
    editMode = false;
  }

  void initListDate() async {
    setState(() {
      isLoading = true;
    });
    list = await Provider.of<ListsProvider>(context, listen: false)
        .getListById(widget.listId);
    if (list == null) Navigator.pop;
    newDeadline = list!.deadline;
    _titleController.text = list!.title;
    currentList = await Provider.of<ItemProvider>(context, listen: false)
        .itemsByListId(list!.id);
    currentList.sort((a, b) {
      if (a.done == b.done) {
        return a.itemIndex.compareTo(b.itemIndex);
      } else {
        return a.done ? 1 : -1;
      }
    });
    editList = List.from(currentList);
    setState(() {
      isLoading = false;
    });
  }

  void toggleEditMode() {
    if (!editMode) editList = List.from(currentList);
    setState(() {
      editMode = !editMode;
    });
  }

  void _showNewItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditItemDialog(
            addNewItem: addNewItem); // Pass the function as a parameter
      },
    );
  }

  void _showChangeDateDialog(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: newDeadline.isBefore(DateTime.now())
          ? DateTime.now().add(Duration(days: 7))
          : newDeadline,
      firstDate: DateTime.now().add(
        Duration(days: 1),
      ),
      lastDate: DateTime.now().add(
        Duration(days: 3650),
      ),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          newDeadline = selectedDate;
        });
      }
    });
  }

  void deleteItem(String id, bool done, context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    itemProvider.deleteItemById(id, done);

    List<ToDoItem> temp = List.from(currentList);
    temp.removeWhere((element) => element.id == id);
    setState(() {
      currentList = temp;
    });
  }

  void addNewItem(String newTitle) async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    if (newTitle.isNotEmpty) {
      ToDoItem? newItem = await itemProvider.addNewItem(list!.id, newTitle);

      if (newItem != null) {
        List<ToDoItem> temp = List.from(currentList);
        temp.add(newItem);
        temp.sort((a, b) {
          if (a.done == b.done) {
            return a.itemIndex.compareTo(b.itemIndex);
          } else {
            return a.done ? 1 : -1;
          }
        });
        setState(() {
          currentList = temp;
        });
      }
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final ToDoItem item = editList.removeAt(oldIndex);
      editList.insert(newIndex, item);
    });
  }

  void _save() async {
    setState(() {
      isLoading = true;
    });
    if (list!.deadline != newDeadline) {
      await Provider.of<ListsProvider>(context, listen: false)
          .editDeadline(list!, newDeadline);
    }
    if (list!.title != _titleController.text) {
      await Provider.of<ListsProvider>(context, listen: false)
          .editTitle(list!.id, _titleController.text);
    }
    for (int i = 0; i < editList.length; i++) {
      if (editList[i].itemIndex != i) {
        await Provider.of<ItemProvider>(context, listen: false)
            .editIndex(editList[i].id, i);
      }
    }
    initListDate();
    toggleEditMode();
  }

  void checkItem(String id, String listId, bool done) {
    Provider.of<ItemProvider>(context, listen: false)
        .toggleItemDone(id, listId, done);
    List<ToDoItem> temp = List.from(currentList);

    for (int i = 0; i < temp.length; i++) {
      if (temp[i].id == id) {
        temp[i].done = !temp[i].done;
        break;
      }
    }
    temp.sort((a, b) {
      if (a.done == b.done) {
        return a.itemIndex.compareTo(b.itemIndex);
      } else {
        return a.done ? 1 : -1;
      }
    });
    setState(() {
      currentList = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColorLight,
              Theme.of(context).primaryColorDark
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 75,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        editMode
                            ? IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    newDeadline = list!.deadline;
                                    _titleController.text = list!.title;
                                    toggleEditMode();
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                        editMode
                            ? Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLength: 25,
                                  // Set the maximum length
                                  decoration: const InputDecoration(
                                    counterText:
                                        "", // Hide the character counter
                                    // border: InputBorder.none,
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  _titleController.text,
                                  style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        editMode
                            ? IconButton(
                                icon:
                                    const Icon(Icons.save, color: Colors.white),
                                onPressed: () {
                                  _save();
                                },
                              )
                            : IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.white),
                                onPressed: toggleEditMode,
                              ),
                      ],
                    ),
                  ),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height -
                                      MediaQuery.of(context).padding.top -
                                      (75 + 40),
                                  child: ItemList(
                                    toggleEditMode: toggleEditMode,
                                    editMode: editMode,
                                    currentList: currentList,
                                    editList: editList,
                                    reorderItems: reorderItems,
                                    checkItem: checkItem,
                                    deleteItem: deleteItem,
                                    controller: itemListController,
                                    updateSingleListScreen: initListDate,
                                  ),
                                ),
                                const SizedBox(
                                  height: 40,
                                )
                              ],
                            ),
                            Positioned(
                              bottom: 0,
                              child: editMode
                                  ? DiamondButton(
                                      icon: Icon(
                                        Icons.calendar_month,
                                        color: list!.hasDeadline
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.07,
                                      ),
                                      onTap: list!.hasDeadline
                                          ? () {
                                              _showChangeDateDialog(context);
                                            }
                                          : null,
                                      screenWidth:
                                          MediaQuery.of(context).size.width,
                                      screenHeight:
                                          MediaQuery.of(context).size.height,
                                    )
                                  : DiamondButton(
                                      icon: Icon(
                                        Icons.add,
                                        color: Theme.of(context).primaryColor,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                      ),
                                      onTap: () {
                                        _showNewItemDialog(context);
                                      },
                                      screenWidth:
                                          MediaQuery.of(context).size.width,
                                      screenHeight:
                                          MediaQuery.of(context).size.height,
                                    ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

AnimatedListController itemListController = AnimatedListController();

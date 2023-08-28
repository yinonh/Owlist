import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:great_list_view/great_list_view.dart';

import '../Widgets/edit_item_title_popup.dart';
import '../Widgets/item_list.dart';
import '../Widgets/diamond_button.dart';
import '../Models/to_do_item.dart';
import '../Models/to_do_list.dart';
import '../Providers/item_provider.dart';
import '../Providers/lists_provider.dart';

class SingleListScreen extends StatefulWidget {
  final ToDoList list;
  static const routeName = '/single_list_screen';

  SingleListScreen({required this.list, Key? key}) : super(key: key);

  @override
  State<SingleListScreen> createState() => _SingleListScreenState();
}

class _SingleListScreenState extends State<SingleListScreen> {
  late DateTime newDeadline;
  TextEditingController _titleController = TextEditingController();
  bool isLoading = false;
  late bool editMode;
  late List<ToDoItem> currentList;
  late List<ToDoItem> editList;

  @override
  void initState() {
    super.initState();
    newDeadline = widget.list.deadline;
    _titleController.text = widget.list.title;
    editMode = false;
    getList();
  }

  void _toggleEditMode() {
    if (!editMode) editList = List.from(currentList);
    setState(() {
      editMode = !editMode;
    });
  }

  void getList() async {
    setState(() {
      isLoading = true;
    });
    currentList = await Provider.of<ItemProvider>(context, listen: false)
        .itemsByListId(widget.list.id);
    currentList.sort((a, b) {
      if (a.done == b.done) {
        return a.index.compareTo(b.index);
      } else {
        return a.done ? 1 : -1;
      }
    });
    editList = List.from(currentList);
    setState(() {
      isLoading = false;
    });
  }

  @override
  void didUpdateWidget(SingleListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the deadline has changed and update the UI accordingly
    if (widget.list.deadline != oldWidget.list.deadline) {
      newDeadline = widget.list.deadline;
    }
    if (widget.list.title != oldWidget.list.title) {
      _titleController.text = widget.list.title;
    }
  }

  void _moveToItemPage(BuildContext context, String itemID) {
    print("Moving to item page: $itemID");
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
      firstDate: DateTime.now(),
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
      ToDoItem? newItem =
          await itemProvider.addNewItem(widget.list.id, newTitle);

      if (newItem != null) {
        List<ToDoItem> temp = List.from(currentList);
        temp.add(newItem);
        temp.sort((a, b) {
          if (a.done == b.done) {
            return a.index.compareTo(b.index);
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
    if (widget.list.deadline != newDeadline) {
      await Provider.of<ListsProvider>(context, listen: false)
          .editDeadline(widget.list.id, newDeadline);
    }
    if (widget.list.title != _titleController.text) {
      await Provider.of<ListsProvider>(context, listen: false)
          .editTitle(widget.list.id, _titleController.text);
    }
    for (int i = 0; i < editList.length; i++) {
      if (editList[i].index != i) {
        await Provider.of<ItemProvider>(context, listen: false)
            .editIndex(editList[i].id, i);
      }
    }
    getList();
    _toggleEditMode();
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
        return a.index.compareTo(b.index);
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF635985), Color(0xFF18122B)],
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        editMode
                            ? IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    newDeadline = widget.list.deadline;
                                    _titleController.text = widget.list.title;
                                    _toggleEditMode();
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
                                  style: TextStyle(
                                    fontSize: 19.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLength: 25,
                                  // Set the maximum length
                                  decoration: InputDecoration(
                                    counterText:
                                        "", // Hide the character counter
                                    // border: InputBorder.none,
                                  ),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  _titleController.text,
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        editMode
                            ? IconButton(
                                icon: Icon(Icons.save, color: Colors.white),
                                onPressed: () {
                                  _save();
                                },
                              )
                            : IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: _toggleEditMode,
                              ),
                      ],
                    ),
                  ),
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      //To DO: change the height to be calculated
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              children: [
                                Container(
                                  height: MediaQuery.of(context).size.height -
                                      MediaQuery.of(context).padding.top -
                                      (75 + 40),
                                  child: ItemList(
                                    editMode: editMode,
                                    currentList: currentList,
                                    editList: editList,
                                    reorderItems: reorderItems,
                                    checkItem: checkItem,
                                    deleteItem: deleteItem,
                                    controller: itemListController,
                                  ),
                                ),
                                SizedBox(
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
                                        color: widget.list.hasDeadline
                                            ? Colors.white
                                            : Colors.grey,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.07,
                                      ),
                                      onTap: widget.list.hasDeadline
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
                                        color: Colors.white,
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
                              // ? ElevatedButton(
                              //     onPressed: widget.list.hasDeadline
                              //         ? () {
                              //             _showChangeDateDialog(context);
                              //           }
                              //         : null,
                              //     child:
                              //         Icon(Icons.calendar_month, size: 30),
                              //     style: ElevatedButton.styleFrom(
                              //       shape: CircleBorder(),
                              //       backgroundColor: Color(0xFF635985),
                              //       padding: EdgeInsets.all(15),
                              //       elevation: 10,
                              //     ),
                              //   )
                              // : ElevatedButton(
                              //     onPressed: () {
                              //       _showNewItemDialog(context);
                              //     },
                              //     child: Icon(Icons.add, size: 30),
                              //     style: ElevatedButton.styleFrom(
                              //       shape: CircleBorder(),
                              //       backgroundColor: Color(0xFF635985),
                              //       padding: EdgeInsets.all(15),
                              //       elevation: 10,
                              //     ),
                              //   ),
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

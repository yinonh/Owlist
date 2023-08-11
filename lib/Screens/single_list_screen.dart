import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:great_list_view/great_list_view.dart';

import '../Widgets/edit_title_popup.dart';
import '../Widgets/item_list.dart';
import '../Widgets/to_do_item_widget.dart';
import '../Widgets/date_picker.dart';
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

  @override
  void initState() {
    super.initState();
    newDeadline = widget.list.deadline;
    _titleController.text = widget.list.title;
    editMode = false;
    getList();
  }

  void _toggleEditMode() {
    setState(() {
      editMode = !editMode;
      print(editMode);
    });
  }

  void getList() async {
    setState(() {
      isLoading = true;
    });
    currentList = await Provider.of<ItemProvider>(context, listen: false)
        .itemsByListId(widget.list.id);
    currentList.sort((a, b) {
      if (a.done && !b.done) {
        return 1;
      } else if (!a.done && b.done) {
        return -1;
      } else {
        return a.index.compareTo(b.index);
      }
    });
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
        setState(() {
          currentList = temp;
        });
      }
    }
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
    setState(() {
      isLoading = false;
    });
    _toggleEditMode();
  }

  void checkItem(String id, String listId, bool done) {
    Provider.of<ItemProvider>(context, listen: false)
        .toggleItemDone(id, listId, done);
    List<ToDoItem> temp = List.from(currentList);
    ToDoItem x = temp.firstWhere((element) => element.id == id);
    x.done = !x.done;
    temp.sort((a, b) {
      if (a.done && !b.done) {
        return 1;
      } else if (!a.done && b.done) {
        return -1;
      } else {
        return a.index.compareTo(b.index);
      }
    });
    setState(() {
      currentList = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: editMode
          ? FloatingActionButton(
              onPressed: () {
                _showChangeDateDialog(context);
              },
              backgroundColor: Color(0xFF635985),
              child: const Icon(Icons.calendar_month),
            )
          : FloatingActionButton(
              onPressed: () {
                _showNewItemDialog(context);
              },
              backgroundColor: Color(0xFF635985),
              child: const Icon(Icons.add),
            ),
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
                  Padding(
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
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLength: 35,
                                  // Set the maximum length
                                  decoration: InputDecoration(
                                    counterText:
                                        "", // Hide the character counter
                                    // border: InputBorder.none,
                                  ),
                                ),
                              )
                            : Text(
                                _titleController.text,
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                      : ItemList(
                          editMode: editMode,
                          currentList: currentList,
                          checkItem: checkItem,
                          deleteItem: deleteItem,
                          controller: controller,
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

final controller = AnimatedListController();

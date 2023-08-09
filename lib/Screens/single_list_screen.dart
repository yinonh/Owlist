import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:great_list_view/great_list_view.dart';

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
  bool editMode = false;
  late List<ToDoItem> currentList;

  @override
  void initState() {
    super.initState();
    newDeadline = widget.list.deadline;
    _titleController.text = widget.list.title;
    getList();
  }

  void _toggleEditMode() {
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
    String newTitle = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter New Item Title',
              style: TextStyle(color: Color(0xFF635985))),
          content: TextField(
            onChanged: (value) {
              newTitle = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Color(0xFF635985))),
            ),
            TextButton(
              onPressed: () {
                addNewItem(newTitle);
              },
              child: Text(
                'Add',
                style: TextStyle(color: Color(0xFF635985)),
              ),
            ),
          ],
        );
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
      Navigator.of(context).pop();

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
    if (isLoading) return;
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
    _toggleEditMode();
    setState(() {
      isLoading = false;
    });
  }

  void checkItem(String id) {
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
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
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
                                    editMode = false;
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
                                onPressed: () {
                                  _toggleEditMode();
                                },
                              ),
                      ],
                    ),
                  ),
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Container(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: AutomaticAnimatedListView<ToDoItem>(
                            list: currentList,
                            comparator:
                                AnimatedListDiffListComparator<ToDoItem>(
                              sameItem: (a, b) => a.id == b.id,
                              sameContent: (a, b) => a.title == b.title,
                            ),
                            itemBuilder: (context, item, data) => data.measuring
                                ? Container(
                                    margin: EdgeInsets.all(5), height: 50)
                                : Container(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ToDoItemWidget(
                                      item,
                                      editMode,
                                      item.index,
                                      checkItem,
                                      deleteItem,
                                    ),
                                  ),
                            listController: controller,
                            addLongPressReorderable: editMode,
                            reorderModel: editMode
                                ? AutomaticAnimatedListReorderModel(currentList)
                                : null,
                            detectMoves: editMode,
                          ),
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

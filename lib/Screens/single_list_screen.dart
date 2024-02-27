import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:great_list_view/great_list_view.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import '../Widgets/edit_item_title_popup.dart';
import '../Widgets/item_list.dart';
import '../Utils/strings.dart';
import '../Models/to_do_item.dart';
import '../Models/to_do_list.dart';
import '../Providers/item_provider.dart';
import '../Providers/lists_provider.dart';
import '../Widgets/uicorn_button.dart';

class SingleListScreen extends StatefulWidget {
  final String listId;
  static const routeName = '/single_list_screen';

  const SingleListScreen({required this.listId, Key? key}) : super(key: key);

  @override
  State<SingleListScreen> createState() => _SingleListScreenState();
}

class _SingleListScreenState extends State<SingleListScreen> {
  late DateTime newDeadline;
  final TextEditingController _titleController = TextEditingController();
  bool isLoading = false;
  bool newTextEmpty = false;
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
          ? DateTime.now().add(const Duration(days: 7))
          : newDeadline,
      firstDate: DateTime.now().add(
        const Duration(days: 1),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          newDeadline = selectedDate;
        });
      }
    });
  }

  void addNewItem(String newTitle) async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    if (newTitle.trim().isNotEmpty) {
      ToDoItem? newItem =
          await itemProvider.addNewItem(list!.id, newTitle.trim());

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

  void showMessage(String text) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: text,
        backgroundColor: Theme.of(context).highlightColor,
        icon: const Icon(
          Icons.notifications_active,
          color: Color(0x15000000),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      displayDuration: Duration(seconds: 1),
    );
  }

  void _save() async {
    String newTitle = _titleController.text.trim();
    setState(() {
      isLoading = true;
    });
    if (list!.deadline != newDeadline) {
      String? result = await Provider.of<ListsProvider>(context, listen: false)
          .editDeadline(list!, newDeadline);
      if (result != null) {
        showMessage(
            "${context.translate(Strings.scheduleNotificationFor)} $result");
      }
    }
    if (list!.title != newTitle) {
      await Provider.of<ListsProvider>(context, listen: false)
          .editTitle(list!, newTitle);
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
        .toggleItemDone(id, listId, done, context);
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
    List<UnicornButton> childButtons = [];

    childButtons.add(
      UnicornButton(
        currentButton: FloatingActionButton(
            heroTag: "Text",
            backgroundColor: const Color(0xFF635985),
            mini: true,
            onPressed: () {
              _showNewItemDialog(context);
            },
            child: const Icon(Icons.text_fields)),
      ),
    );

    childButtons.add(
      UnicornButton(
        currentButton: FloatingActionButton(
            heroTag: "notification",
            backgroundColor: Color(0xFF634999),
            mini: true,
            onPressed: () {
              print("notification");
            },
            child: const Icon(Icons.notification_add)),
      ),
    );

    // childButtons.add(
    //   UnicornButton(
    //     currentButton: FloatingActionButton(
    //         heroTag: "directions",
    //         backgroundColor: Color(0xFF635985), //Colors.blueAccent,
    //         mini: true,
    //         onPressed: () {
    //           print("link");
    //         },
    //         child: Icon(Icons.link)),
    //   ),
    // );

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      floatingActionButton: editMode
          ? UnicornDialer(
              backgroundColor: Colors.transparent,
              parentButton: Icon(
                Icons.calendar_month,
                color: list!.hasDeadline
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                size: MediaQuery.of(context).size.width * 0.1,
              ),
              childButtons: [],
              onMainButtonPressed: list!.hasDeadline
                  ? () {
                      _showChangeDateDialog(context);
                    }
                  : () {},
              finalButtonIcon: Icon(Icons.close),
            )
          : UnicornDialer(
              backgroundColor: Colors.transparent,
              parentButton: Icon(
                Icons.add,
                color: Theme.of(context).primaryColor,
                size: MediaQuery.of(context).size.width * 0.1,
              ),
              childButtons: childButtons,
              onMainButtonPressed: () {},
              finalButtonIcon: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
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
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 110,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        editMode
                            ? IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () {
                                  setState(() {
                                    newDeadline = list!.deadline;
                                    _titleController.text = list!.title;
                                    toggleEditMode();
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                        editMode
                            ? Expanded(
                                child: TextField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: (txt) {
                                    setState(() {
                                      newTextEmpty = txt.trim().isEmpty;
                                    });
                                  },
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
                            : Expanded(
                                child: Text(
                                  _titleController.text,
                                  textAlign: TextAlign.center,
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
                                icon: const Icon(Icons.save),
                                onPressed: newTextEmpty
                                    ? null
                                    : () {
                                        _save();
                                      },
                              )
                            : IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: toggleEditMode,
                              ),
                      ],
                    ),
                  ),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height -
                                  MediaQuery.of(context).padding.top -
                                  (110 + 40),
                              child: ItemList(
                                toggleEditMode: toggleEditMode,
                                editMode: editMode,
                                currentList: currentList,
                                editList: editList,
                                reorderItems: reorderItems,
                                checkItem: checkItem,
                                controller: itemListController,
                                updateSingleListScreen: initListDate,
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            )
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

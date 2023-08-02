import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool editMode = false;
  bool _isLoading = false;

  void _moveToItemPage(BuildContext context, String itemID) {
    print("Moving to item page: $itemID");
  }

  void _showNewItemDialog(BuildContext context) {
    String newTitle = ''; // Initialize with an empty string

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter New Item Title',
              style: TextStyle(color: Color(0xFF635985))),
          content: TextField(
            onChanged: (value) {
              newTitle =
                  value; // Update the newTitle variable when the user enters text
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel', style: TextStyle(color: Color(0xFF635985))),
            ),
            TextButton(
              onPressed: () {
                // Obtain the instance of ItemProvider
                final itemProvider =
                    Provider.of<ItemProvider>(context, listen: false);

                // Check if the entered title is not empty
                if (newTitle.isNotEmpty) {
                  // Add a new item using the addNewItem function
                  itemProvider.addNewItem(widget.list.id, newTitle);
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Handle empty title, show an error message, or any other validation you prefer
                }
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

  void deleteItem(String id, bool done, context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    itemProvider.deleteItemById(id, done);
  }

  Future<void> _toggleItemDone(bool? value, ToDoItem item) async {
    if (_isLoading)
      return; // Avoid multiple requests while the function is still processing
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ItemProvider>(context, listen: false)
          .toggleItemDone(item.id, item.listId, item.done);
    } catch (error) {
      print("Error toggling item's done state: $error");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: editMode
          ? FloatingActionButton(
              onPressed: () {
                // Show the popup dialog to get the new item title
                _showNewItemDialog(context);
              },
              backgroundColor: Color(0xFF635985),
              child: const Icon(Icons.calendar_month),
            )
          : FloatingActionButton(
              onPressed: () {
                // Show the popup dialog to get the new item title
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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    editMode
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            onPressed: () {
                              setState(() {
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
                    Text(
                      widget.list.title,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: editMode
                          ? Icon(Icons.save, color: Colors.white)
                          : Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          editMode = !editMode;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ToDoItem>>(
                  future: Provider.of<ItemProvider>(context)
                      .itemsByListId(widget.list.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        _isLoading) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error fetching data'),
                      );
                    } else {
                      List<ToDoItem> todoItems = snapshot.data ?? [];

                      todoItems.sort((a, b) {
                        if (a.done && !b.done) {
                          return 1;
                        } else if (!a.done && b.done) {
                          return -1;
                        } else {
                          return a.index.compareTo(b.index);
                        }
                      });

                      return ReorderableListView.builder(
                        onReorder: (editMode
                            ? (int oldIndex, int newIndex) {
                                if (oldIndex < newIndex) newIndex -= 1;
                                final ToDoItem movedItem =
                                    todoItems.removeAt(oldIndex);
                                todoItems.insert(newIndex, movedItem);

                                for (int i = 0; i < todoItems.length; i++) {
                                  todoItems[i].index = i;
                                }
                              }
                            : (_, __) {}),
                        buildDefaultDragHandles: editMode,
                        itemCount: todoItems.length,
                        itemBuilder: (context, index) {
                          final item = todoItems[index];
                          return Container(
                            margin: EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0))),
                            key: Key(item.id),
                            child: Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                deleteItem(item.id, item.done, context);
                              },
                              background: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                color: Colors.red,
                                child: const Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                onTap: () {
                                  _moveToItemPage(context, item.id);
                                },
                                leading: editMode
                                    ? Icon(Icons.drag_handle)
                                    : Text(
                                        (index + 1).toString(),
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xFF945985),
                                            fontWeight: FontWeight.bold),
                                      ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                trailing: _isLoading
                                    ? Checkbox(
                                        activeColor: Color(0xFF945985),
                                        value: item.done,
                                        onChanged: (value) {},
                                      )
                                    : Checkbox(
                                        activeColor: Color(0xFF945985),
                                        value: item.done,
                                        onChanged: (value) {
                                          _toggleItemDone(value, item);
                                        },
                                      ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

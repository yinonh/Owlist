import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Widgets/to_do_item_widget.dart';
import '../Models/to_do_item.dart';
import '../Models/to_do_list.dart';
import '../Providers/item_provider.dart';

class SingleListScreen extends StatefulWidget {
  final ToDoList list;
  static const routeName = '/single_list_screen';

  SingleListScreen({required this.list, Key? key}) : super(key: key);

  @override
  State<SingleListScreen> createState() => _SingleListScreenState();
}

class _SingleListScreenState extends State<SingleListScreen> {
  bool editMode = false;

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
                final itemProvider =
                    Provider.of<ItemProvider>(context, listen: false);

                if (newTitle.isNotEmpty) {
                  itemProvider.addNewItem(widget.list.id, newTitle);
                  Navigator.of(context).pop();
                } else {
                  // Handle empty title
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: editMode
          ? FloatingActionButton(
              onPressed: () {
                _showNewItemDialog(context);
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
                child: Consumer<ItemProvider>(
                  builder: (context, itemProvider, _) {
                    return FutureBuilder<List<ToDoItem>>(
                      future: itemProvider.itemsByListId(widget.list.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                      BorderRadius.all(Radius.circular(10.0)),
                                ),
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
                                      padding: EdgeInsets.fromLTRB(
                                          0.0, 0.0, 10.0, 0.0),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  child: ToDoItemWidget(item, editMode, index),
                                ),
                              );
                            },
                          );
                        }
                      },
                    );
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

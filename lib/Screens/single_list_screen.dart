import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Models/to_do_item.dart';
import '../Providers/item_provider.dart';
import '../Providers/lists_provider.dart';

class SingleListScreen extends StatelessWidget {
  final String id;
  static const routeName = '/single_list_screen';

  SingleListScreen({required this.id, Key? key}) : super(key: key);

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
                  itemProvider.addNewItem(id, newTitle);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FutureBuilder<String?>(
                      future: ListsProvider().getItemTitleById(id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError || snapshot.data == null) {
                          return Text(
                            'Error fetching title',
                            style: TextStyle(color: Colors.white),
                          );
                        } else {
                          return Text(
                            snapshot.data!,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ToDoItem>>(
                  future: Provider.of<ItemProvider>(context).itemsByListId(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                        onReorder: (int oldIndex, int newIndex) {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final ToDoItem movedItem =
                              todoItems.removeAt(oldIndex);
                          todoItems.insert(newIndex, movedItem);

                          for (int i = 0; i < todoItems.length; i++) {
                            todoItems[i].index = i;
                          }
                        },
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
                                // ... your existing onDismissed logic ...
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
                                leading: Icon(Icons.drag_handle),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                trailing: Checkbox(
                                  activeColor: Color(0xFF945985),
                                  value: item.done,
                                  onChanged: (value) {},
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

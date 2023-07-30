import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Models/to_do_item.dart';
import '../Providers/lists_provider.dart';
import '../Providers/item_provider.dart';

class SingleListScreen extends StatefulWidget {
  final String id;
  static const routeName = '/single_list_screen';
  @override
  _SingleListScreenState createState() => _SingleListScreenState();

  const SingleListScreen({required this.id, Key? key}) : super(key: key);
}

class _SingleListScreenState extends State<SingleListScreen> {
  late String title;
  late List<ToDoItem> todoItems;

  @override
  void initState() {
    super.initState();
    title = "Hello";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    List<ToDoItem>? itemList =
        Provider.of<ItemProvider>(context).items_by_listId(widget.id);
    if (itemList == null) {
      todoItems = [];
    } else {
      todoItems = itemList;
    }
  }

  void _moveToItemPage(BuildContext context, String itemID) {
    print("Moving to item page: $itemID");
  }

  @override
  Widget build(BuildContext context) {
    todoItems.sort((a, b) {
      if (a.done && !b.done) {
        return 1;
      } else if (!a.done && b.done) {
        return -1;
      } else {
        return a.index.compareTo(b.index);
      }
    });
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) newIndex--;
                    setState(() {
                      if (oldIndex < newIndex) {
                        for (int i = oldIndex + 1; i <= newIndex; i++) {
                          todoItems[i].index = i - 1;
                        }
                      } else if (oldIndex > newIndex) {
                        for (int i = oldIndex - 1; i >= newIndex; i--) {
                          todoItems[i].index = i + 1;
                        }
                      }
                      todoItems[oldIndex].index = newIndex;
                    });
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
                          setState(() {
                            todoItems.removeAt(index);
                          });
                        },
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: Colors.red,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
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
                            onChanged: (value) {
                              setState(() {
                                item.done = value ?? false;
                              });
                            },
                          ),
                        ),
                      ),
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

import 'package:flutter/material.dart';

import './to_do_item_tile.dart';
import '../Models/to_do_list.dart';

class ItemsScreen extends StatelessWidget {
  final int selectedIndex;
  final List<ToDoList> existingItems;
  final Function deleteItem;
  final Function refresh;

  const ItemsScreen({
    required this.selectedIndex,
    required this.existingItems,
    required this.deleteItem,
    required this.refresh,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: existingItems.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ToDoItemTile(
            item: existingItems[index],
            onDelete: (item) {
              deleteItem(item);
            },
            refresh: refresh,
          ),
        );
      },
    );
  }
}

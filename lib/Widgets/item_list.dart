import 'package:flutter/material.dart';
import 'package:great_list_view/great_list_view.dart';

import '../Models/to_do_item.dart';
import '../Widgets/to_do_item_widget.dart';

class ItemList extends StatefulWidget {
  final bool editMode;
  final List<ToDoItem> currentList;
  final List<ToDoItem> editList;
  final Function reorderItems;
  final Function deleteItem;
  final Function checkItem;
  final AnimatedListController controller;

  const ItemList(
      {required this.editMode,
      required this.currentList,
      required this.editList,
      required this.reorderItems,
      required this.checkItem,
      required this.deleteItem,
      required this.controller,
      Key? key})
      : super(key: key);

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    return widget.editMode
        ? ReorderableListView.builder(
            itemCount: widget.editList.length,
            itemBuilder: (context, index) {
              final item = widget.editList[index];
              return Container(
                key: Key(item.id), // Key for reordering
                margin: EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      // offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ToDoItemWidget(
                  item,
                  true,
                  item.index,
                  widget.checkItem,
                  widget.deleteItem,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              widget.reorderItems(oldIndex, newIndex);
              // // Reorder logic here
              // setState(() {
              //   if (newIndex > oldIndex) newIndex -= 1;
              //   final ToDoItem item = widget.currentList.removeAt(oldIndex);
              //   widget.currentList.insert(newIndex, item);
              // });
            },
          )
        : AutomaticAnimatedListView<ToDoItem>(
            list: widget.currentList,
            comparator: AnimatedListDiffListComparator<ToDoItem>(
              sameItem: (a, b) => a.id == b.id,
              sameContent: (a, b) => a.title == b.title,
            ),
            itemBuilder: (context, item, data) => data.measuring
                ? Container(margin: EdgeInsets.all(5), height: 50)
                : Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          // offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ToDoItemWidget(
                      item,
                      false,
                      item.index,
                      widget.checkItem,
                      widget.deleteItem,
                    ),
                  ),
            listController: widget.controller,
            addLongPressReorderable: false,
            detectMoves: false,
          );
  }
}

import 'package:flutter/material.dart';
import 'package:great_list_view/great_list_view.dart';

import '../Models/to_do_item.dart';
import '../Widgets/to_do_item_widget.dart';

class ItemList extends StatefulWidget {
  final bool editMode;
  final List<ToDoItem> currentList;
  final List<ToDoItem> editList;
  final Function reorderItems;
  final Function checkItem;
  final void Function() toggleEditMode;
  final Function updateSingleListScreen;
  final AnimatedListController controller;

  const ItemList(
      {required this.editMode,
      required this.currentList,
      required this.editList,
      required this.reorderItems,
      required this.checkItem,
      required this.toggleEditMode,
      required this.controller,
      required this.updateSingleListScreen,
      super.key});

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
              return ToDoItemWidget(
                item,
                true,
                widget.checkItem,
                widget.updateSingleListScreen,
              );
            },
            onReorder: (oldIndex, newIndex) {
              widget.reorderItems(oldIndex, newIndex);
            },
          )
        : GestureDetector(
            onLongPress: widget.toggleEditMode,
            child: AutomaticAnimatedListView<ToDoItem>(
              list: widget.currentList,
              comparator: AnimatedListDiffListComparator<ToDoItem>(
                sameItem: (a, b) => a.id == b.id,
                sameContent: (a, b) => a.title == b.title,
              ),
              itemBuilder: (context, item, data) {
                if (data.measuring) {
                  return Container(margin: const EdgeInsets.all(5), height: 50);
                } else {
                  return ToDoItemWidget(
                    item,
                    false,
                    widget.checkItem,
                    widget.updateSingleListScreen,
                  );
                }
              },
              listController: widget.controller,
              addLongPressReorderable: false,
              detectMoves: false,
            ),
          );
  }
}

import 'package:flutter/material.dart';
import 'package:great_list_view/great_list_view.dart';

import '../Models/to_do_item.dart';
import '../Widgets/to_do_item_widget.dart';

class ItemList extends StatelessWidget {
  final bool editMode;
  final List<ToDoItem> currentList;
  final Function deleteItem;
  final Function checkItem;
  final AnimatedListController controller;

  const ItemList(
      {required this.editMode,
      required this.currentList,
      required this.checkItem,
      required this.deleteItem,
      required this.controller,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    AutomaticAnimatedListReorderModel animation =
        AutomaticAnimatedListReorderModel(currentList);
    print("build");
    print(editMode);
    if (editMode) {
      print("here");
      return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          child: AutomaticAnimatedListView<ToDoItem>(
            list: currentList,
            comparator: AnimatedListDiffListComparator<ToDoItem>(
              sameItem: (a, b) => a.id == b.id,
              sameContent: (a, b) => a.title == b.title,
            ),
            itemBuilder: (context, item, data) => data.measuring
                ? Container(margin: EdgeInsets.all(5), height: 50)
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
                      true,
                      item.index,
                      checkItem,
                      deleteItem,
                    ),
                  ),
            listController: controller,
            addLongPressReorderable: true,
            reorderModel: animation,
            detectMoves: true,
          ));
    } else {
      return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          child: ListView.builder(
            itemCount: currentList.length,
            itemBuilder: (context, index) {
              final item = currentList[index];
              return Container(
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
              );
            },
          ));
    }
  }
}

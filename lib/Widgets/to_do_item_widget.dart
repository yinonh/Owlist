import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Models/to_do_item.dart';
import '../Providers/item_provider.dart';

class ToDoItemWidget extends StatefulWidget {
  final ToDoItem item;
  final bool editMode;
  final int index;
  final Function checkItem;
  final Function deleteItem;

  ToDoItemWidget(
      this.item, this.editMode, this.index, this.checkItem, this.deleteItem,
      {Key? key})
      : super(key: key);

  @override
  _ToDoItemWidgetState createState() => _ToDoItemWidgetState();
}

class _ToDoItemWidgetState extends State<ToDoItemWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: 55,
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          widget.deleteItem(widget.item.id, widget.item.done, context);
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
            print("move to" + widget.item.id + "page");
          },
          leading: widget.editMode
              ? Icon(Icons.drag_handle)
              : Text(
                  (widget.index + 1).toString(),
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF945985),
                    fontWeight: FontWeight.bold,
                  ),
                ),
          title: Text(
            widget.item.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          trailing: Checkbox(
            activeColor: Color(0xFF945985),
            value: widget.item.done,
            onChanged: widget.editMode
                ? null
                : (value) {
                    setState(() {
                      widget.checkItem(
                          widget.item.id, widget.item.listId, widget.item.done);
                    });
                  },
          ),
        ),
      ),
    );
  }
}

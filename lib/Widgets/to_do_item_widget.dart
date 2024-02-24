import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/Providers/item_provider.dart';
import 'package:to_do/Utils/strings.dart';

import '../Screens/content_screen.dart';
import '../Models/to_do_item.dart';
import 'dog_ear_list_tile.dart';

class ToDoItemWidget extends StatefulWidget {
  final ToDoItem item;
  final bool editMode;
  final Function checkItem;
  final Function updateSingleListScreen;

  ToDoItemWidget(
      this.item, this.editMode, this.checkItem, this.updateSingleListScreen,
      {Key? key})
      : super(key: key ?? ValueKey(item.id));

  @override
  _ToDoItemWidgetState createState() => _ToDoItemWidgetState();
}

class _ToDoItemWidgetState extends State<ToDoItemWidget> {
  bool _itemVisible = true;

  void dismiss(ItemProvider provider) {
    provider.deleteItemById(widget.item.id, widget.item.done);
    // Create a Completer to control the flow
    Completer<bool> completer = Completer<bool>();

    setState(() {
      _itemVisible = false;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.translate(Strings.itemDeleted),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).highlightColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 6,
        margin: const EdgeInsets.all(10),
        action: SnackBarAction(
          label: context.translate(Strings.undo),
          onPressed: () {
            provider.addExistingItem(widget.item);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            setState(() {
              _itemVisible = true;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ItemProvider itemProvider = Provider.of<ItemProvider>(context);
    return Visibility(
      maintainAnimation: true,
      maintainState: true,
      visible: _itemVisible,
      child: AnimatedOpacity(
        opacity: _itemVisible ? 1.0 : 0.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 5),
          decoration: widget.editMode
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      // offset: Offset(0, 3),
                    ),
                  ],
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).hintColor.withOpacity(0.5),
                      spreadRadius: 0.5,
                      blurRadius: 1.5,
                      // offset: Offset(0, 3),
                    ),
                  ],
                ),
          child: Dismissible(
            direction: DismissDirection.startToEnd,
            key: UniqueKey(),
            onDismissed: (DismissDirection direction) {
              dismiss(itemProvider);
            },
            background: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(10.0), // Adjust the radius as needed
                color: Colors.red,
              ),
              alignment: AlignmentDirectional.centerStart,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Icon(
                    Icons.delete,
                  ),
                ),
              ),
            ),
            child: DogEarListTile(
              onTap: () {
                Navigator.of(context).pushNamed(
                  ContentScreen.routeName,
                  arguments: {
                    'id': widget.item.id,
                  },
                ).then((value) => widget.updateSingleListScreen());
              },
              leading: widget.editMode
                  ? Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).hintColor,
                    )
                  : const SizedBox(
                      width: 10,
                    ),
              title: Text(
                widget.item.title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              trailing: Checkbox(
                // activeColor: Color(0xFF945985),
                value: widget.item.done,
                onChanged: widget.editMode
                    ? null
                    : (value) {
                        setState(() {
                          widget.checkItem(widget.item.id, widget.item.listId,
                              widget.item.done);
                        });
                      },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

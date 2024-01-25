import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../Screens/content_screen.dart';
import '../Models/to_do_item.dart';
import 'dog_ear_list_tile.dart';

class ToDoItemWidget extends StatefulWidget {
  final ToDoItem item;
  final bool editMode;
  final int index;
  final Function checkItem;
  final Function deleteItem;
  final Function updateSingleListScreen;

  const ToDoItemWidget(this.item, this.editMode, this.index, this.checkItem,
      this.deleteItem, this.updateSingleListScreen,
      {Key? key})
      : super(key: key);

  @override
  _ToDoItemWidgetState createState() => _ToDoItemWidgetState();
}

class _ToDoItemWidgetState extends State<ToDoItemWidget> {
  Future<bool?> confirmDismiss(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text(
            AppLocalizations.of(context).translate("Confirm Deletion"),
            // Replace with your localization logic
          ),
          content: Text(
            AppLocalizations.of(context)
                .translate("Are you sure you want to delete this item?"),
            // Replace with your localization logic
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                AppLocalizations.of(context).translate("Cancel"),
                // Replace with your localization logic
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                AppLocalizations.of(context).translate("Delete"),
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: 55,
      duration: const Duration(milliseconds: 100),
      // decoration: BoxDecoration(),
      child: Dismissible(
        direction: DismissDirection.startToEnd,
        key: UniqueKey(),
        onDismissed: (direction) {
          widget.deleteItem(widget.item.id, widget.item.done, context);
        },
        confirmDismiss: (DismissDirection direction) async {
          return await confirmDismiss(context);
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
                'updateSingleListScreen': widget.updateSingleListScreen,
              },
            );
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

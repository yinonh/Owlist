import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Models/to_do_item.dart';
import '../Providers/item_provider.dart';
import '../Screens/content_screen.dart';
import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/strings.dart';
import '../Widgets/dog_ear_list_tile.dart';

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
    widget.updateSingleListScreen();

    setState(() {
      _itemVisible = false;
    });
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: context.translate(Strings.itemDeletedPressHereToUndo),
        backgroundColor: Theme.of(context).highlightColor,
        icon: Icon(
          Icons.warning_rounded,
          color: Theme.of(context).primaryColorDark.withValues(alpha: 0.2),
          size: 120,
        ),
      ),
      onTap: () {
        provider.addExistingItem(widget.item);
        widget.updateSingleListScreen();
        _itemVisible = true;
      },
      snackBarPosition: SnackBarPosition.top,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 80,
      ),
      displayDuration: const Duration(seconds: 1, milliseconds: 500),
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
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: widget.editMode
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
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
                      color: Theme.of(context).hintColor.withValues(alpha: 0.5),
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
                    Icons.delete_rounded,
                  ),
                ),
              ),
            ),
            child: widget.editMode
                ? ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: Icon(
                      Icons.drag_handle_rounded,
                      color: Theme.of(context).hintColor,
                    ),
                    title: Text(
                      widget.item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    trailing: Checkbox(
                      // activeColor: Color(0xFF945985),
                      value: widget.item.done,
                      onChanged: null,
                    ),
                  )
                : DogEarListTile(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        ContentScreen.routeName,
                        arguments: {
                          Keys.id: widget.item.id,
                        },
                      ).then((value) => widget.updateSingleListScreen());
                    },
                    leading: const SizedBox(
                      width: 10,
                    ),
                    title: Text(
                      widget.item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    trailing: Checkbox(
                      // activeColor: Color(0xFF945985),
                      value: widget.item.done,
                      onChanged: (value) {
                        setState(() {
                          widget.checkItem(widget.item);
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../Models/to_do_list.dart';
import '../Screens/single_list_screen.dart';

class ToDoItemTile extends StatefulWidget {
  final ToDoList item;
  final Function(ToDoList) onDelete;
  final Function refresh;
  // bool is_done = false;

  ToDoItemTile(
      {required this.item, required this.refresh, required this.onDelete});

  @override
  State<ToDoItemTile> createState() => _ToDoItemTileState();
}

class _ToDoItemTileState extends State<ToDoItemTile> {
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10.0,
            ),
          ),
          title: Text(
              AppLocalizations.of(context).translate("Confirm Deletion"),
              style: Theme.of(context).textTheme.titleMedium),
          content: Text(
            AppLocalizations.of(context)
                .translate("Are you sure you want to delete this item?"),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                AppLocalizations.of(context).translate("Cancel"),
                style: Theme.of(context).textTheme.titleLarge,
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
    ).then((value) {
      if (value == true) {
        widget.onDelete(widget.item);
      }
    });
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime currentDate = DateTime.now();

    final int totalDays =
        widget.item.deadline.difference(widget.item.creationDate).inDays;
    final int remaining =
        widget.item.deadline.difference(currentDate).inDays + 1;
    double progressPercentage;
    if (widget.item.totalItems != 0) {
      progressPercentage =
          (widget.item.accomplishedItems / widget.item.totalItems);
    } else {
      progressPercentage = 1;
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, SingleListScreen.routeName,
                arguments: widget.item.id)
            .then((value) {
          setState(() {
            widget.refresh();
          });
        });
      },
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).hintColor,
              offset: Offset.fromDirection(3.7),
              spreadRadius: -0.4,
              //Use negative value above for the inner shadow effect
              blurRadius: 2.0,
            ),
          ],
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FittedBox(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Text(
                        widget.item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showDeleteConfirmation(context);
                    },
                    icon: Icon(Icons.delete,
                        color: Theme.of(context).highlightColor),
                  ),
                ],
              ),
              widget.item.hasDeadline
                  ? Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDate(widget
                                    .item.creationDate), // Format creationDate
                              ),
                              Text(
                                formatDate(
                                    widget.item.deadline), // Format deadline
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          LinearProgressIndicator(
                            value: remaining <= 0
                                ? 1
                                : (totalDays - remaining) / totalDays,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '${AppLocalizations.of(context).translate("Remaining Days:")} ${remaining <= 0 ? AppLocalizations.of(context).translate("Done") : remaining}',
                            // style: TextStyle(fontSize: 16.0),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)
                              .translate("Creation Date: ") +
                          formatDate(
                              widget.item.creationDate), // Format creationDate
                    ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context).translate("Total Items:")} ${widget.item.totalItems}',
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${AppLocalizations.of(context).translate("Accomplished Items:")} ${widget.item.accomplishedItems}',
                    // style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              widget.item.totalItems > 0
                  ? Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progressPercentage,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '${AppLocalizations.of(context).translate("Progress:")} ${(progressPercentage * 100).toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }
}

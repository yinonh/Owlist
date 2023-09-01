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
            style: TextStyle(color: Color(0xFF864879)),
          ),
          content: Text(
            AppLocalizations.of(context)
                .translate("Are you sure you want to delete this item?"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                AppLocalizations.of(context).translate("Cancel"),
                style: TextStyle(
                  color: Color(0xFF864879),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                AppLocalizations.of(context).translate("Delete"),
                style: TextStyle(
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
    final int remainingDays =
        widget.item.deadline.difference(currentDate).inDays;
    double progressPercentage;
    if (widget.item.totalItems != 0) {
      progressPercentage =
          (widget.item.accomplishedItems / widget.item.totalItems);
    } else {
      progressPercentage = 1;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, SingleListScreen.routeName,
                arguments: widget.item)
            .then((value) {
          setState(() {
            widget.refresh();
          });
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF864879),
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        _showDeleteConfirmation(context);
                      },
                      icon: Icon(Icons.delete, color: Color(0xFF393053)))
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
                                style: const TextStyle(
                                  // fontSize: 16.0,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                formatDate(
                                    widget.item.deadline), // Format deadline
                                style: const TextStyle(
                                  // fontSize: 16.0,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          LinearProgressIndicator(
                            value: remainingDays <= 0
                                ? 1
                                : (totalDays - remainingDays) / totalDays,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF393053)),
                            minHeight: 10.0,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            AppLocalizations.of(context)
                                    .translate("Remaining Days:") +
                                ' ${remainingDays <= 0 ? AppLocalizations.of(context).translate("Done") : remainingDays}',
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
                      style: const TextStyle(
                        // fontSize: 16.0,
                        color: Colors.black,
                      ),
                    ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate("Total Items:") +
                        ' ${widget.item.totalItems}',
                    // style: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    AppLocalizations.of(context)
                            .translate("Accomplished Items:") +
                        ' ${widget.item.accomplishedItems}',
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
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF635985)),
                            minHeight: 10.0,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            AppLocalizations.of(context)
                                    .translate("Progress:") +
                                ' ${(progressPercentage * 100).toStringAsFixed(0)}%',
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

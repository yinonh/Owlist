import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Utils/l10n/app_localizations.dart';
import '../Models/to_do_list.dart';
import '../Screens/single_list_screen.dart';

class ToDoItemTile extends StatefulWidget {
  final ToDoList item;
  final Function(ToDoList) onDelete;
  final Function refresh;

  const ToDoItemTile(
      {super.key,
      required this.item,
      required this.refresh,
      required this.onDelete});

  @override
  State<ToDoItemTile> createState() => _ToDoItemTileState();
}

class _ToDoItemTileState extends State<ToDoItemTile> {
  late int totalHours;
  late int remainingHours;
  late double progressPercentage;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  void _calculateProgress() {
    setState(() {
      totalHours =
          widget.item.deadline.difference(widget.item.creationDate).inHours;

      if (DateTime.now().isBefore(widget.item.deadline)) {
        remainingHours =
            widget.item.deadline.difference(DateTime.now()).inHours;
      } else {
        remainingHours = 0;
      }

      progressPercentage = widget.item.totalItems != 0
          ? (widget.item.accomplishedItems / widget.item.totalItems)
          : 1;
    });
  }

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

  String getDeadlineDiff(DateTime deadline) {
    DateTime now = DateTime.now();

    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime deadlineDay =
        DateTime(deadline.year, deadline.month, deadline.day);

    if (deadlineDay.isBefore(today)) {
      return AppLocalizations.of(context).translate("Done");
    } else if (deadlineDay.isAtSameMomentAs(today)) {
      return AppLocalizations.of(context).translate("Today");
    } else {
      Duration difference = deadlineDay.difference(today);
      if (difference.inDays > 1) {
        return '${AppLocalizations.of(context).translate("Remaining Days:")} ${difference.inDays}';
      } else {
        int hoursDifference = deadline.difference(now).inHours;
        return '${AppLocalizations.of(context).translate("Remaining Hours:")} $hoursDifference';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  ? Column(
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
                        const SizedBox(height: 8.0),
                        LinearProgressIndicator(
                          value: remainingHours <= 0
                              ? 1
                              : (totalHours - remainingHours) / totalHours,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          getDeadlineDiff(widget.item.deadline),
                          // style: TextStyle(fontSize: 16.0),
                        ),
                      ],
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
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context).translate("Total Items:")} ${widget.item.totalItems}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context).translate("Accomplished Items:")} ${widget.item.accomplishedItems}',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              widget.item.totalItems > 0
                  ? Column(
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
                    )
                  : const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }
}

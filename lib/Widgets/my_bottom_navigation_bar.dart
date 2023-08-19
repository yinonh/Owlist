import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Widgets/date_picker.dart';
import '../Providers/lists_provider.dart';

class MyBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Function add_item;

  MyBottomNavigationBar(
      {required this.currentIndex,
      required this.onTap,
      required this.add_item});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  bool hasDeadline = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF393053),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavigationItem(Icons.fact_check, "Active", 0),
              const SizedBox(
                width: 0,
              ),
              _buildBottomNavigationItem(Icons.archive, "Archived", 1),
            ],
          ),
          Positioned(
            bottom: 0,
            child: ElevatedButton(
              onPressed: () {
                TextEditingController new_title = TextEditingController();
                DateTime new_deadline = DateTime.now().add(Duration(days: 7));
                showDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    hasDeadline = true;

                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      title: const Text(
                        'Enter list title',
                        style: TextStyle(color: Color(0xFF635985)),
                      ),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                autofocus: true,
                                controller: new_title,
                                maxLength: 25,
                                decoration: InputDecoration(hintText: "Title"),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Checkbox(
                                    value: hasDeadline,
                                    onChanged: (val) {
                                      setState(() {
                                        hasDeadline = val ??
                                            false; // Ensure a default value
                                      });
                                    },
                                    activeColor: Color(0xFF945985),
                                  ),
                                  hasDeadline
                                      ? DatePickerWidget(
                                          initialDate: new_deadline ??
                                              DateTime.now()
                                                  .add(Duration(days: 7)),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(Duration(days: 3650)),
                                          onDateSelected: (selectedDate) {
                                            if (selectedDate != null)
                                              new_deadline = selectedDate;
                                          },
                                        )
                                      : Text('Check for adding deadline'),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF635985),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Color(0xFF635985),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            if (new_title.text != '') {
                              widget.add_item(
                                  new_title.text, new_deadline, hasDeadline);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.add, size: 30),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                backgroundColor: Color(0xFF635985),
                padding: EdgeInsets.all(15),
                elevation: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationItem(
      IconData iconData, String label, int index) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: widget.currentIndex == index ? 30 : 20,
              color: widget.currentIndex == index ? Colors.white : Colors.grey,
            ),
            if (widget.currentIndex == index) SizedBox(height: 5),
            if (widget.currentIndex == index)
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

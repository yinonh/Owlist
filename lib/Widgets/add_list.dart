import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Widgets/date_picker.dart';
import '../Providers/lists_provider.dart';

class AddList extends StatelessWidget {
  final Function add_item;
  const AddList({required this.add_item, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.add, color: Colors.white),
      onPressed: () {
        TextEditingController new_title = TextEditingController();
        DateTime new_deadline = DateTime.now().add(Duration(days: 7));
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Enter list title',
                style: TextStyle(color: Color(0xFF635985)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: new_title,
                    maxLength: 30,
                    decoration: InputDecoration(hintText: "Title"),
                  ),
                  DatePickerWidget(
                    initialDate: DateTime.now().add(Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    onDateSelected: (selectedDate) {
                      if (selectedDate != null) new_deadline = selectedDate;
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Save',
                    style: TextStyle(
                        color: Color(0xFF635985), fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (new_title.text != '') {
                      add_item(new_title.text, new_deadline);
                    }

                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

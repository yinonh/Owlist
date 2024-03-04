import 'package:flutter/material.dart';
import 'package:to_do/Utils/strings.dart';

class EditItemDialog extends StatefulWidget {
  final Function(String) addNewItem; // Function parameter

  const EditItemDialog({super.key, required this.addNewItem});

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  String newTitle = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.translate(Strings.enterNewItemTitle),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: TextField(
        textCapitalization: TextCapitalization.sentences,
        maxLength: 25,
        autofocus: true,
        decoration: InputDecoration(
          hintText: context.translate(Strings.title),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        onChanged: (value) {
          setState(() {
            newTitle = value;
          });
        },
      ),
      actions: <Widget>[
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                context.translate(Strings.cancel),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.addNewItem(newTitle.trim()); // Use the passed function
              },
              child: Text(
                context.translate(Strings.add),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

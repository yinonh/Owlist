import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class EditItemDialog extends StatefulWidget {
  final Function(String) addNewItem; // Function parameter

  EditItemDialog({required this.addNewItem});

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  String newTitle = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          10.0,
        ),
      ),
      title: Text(
          AppLocalizations.of(context).translate("Enter New Item Title"),
          style: TextStyle(color: Color(0xFF635985))),
      content: TextField(
        maxLength: 35,
        autofocus: true,
        decoration: InputDecoration(
            hintText: AppLocalizations.of(context).translate("Title")),
        onChanged: (value) {
          setState(() {
            newTitle = value;
          });
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).translate("Cancel"),
              style: TextStyle(color: Color(0xFF635985))),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.addNewItem(newTitle); // Use the passed function
          },
          child: Text(AppLocalizations.of(context).translate("Add"),
              style: TextStyle(color: Color(0xFF635985))),
        ),
      ],
    );
  }
}

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
      title: Text(
        AppLocalizations.of(context).translate("Enter New Item Title"),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: TextField(
        maxLength: 35,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).translate("Title"),
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
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            AppLocalizations.of(context).translate("Cancel"),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.addNewItem(newTitle); // Use the passed function
          },
          child: Text(
            AppLocalizations.of(context).translate("Add"),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/strings.dart';

class EditItemDialog extends StatefulWidget {
  final Function(String) addNewItem;

  const EditItemDialog({super.key, required this.addNewItem});

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  String newTitle = Keys.emptyChar;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.translate(Strings.enterNewItemTitle),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          textCapitalization: TextCapitalization.sentences,
          maxLength: 50,
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.translate(Strings.itemMustHaveTitle);
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              newTitle = value;
            });
          },
          inputFormatters: [
            FilteringTextInputFormatter.deny(new RegExp(Keys.filterFormat))
          ],
        ),
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
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  widget.addNewItem(newTitle.trim());
                }
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

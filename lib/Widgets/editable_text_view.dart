import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Utils/strings.dart';

class EditableTextView extends StatefulWidget {
  final String initialText;
  final bool isEditMode;
  final Function toggleEditMode;
  final TextEditingController controller;

  const EditableTextView(
      {super.key,
      required this.initialText,
      required this.isEditMode,
      required this.toggleEditMode,
      required this.controller});

  @override
  _EditableTextViewState createState() => _EditableTextViewState();
}

class _EditableTextViewState extends State<EditableTextView> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = widget.initialText;
  }

  @override
  void didUpdateWidget(EditableTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      widget.controller.text = widget.initialText;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditMode) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              cursorColor: Colors.purpleAccent, // Change cursor color
              style: const TextStyle(
                color: Colors.white,
              ),
              controller: widget.controller,
              maxLines: 12,
              textAlign: TextAlign.start, // Align the text to the start (left)
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purpleAccent),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purpleAccent),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Linkify(
          onOpen: (url) => _onOpen(url),
          text: widget.controller.text.trim(),
          style: const TextStyle(color: Colors.white),
          linkStyle: const TextStyle(color: Colors.blue),
          textAlign: TextAlign.start, // Align the text to the start (left)
          linkifiers: const [
            PhoneNumberLinkifier(),
            UrlLinkifier(),
            EmailLinkifier()
          ],
        ),
      );
    }
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (!await launchUrl(Uri.parse(link.url))) {
      throw Exception(
          '${context.translate(Strings.couldNotLaunch)} ${link.url}');
    }
  }
}

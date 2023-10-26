import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class EditableTextView extends StatefulWidget {
  final String initialText;
  final bool isEditMode;
  final Function toggleEditMode;
  final TextEditingController controller;

  EditableTextView(
      {required this.initialText,
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
  Widget build(BuildContext context) {
    if (widget.isEditMode) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: widget.controller,
              maxLines: null, // Allow multiple lines of text
              textAlign: TextAlign.start, // Align the text to the start (left)
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Linkify(
          onOpen: (url) => _onOpen(url),
          text: widget.controller.text,
          style: TextStyle(fontSize: 16),
          linkStyle: TextStyle(color: Colors.blue),
          textAlign: TextAlign.start, // Align the text to the start (left)
        ),
      );
    }
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (!await launchUrl(Uri.parse(link.url))) {
      throw Exception('Could not launch ${link.url}');
    }
  }
}

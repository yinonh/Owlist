import 'dart:convert'; // For jsonDecode (though parent will handle it)
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart' as quillEmbeds;

import '../Utils/context_extensions.dart'; // For context.translate
import '../Utils/strings.dart'; // For string keys

class EditableTextView extends StatefulWidget {
  final quill.QuillController quillController;
  final bool isEditMode;

  const EditableTextView({
    super.key,
    required this.quillController,
    required this.isEditMode,
  });

  @override
  _EditableTextViewState createState() => _EditableTextViewState();
}

class _EditableTextViewState extends State<EditableTextView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditMode) {
      return Column(
        children: [
          quill.QuillSimpleToolbar(
            controller: widget.quillController,
            config: quill.QuillSimpleToolbarConfig(
              showAlignmentButtons: true,
              embedButtons: quillEmbeds.FlutterQuillEmbeds.toolbarButtons(),
              // Add other configurations as needed
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: quill.QuillEditor.basic(
                controller: widget.quillController,
                focusNode: _focusNode,
                config: quill.QuillEditorConfig(
                  embedBuilders: quillEmbeds.FlutterQuillEmbeds.editorBuilders(),
                  placeholder: context.translate(Strings.startTyping) ?? "Start typing...",
                  padding: const EdgeInsets.all(16),
                  customStyles: quill.DefaultStyles(
                    placeHolder: quill.DefaultListBlockStyle(
                       Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey),
                       const quill.VerticalSpacing(0,0),
                       const quill.VerticalSpacing(0,0),
                       null, null
                    )
                  ),
                  // autoFocus: true, // Parent might control this
                )
              ),
            ),
          ),
        ],
      );
    } else {
      // Read-only view
      final plainText = widget.quillController.document.toPlainText().trim();
      if (plainText.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.translate(Strings.emptyContent) ?? "No content",
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.start,
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: quill.QuillEditor.basic(
          controller: widget.quillController,
          config: quill.QuillEditorConfig(
            padding: const EdgeInsets.all(16),
            readOnly: true,
            embedBuilders: quillEmbeds.FlutterQuillEmbeds.editorBuilders(),
            customStyles: quill.DefaultStyles(
              placeHolder: quill.DefaultListBlockStyle(
                 Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey), // Example placeholder style
                 const quill.VerticalSpacing(0,0),
                 const quill.VerticalSpacing(0,0),
                 null, null
              )
            ),
          )
        ),
      );
    }
  }
}

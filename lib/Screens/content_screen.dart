import 'dart:convert'; // For jsonEncode/jsonDecode

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';

import '../Models/to_do_item.dart';
import '../Providers/item_provider.dart';
// import '../Providers/lists_provider.dart'; // No longer needed for editItemTitle
import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/show_case_helper.dart';
import '../Utils/strings.dart';
import '../Widgets/diamond_button.dart';
import '../Widgets/editable_text_view.dart';

class ContentScreen extends StatefulWidget {
  static const routeName = Keys.contentScreenRouteName;
  final String id;

  const ContentScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late bool titleEditMode;
  final TextEditingController _titleController = TextEditingController();
  quill.QuillController? _quillController;
  late ToDoItem _item;
  bool _isLoading = false;
  bool textEditMode = false;
  bool newTextEmpty = false; // For title TextField
  final GlobalKey<ScaffoldState> addContentKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    titleEditMode = false;
    _quillController = quill.QuillController.basic(); // Initial basic controller
    _getItem();
    if (ShowCaseHelper.instance.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(
          const Duration(milliseconds: 400),
          () => ShowCaseHelper.instance
              .startShowCaseContentAdded(context, [addContentKey]),
        );
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  void _initializeQuillController() {
    _quillController?.dispose(); // Dispose previous controller unconditionally

    try {
      final content = _item.content.trim();
      if (content.isEmpty || content == '{"ops":[{"insert":"\\n"}]}') {
        _quillController = quill.QuillController.basic();
      } else {
        final decodedJson = jsonDecode(content);
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(decodedJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      // If JSON decoding fails, or if it's not JSON, treat as plain text
      _quillController = quill.QuillController(
        document: quill.Document()..insert(0, _item.content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  void _getItem() async {
    setState(() {
      _isLoading = true;
    });
    _item = await Provider.of<ItemProvider>(context, listen: false)
        .itemById(widget.id);
    _titleController.text = _item.title.trim();

    _initializeQuillController();

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleTitleEditMode() {
    setState(() {
      titleEditMode = !titleEditMode;
      if (titleEditMode) {
        newTextEmpty = _titleController.text.trim().isEmpty;
      }
    });
  }

  void toggleTextEditMode() {
    setState(() {
      textEditMode = !textEditMode;
    });
  }

  void _save() async {
    bool titleChanged = false;
    if (titleEditMode) {
      if (_item.title.trim() != _titleController.text.trim() && !_titleController.text.trim().isEmpty) {
        await Provider.of<ItemProvider>(context, listen: false)
            .editItemTitle(_item.id, _titleController.text.trim());
        titleChanged = true;
      }
    }

    bool contentChanged = false;
    if (textEditMode && _quillController != null) {
      final newContentJson = jsonEncode(_quillController!.document.toDelta().toJson());
      if (newContentJson != _item.content) {
        await Provider.of<ItemProvider>(context, listen: false)
            .updateItemContent(_item.id, newContentJson);
        contentChanged = true;
      }
    }

    if (titleChanged || contentChanged) {
      await _getItem();
    }

    setState(() {
      if (titleEditMode) titleEditMode = false;
      if (textEditMode) textEditMode = false;
    });
  }

  void _discard() {
    setState(() {
      if (titleEditMode) {
        _titleController.text = _item.title.trim();
        titleEditMode = false;
      }
      if (textEditMode) {
        _initializeQuillController(); // Reset content to original
        textEditMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      resizeToAvoidBottomInset: true,
      floatingActionButton: Visibility(
        maintainState: true,
        visible: MediaQuery.of(context).viewInsets.bottom == 0 && !titleEditMode, // Hide if title is being edited
        child: DiamondButton(
          icon: Icon(
            Icons.text_fields_rounded,
            color: textEditMode ? Colors.grey : Theme.of(context).primaryColor,
            size: MediaQuery.of(context).size.width * 0.1,
          ),
          onTap: textEditMode ? null : toggleTextEditMode,
          screenWidth: MediaQuery.of(context).size.width,
          screenHeight: MediaQuery.of(context).size.height,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColorLight,
              Theme.of(context).primaryColorDark
            ],
          ),
        ),
        child: _isLoading || _quillController == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 110,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              titleEditMode || textEditMode
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: _discard,
                                    )
                                  : IconButton(
                                      icon:
                                          const Icon(Icons.arrow_back_ios_new),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                              titleEditMode
                                  ? Expanded(
                                      child: TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        autofocus: true,
                                        onChanged: (txt) {
                                          setState(() {
                                            newTextEmpty = txt.trim().isEmpty;
                                          });
                                        },
                                        controller: _titleController,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLength: 50,
                                        decoration: const InputDecoration(
                                          counterText: Keys.emptyChar,
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white54),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white),
                                          ),
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(
                                              RegExp(Keys.filterFormat))
                                        ],
                                        onSubmitted: (_) {
                                           if (!newTextEmpty) _save();
                                        },
                                      ),
                                    )
                                  : Flexible(
                                      child: GestureDetector(
                                        onTap: textEditMode ? null : _toggleTitleEditMode, // Allow title edit only if content not in edit mode
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          _titleController.text.trim(),
                                          style: const TextStyle(
                                            fontSize: 24.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                              titleEditMode || textEditMode
                                  ? IconButton(
                                      icon: const Icon(Icons.save_as_rounded),
                                      onPressed: (titleEditMode && newTextEmpty) ? null : _save,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: textEditMode ? null : _toggleTitleEditMode, // Allow title edit only if content not in edit mode
                                    ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView( // Using ListView to allow potential scrolling if content is very long
                            children: [
                              // SizedBox height might be adjusted or removed if QuillEditor handles all padding
                              // const SizedBox(height: 20,),
                              GestureDetector(
                                // Long press/double tap to toggle edit mode is now handled by DiamondButton for content
                                // onLongPress: toggleTextEditMode,
                                // onDoubleTap: toggleTextEditMode,
                                child: ShowCaseHelper.instance.customShowCase(
                                  key: addContentKey,
                                  description: context.translate(ShowCaseHelper
                                      .instance.contentShowCaseDescription),
                                  context: context,
                                  overlayOpacity: 0,
                                  showArrow: false,
                                  child: EditableTextView(
                                    quillController: _quillController!,
                                    isEditMode: textEditMode,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox( // Space for the DiamondButton or general padding
                          height: (MediaQuery.of(context).size.height -
                                  MediaQuery.of(context).padding.top -
                                  MediaQuery.of(context).padding.bottom) *
                              0.1,
                        )
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

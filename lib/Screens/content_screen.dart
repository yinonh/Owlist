import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../Models/to_do_item.dart';
import '../Providers/item_provider.dart';
import '../Providers/lists_provider.dart';
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
  TextEditingController textEditingController = TextEditingController();
  late ToDoItem _item;
  bool _isLoading = false;
  bool textEditMode = false;
  bool newTextEmpty = false;
  final GlobalKey<ScaffoldState> addContentKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    titleEditMode = false;
    _getItem();
    if (ShowCaseHelper.instance.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(
          Duration(milliseconds: 400),
          () => ShowCaseHelper.instance
              .startShowCaseContentAdded(context, [addContentKey]),
        );
      });
    }
  }

  void _getItem() async {
    setState(() {
      _isLoading = true;
    });
    _item = await Provider.of<ItemProvider>(context, listen: false)
        .itemById(widget.id);
    _titleController.text = _item.title.trim();
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleTitleEditMode() {
    setState(() {
      titleEditMode = !titleEditMode;
    });
  }

  void toggleTextEditMode() {
    setState(() {
      if (_item.content.trim().isEmpty) {
        textEditingController.text = '';
      }
      textEditMode = !textEditMode;
    });
  }

  void _save() async {
    if (titleEditMode) {
      Provider.of<ListsProvider>(context, listen: false)
          .editItemTitle(_item.id, _titleController.text.trim());
      _toggleTitleEditMode();
    }
    if (textEditMode) {
      await Provider.of<ItemProvider>(context, listen: false)
          .updateItemContent(_item.id, textEditingController.text.trim());
      toggleTextEditMode();
    }
    _getItem();
  }

  void _discard() {
    setState(() {
      if (titleEditMode) {
        _titleController.text = _item.title.trim();
        _toggleTitleEditMode();
      }
      if (textEditMode) {
        textEditingController.text = _item.content.trim().isEmpty
            ? context.translate(Strings.addSomeContent)
            : _item.content.trim();
        toggleTextEditMode();
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
        visible: MediaQuery.of(context).viewInsets.bottom == 0,
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
        child: _isLoading
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
                                          // fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLength: 50,
                                        decoration: const InputDecoration(
                                          counterText: Keys.emptyChar,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.deny(
                                              RegExp(Keys.filterFormat))
                                        ],
                                        onSubmitted: (_) {
                                          _save();
                                        },
                                      ),
                                    )
                                  : Flexible(
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
                              titleEditMode || textEditMode
                                  ? IconButton(
                                      icon: const Icon(Icons.save_as_rounded),
                                      onPressed: newTextEmpty ? null : _save,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: _toggleTitleEditMode,
                                    ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              const SizedBox(
                                height: 20,
                              ),
                              GestureDetector(
                                onLongPress: toggleTextEditMode,
                                onDoubleTap: toggleTextEditMode,
                                child: ShowCaseHelper.instance.customShowCase(
                                  key: addContentKey,
                                  description: context.translate(ShowCaseHelper
                                      .instance.contentShowCaseDescription),
                                  context: context,
                                  overlayOpacity: 0,
                                  showArrow: false,
                                  child: EditableTextView(
                                    initialText: _item.content.trim().isEmpty
                                        ? context
                                            .translate(Strings.addSomeContent)
                                        : _item.content.trim(),
                                    isEditMode: textEditMode,
                                    toggleEditMode: toggleTextEditMode,
                                    controller: textEditingController,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
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

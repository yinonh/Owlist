import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Models/to_do_item.dart';
import '../Widgets/diamond_button.dart';
import '../Widgets/editable_text_view.dart';
import '../Widgets/uicorn_button.dart';
import '../l10n/app_localizations.dart';
import '../Providers/lists_provider.dart';
import '../Providers/item_provider.dart';

class ContentScreen extends StatefulWidget {
  static const routeName = '/content';
  final String id;
  final Function updateSingleListScreen;
  const ContentScreen(
      {Key? key, required this.id, required this.updateSingleListScreen})
      : super(key: key);

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late bool titleEditMode;
  TextEditingController _titleController = TextEditingController();
  late ToDoItem _item;
  bool _isLoading = false;
  bool textEditMode = false;
  bool newTextEmpty = false;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    titleEditMode = false;
    _getItem();
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
      textEditMode = !textEditMode;
    });
  }

  void _save() async {
    if (titleEditMode) {
      Provider.of<ListsProvider>(context, listen: false)
          .editItemTitle(_item.id, _titleController.text.trim());
      _toggleTitleEditMode();
      widget.updateSingleListScreen();
    }
    if (textEditMode) {
      await Provider.of<ItemProvider>(context, listen: false)
          .updateItemContent(_item.id, textEditingController.text.trim());
      toggleTextEditMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<UnicornButton> childButtons = [];

    childButtons.add(
      UnicornButton(
        currentButton: FloatingActionButton(
            heroTag: "Text",
            backgroundColor: Color(0xFF635985), //Colors.red,
            mini: true,
            onPressed: () {
              print("text");
            },
            child: Icon(Icons.text_fields)),
      ),
    );

    // childButtons.add(
    //   UnicornButton(
    //     currentButton: FloatingActionButton(
    //         heroTag: "airplane",
    //         backgroundColor: Color(0xFF634999), // Colors.greenAccent,
    //         mini: true,
    //         onPressed: () {
    //           print("location");
    //         },
    //         child: Icon(Icons.image)),
    //   ),
    // );

    // childButtons.add(
    //   UnicornButton(
    //     currentButton: FloatingActionButton(
    //         heroTag: "directions",
    //         backgroundColor: Color(0xFF635985), //Colors.blueAccent,
    //         mini: true,
    //         onPressed: () {
    //           print("link");
    //         },
    //         child: Icon(Icons.link)),
    //   ),
    // );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: DiamondButton(
        icon: Icon(
          Icons.text_fields,
          color: textEditMode ? Colors.grey : Theme.of(context).primaryColor,
          size: MediaQuery.of(context).size.width * 0.1,
        ),
        onTap: textEditMode ? null : toggleTextEditMode,
        screenWidth: MediaQuery.of(context).size.width,
        screenHeight: MediaQuery.of(context).size.height,
      ),
      // floatingActionButton: UnicornDialer(
      //   backgroundColor: Colors.transparent,
      //   parentButton: Icon(Icons.add),
      //   childButtons: childButtons,
      //   onMainButtonPressed: () {},
      //   finalButtonIcon: Icon(Icons.close),
      // ),
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
            ? Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          // height: 80,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              titleEditMode || textEditMode
                                  ? IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed: () {
                                        setState(() {
                                          if (titleEditMode) {
                                            _titleController.text =
                                                _item.title.trim();
                                            _toggleTitleEditMode();
                                          }
                                          if (textEditMode) {
                                            textEditingController.text = _item
                                                    .content
                                                    .trim()
                                                    .isEmpty
                                                ? AppLocalizations.of(context)
                                                    .translate(
                                                        "Add some content")
                                                : _item.content.trim();
                                            toggleTextEditMode();
                                          }
                                        });
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                              titleEditMode
                                  ? Expanded(
                                      child: TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        onChanged: (txt) {
                                          setState(() {
                                            newTextEmpty = txt.trim().isEmpty;
                                          });
                                        },
                                        controller: _titleController,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLength: 25,
                                        // Set the maximum length
                                        decoration: const InputDecoration(
                                          counterText:
                                              "", // Hide the character counter
                                          // border: InputBorder.none,
                                        ),
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
                                      icon: Icon(Icons.save),
                                      onPressed: newTextEmpty ? null : _save,
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: _toggleTitleEditMode,
                                    ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              SizedBox(
                                height: 20,
                              ),
                              GestureDetector(
                                onLongPress: toggleTextEditMode,
                                child: EditableTextView(
                                    initialText: _item.content.trim().isEmpty
                                        ? AppLocalizations.of(context)
                                            .translate("Add some content")
                                        : _item.content.trim(),
                                    isEditMode: textEditMode,
                                    toggleEditMode: toggleTextEditMode,
                                    controller: textEditingController),
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

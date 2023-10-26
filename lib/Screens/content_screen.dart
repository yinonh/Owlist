import 'package:flutter/material.dart';
import 'package:to_do/Models/to_do_item.dart';
import 'package:provider/provider.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Widgets/diamond_button.dart';
import '../Widgets/editable_text_view.dart';
import '../l10n/app_localizations.dart';
import '../Providers/lists_provider.dart';
import '../Providers/item_provider.dart';
import '../Widgets/uicorn_button.dart';

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
  TextEditingController textEditingController = TextEditingController();
  bool textEditMode = false;

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
    _titleController.text = _item.title;
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

    childButtons.add(
      UnicornButton(
        currentButton: FloatingActionButton(
            heroTag: "directions",
            backgroundColor: Color(0xFF635985), //Colors.blueAccent,
            mini: true,
            onPressed: () {
              print("link");
            },
            child: Icon(Icons.link)),
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: DiamondButton(
        icon: Icon(
          textEditMode ? Icons.save : Icons.add,
          color: Theme.of(context).primaryColor,
          size: MediaQuery.of(context).size.width * 0.1,
        ),
        onTap: textEditMode
            ? () async {
                await Provider.of<ItemProvider>(context, listen: false)
                    .updateItemContent(_item.id, textEditingController.text);
                toggleTextEditMode();
              }
            : toggleTextEditMode,
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
                  // alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              Container(
                                height: 75,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 24.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    titleEditMode
                                        ? IconButton(
                                            icon: const Icon(Icons.cancel,
                                                color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _titleController.text =
                                                    _item.title;
                                                _toggleTitleEditMode();
                                              });
                                            },
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.arrow_back,
                                                color: Colors.white),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                    titleEditMode
                                        ? Expanded(
                                            child: TextField(
                                              controller: _titleController,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 19.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLength: 25,
                                              // Set the maximum length
                                              decoration: InputDecoration(
                                                counterText:
                                                    "", // Hide the character counter
                                                // border: InputBorder.none,
                                              ),
                                            ),
                                          )
                                        : Flexible(
                                            child: Text(
                                              _titleController.text,
                                              style: TextStyle(
                                                fontSize: 24.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                    titleEditMode
                                        ? IconButton(
                                            icon: Icon(Icons.save,
                                                color: Colors.white),
                                            onPressed: () {
                                              Provider.of<ListsProvider>(
                                                      context,
                                                      listen: false)
                                                  .editItemTitle(_item.id,
                                                      _titleController.text);
                                              _toggleTitleEditMode();
                                              widget.updateSingleListScreen();
                                            },
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.white),
                                            onPressed: _toggleTitleEditMode,
                                          ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              EditableTextView(
                                  initialText: _item.content,
                                  isEditMode: textEditMode,
                                  toggleEditMode: toggleTextEditMode,
                                  controller: textEditingController)
                            ],
                          ),
                        ),
                        SizedBox(
                          height: (MediaQuery.of(context).size.height -
                                  MediaQuery.of(context).padding.top -
                                  MediaQuery.of(context).padding.bottom) *
                              0.15,
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

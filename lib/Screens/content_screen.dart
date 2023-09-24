import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../Widgets/diamond_button.dart';
import '../Widgets/uicorn_button.dart';

class ContentScreen extends StatelessWidget {
  static const routeName = '/content';
  const ContentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<UnicornButton> childButtons = [];
    // Color(0xFF634999),
    // Color(0xFF635985),

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

    childButtons.add(
      UnicornButton(
        currentButton: FloatingActionButton(
            heroTag: "airplane",
            backgroundColor: Color(0xFF634999), // Colors.greenAccent,
            mini: true,
            onPressed: () {
              print("location");
            },
            child: Icon(Icons.place)),
      ),
    );

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
      floatingActionButton: UnicornDialer(
        backgroundColor: Colors.transparent,
        parentButton: Icon(Icons.add),
        childButtons: childButtons,
        onMainButtonPressed: () {},
        finalButtonIcon: Icon(Icons.close),
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
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        Center(
                          child: Text(
                            AppLocalizations.of(context).translate("To-Do"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

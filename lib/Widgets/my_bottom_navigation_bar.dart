import 'package:flutter/material.dart';

import '../Utils/l10n/app_localizations.dart';
import '../Widgets/diamond_button.dart';
import '../Widgets/date_picker.dart';

class DiamondBottomNavigation extends StatelessWidget {
  final List<IconData> itemIcons;
  final int selectedIndex;
  final Function(int) onItemPressed;
  final double? height;
  final Color selectedColor;
  final Color selectedLightColor;
  final Color unselectedColor;
  final Color bgColor;
  final Function addItem;
  bool hasDeadline = true;

  DiamondBottomNavigation({
    Key? key,
    required this.itemIcons,
    required this.selectedIndex,
    required this.onItemPressed,
    required this.addItem,
    this.height,
    this.selectedColor = const Color(0xFF635985),
    this.unselectedColor = Colors.grey,
    this.selectedLightColor = const Color(0xFF634999),
    this.bgColor = Colors.white,
  })  : assert(itemIcons.length == 4, "Item must equal 4"),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.initSize(context);
    final height = this.height ?? getRelativeHeight(0.076);

    return Container(
      // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: bgColor,
      child: SizedBox(
        height: height + getRelativeHeight(0.01),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height,
                color: bgColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: getRelativeWidth(0.1)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                splashColor: selectedColor.withOpacity(0.5),
                                onTap: () {
                                  onItemPressed(0);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    itemIcons[0],
                                    color: selectedIndex == 0
                                        ? selectedColor
                                        : unselectedColor,
                                    size: getRelativeWidth(0.07),
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                splashColor: selectedColor.withOpacity(0.5),
                                onTap: () {
                                  onItemPressed(1);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    itemIcons[1],
                                    color: selectedIndex == 1
                                        ? selectedColor
                                        : unselectedColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                splashColor: selectedColor.withOpacity(0.5),
                                onTap: () {
                                  onItemPressed(2);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    itemIcons[2],
                                    color: selectedIndex == 2
                                        ? selectedColor
                                        : unselectedColor,
                                    size: getRelativeWidth(0.07),
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                splashColor: selectedColor.withOpacity(0.5),
                                onTap: () {
                                  onItemPressed(3);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Icon(
                                    itemIcons[3],
                                    color: selectedIndex == 3
                                        ? selectedColor
                                        : unselectedColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DiamondButton(
                icon: Icon(
                  Icons.add,
                  color: bgColor,
                  size: getRelativeWidth(0.1),
                ),
                onTap: () async {
                  TextEditingController newTitle = TextEditingController();
                  DateTime newDeadline =
                      DateTime.now().add(const Duration(days: 7));
                  showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      hasDeadline = true;

                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        title: Text(
                          AppLocalizations.of(context)
                              .translate("Enter list title"),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        content: StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  autofocus: true,
                                  controller: newTitle,
                                  maxLength: 25,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)
                                        .translate("Title"),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).dividerColor),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Theme.of(context).dividerColor),
                                    ),
                                  ),
                                ),
                                FittedBox(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Checkbox(
                                        value: hasDeadline,
                                        onChanged: (val) {
                                          setState(() {
                                            hasDeadline = val ??
                                                false; // Ensure a default value
                                          });
                                        },
                                        // activeColor: Color(0xFF945985),
                                      ),
                                      hasDeadline
                                          ? DatePickerWidget(
                                              initialDate: newDeadline,
                                              firstDate: DateTime.now()
                                                  .add(const Duration(days: 1)),
                                              lastDate: DateTime.now().add(
                                                  const Duration(days: 3650)),
                                              onDateSelected: (selectedDate) {
                                                if (selectedDate != null) {
                                                  newDeadline = selectedDate;
                                                }
                                              },
                                            )
                                          : FittedBox(
                                              child: Text(
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        "Check for adding deadline"),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        actions: <Widget>[
                          SizedBox(
                            child: Row(
                              children: [
                                TextButton(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Cancel"),
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Save"),
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  onPressed: () {
                                    if (newTitle.text.trim().isNotEmpty) {
                                      addItem(newTitle.text.trim(), newDeadline,
                                          hasDeadline);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                screenWidth: getRelativeWidth(1),
                screenHeight: getRelativeHeight(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SizeConfig {
  static double screenWidth = 0;
  static double screenHeight = 0;

  static initSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
  }
}

double getRelativeHeight(double percentage) {
  return percentage * SizeConfig.screenHeight;
}

double getRelativeWidth(double percentage) {
  return percentage * SizeConfig.screenWidth;
}

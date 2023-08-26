// import 'package:async/async.dart';
// import 'package:flutter/material.dart';
//
// import '../Widgets/date_picker.dart';
// import '../Providers/lists_provider.dart';
//
// class MyBottomNavigationBar extends StatefulWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//   final Function add_item;
//
//   MyBottomNavigationBar(
//       {required this.currentIndex,
//       required this.onTap,
//       required this.add_item});
//
//   @override
//   State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
// }
//
// class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
//   bool hasDeadline = true;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Color(0xFF393053),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildBottomNavigationItem(Icons.fact_check, "Active", 0),
//               const SizedBox(
//                 width: 0,
//               ),
//               _buildBottomNavigationItem(Icons.archive, "Archived", 1),
//             ],
//           ),
//           Positioned(
//             bottom: 0,
//             child: ElevatedButton(
//               onPressed: () async {
//                 TextEditingController new_title = TextEditingController();
//                 DateTime new_deadline = DateTime.now().add(Duration(days: 7));
//                 showDialog<void>(
//                   context: context,
//                   barrierDismissible: true,
//                   builder: (BuildContext context) {
//                     hasDeadline = true;
//
//                     return AlertDialog(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                       ),
//                       title: const Text(
//                         'Enter list title',
//                         style: TextStyle(color: Color(0xFF635985)),
//                       ),
//                       content: StatefulBuilder(
//                         builder: (BuildContext context, StateSetter setState) {
//                           return Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               TextFormField(
//                                 autofocus: true,
//                                 controller: new_title,
//                                 maxLength: 25,
//                                 decoration: InputDecoration(hintText: "Title"),
//                               ),
//                               FittedBox(
//                                 child: Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Checkbox(
//                                       value: hasDeadline,
//                                       onChanged: (val) {
//                                         setState(() {
//                                           hasDeadline = val ??
//                                               false; // Ensure a default value
//                                         });
//                                       },
//                                       activeColor: Color(0xFF945985),
//                                     ),
//                                     hasDeadline
//                                         ? DatePickerWidget(
//                                             initialDate: new_deadline ??
//                                                 DateTime.now()
//                                                     .add(Duration(days: 7)),
//                                             firstDate: DateTime.now(),
//                                             lastDate: DateTime.now()
//                                                 .add(Duration(days: 3650)),
//                                             onDateSelected: (selectedDate) {
//                                               if (selectedDate != null)
//                                                 new_deadline = selectedDate;
//                                             },
//                                           )
//                                         : Text('Check for adding deadline'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                       actions: <Widget>[
//                         TextButton(
//                           child: const Text(
//                             'Cancel',
//                             style: TextStyle(
//                               color: Colors.grey,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           onPressed: () {
//                             Navigator.of(context).pop();
//                           },
//                         ),
//                         TextButton(
//                           child: const Text(
//                             'Save',
//                             style: TextStyle(
//                               color: Color(0xFF635985),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           onPressed: () {
//                             if (new_title.text != '') {
//                               widget.add_item(
//                                   new_title.text, new_deadline, hasDeadline);
//                             }
//                             Navigator.of(context).pop();
//                           },
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//               child: Icon(Icons.add, size: 30),
//               style: ElevatedButton.styleFrom(
//                 shape: CircleBorder(),
//                 backgroundColor: Color(0xFF635985),
//                 padding: EdgeInsets.all(15),
//                 elevation: 10,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBottomNavigationItem(
//       IconData iconData, String label, int index) {
//     return GestureDetector(
//       onTap: () => widget.onTap(index),
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//         decoration: BoxDecoration(
//           color: Colors.transparent,
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               iconData,
//               size: widget.currentIndex == index ? 30 : 20,
//               color: widget.currentIndex == index ? Colors.white : Colors.grey,
//             ),
//             if (widget.currentIndex == index) SizedBox(height: 5),
//             if (widget.currentIndex == index)
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:async/async.dart';
import 'package:flutter/material.dart';

// import 'package:diamond_bottom_bar/diamond_bottom_bar.dart';
import 'dart:math' as math;

import '../Widgets/date_picker.dart';
import '../Providers/lists_provider.dart';

class DiamondBottomNavigation extends StatelessWidget {
  final List<IconData> itemIcons;
  final IconData centerIcon;
  final int selectedIndex;
  final Function(int) onItemPressed;
  final double? height;
  final Color selectedColor;
  final Color selectedLightColor;
  final Color unselectedColor;
  final Function add_item;
  bool hasDeadline = true;

  DiamondBottomNavigation({
    Key? key,
    required this.itemIcons,
    required this.centerIcon,
    required this.selectedIndex,
    required this.onItemPressed,
    required this.add_item,
    this.height,
    this.selectedColor = const Color(0xFF635985),
    this.unselectedColor = Colors.grey,
    this.selectedLightColor = const Color(0xFF634999),
  })  : assert(itemIcons.length == 4 || itemIcons.length == 2,
            "Item must equal 4 or 2"),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.initSize(context);
    final height = this.height ?? getRelativeHeight(0.076);

    return Container(
      // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: Colors.white,
      child: SizedBox(
        height: height + getRelativeHeight(0.01),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height,
                color: Colors.white,
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
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      // onTap: () {
                      //   onItemPressed(itemIcons.length == 4 ? 2 : 1);
                      // },
                      child: GestureDetector(
                        onTap: () async {
                          TextEditingController new_title =
                              TextEditingController();
                          DateTime new_deadline =
                              DateTime.now().add(Duration(days: 7));
                          showDialog<void>(
                            context: context,
                            barrierDismissible: true,
                            builder: (BuildContext context) {
                              hasDeadline = true;

                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                title: const Text(
                                  'Enter list title',
                                  style: TextStyle(color: Color(0xFF635985)),
                                ),
                                content: StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          autofocus: true,
                                          controller: new_title,
                                          maxLength: 25,
                                          decoration: InputDecoration(
                                              hintText: "Title"),
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
                                                activeColor: Color(0xFF945985),
                                              ),
                                              hasDeadline
                                                  ? DatePickerWidget(
                                                      initialDate:
                                                          new_deadline ??
                                                              DateTime.now()
                                                                  .add(Duration(
                                                                      days: 7)),
                                                      firstDate: DateTime.now(),
                                                      lastDate: DateTime.now()
                                                          .add(Duration(
                                                              days: 3650)),
                                                      onDateSelected:
                                                          (selectedDate) {
                                                        if (selectedDate !=
                                                            null)
                                                          new_deadline =
                                                              selectedDate;
                                                      },
                                                    )
                                                  : Text(
                                                      'Check for adding deadline'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Color(0xFF635985),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (new_title.text != '') {
                                        add_item(new_title.text, new_deadline,
                                            hasDeadline);
                                      }
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 25,
                                offset: const Offset(0, 5),
                                color: selectedColor.withOpacity(0.75),
                              )
                            ],
                            borderRadius:
                                const BorderRadius.all(Radius.circular(18)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                selectedLightColor,
                                selectedColor,
                              ],
                            ),
                          ),
                          height: getRelativeWidth(0.135),
                          width: getRelativeWidth(0.135),
                          child: Center(
                              child: Transform.rotate(
                            angle: math.pi / 4,
                            child: Icon(
                              centerIcon,
                              color: Colors.white,
                              size: getRelativeWidth(0.1),
                            ),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
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

// class MyBottomNavigationBar extends StatefulWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//   final Function add_item;
//
//   MyBottomNavigationBar(
//       {required this.currentIndex,
//       required this.onTap,
//       required this.add_item});
//
//   @override
//   State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
// }
//
// class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
//   @override
//   Widget build(BuildContext context) {
//     return DiamondBottomNavigation(
//       itemIcons: const [
//         Icons.checklist,
//         Icons.archive,
//         Icons.notifications_off_rounded,
//         Icons.settings,
//       ],
//       add_item: widget.add_item,
//       centerIcon: Icons.add_outlined,
//       selectedIndex: widget.currentIndex,
//       onItemPressed: widget.onTap,
//     );
//   }
// }

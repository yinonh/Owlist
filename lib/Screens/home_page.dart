import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:to_do/main.dart';

import '../l10n/app_localizations.dart';
import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Widgets/settigns_widget.dart';
import '../Widgets/my_bottom_navigation_bar.dart';
import '../Widgets/items_screen.dart';

enum FilterBy {
  creationLTN,
  creationNTL,
  deadlineLTN,
  deadlineNTL,
  progressBTS,
  progressSTB
}

class HomePage extends StatefulWidget {
  static const routeName = '/home_page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ListsProvider provider;
  late Future<List<ToDoList>> activeItemsFuture;
  late Future<List<ToDoList>> achievedItemsFuture;
  late Future<List<ToDoList>> withoutDeadlineItemsFuture;
  FilterBy selectedOption = FilterBy.creationNTL;
  late int currentIndex;
  late PageController selectedIndex;
  late List<String> titles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    titles = [
      AppLocalizations.of(context).translate("Active Items"),
      AppLocalizations.of(context).translate("Archived Items"),
      AppLocalizations.of(context).translate("Without Deadline"),
      AppLocalizations.of(context).translate("Settings")
    ];
  }

  Future<void> setUpNotifications() async {
    // final fcm = FirebaseMessaging.instance;
    // AwesomeNotifications().isNotificationAllowed().then(
    //   (isAllowed) {
    //     if (!isAllowed) {
    //       showDialog(
    //         context: context,
    //         builder: (context) => AlertDialog(
    //           title: Text(
    //             AppLocalizations.of(context).translate("Allow Notifications"),
    //           ),
    //           content: Text(
    //             AppLocalizations.of(context)
    //                 .translate("Our app would like to send you notifications"),
    //           ),
    //           actions: [
    //             TextButton(
    //               onPressed: () {
    //                 Navigator.pop(context);
    //               },
    //               child: Text(
    //                 AppLocalizations.of(context).translate("Dont Allow"),
    //                 style: TextStyle(color: Colors.grey, fontSize: 18),
    //               ),
    //             ),
    //             TextButton(
    //               onPressed: () => AwesomeNotifications()
    //                   .requestPermissionToSendNotifications()
    //                   .then((_) => Navigator.pop(context)),
    //               child: Text(
    //                 AppLocalizations.of(context).translate("Allow"),
    //                 style: TextStyle(
    //                   color: Color(0xFF636995),
    //                   fontSize: 18,
    //                   fontWeight: FontWeight.bold,
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       );
    //     }
    //   },
    // );
    // final _token = await fcm.getToken();
    // print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" + _token.toString());
  }

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    selectedIndex = PageController(initialPage: 0);
    setUpNotifications();

    activeItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getActiveItems();
    achievedItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getAchievedItems();
    withoutDeadlineItemsFuture =
        Provider.of<ListsProvider>(context, listen: false)
            .getWithoutDeadlineItems();
  }

  Future<void> sortLists(FilterBy filterBy) async {
    List<ToDoList> activeLists = await activeItemsFuture;
    List<ToDoList> achievedLists = await achievedItemsFuture;
    List<ToDoList> withoutDeadlineLists = await withoutDeadlineItemsFuture;

    void sortFunction(List<ToDoList> lists) {
      lists.sort((a, b) {
        if (filterBy == FilterBy.creationLTN) {
          return a.creationDate.compareTo(b.creationDate);
        } else if (filterBy == FilterBy.creationNTL) {
          return b.creationDate.compareTo(a.creationDate);
        } else if (filterBy == FilterBy.deadlineLTN) {
          if (!a.hasDeadline && b.hasDeadline) {
            return 1;
          } else if (a.hasDeadline && !b.hasDeadline) {
            return -1;
          }
          return b.deadline.compareTo(a.deadline);
        } else if (filterBy == FilterBy.deadlineNTL) {
          if (!a.hasDeadline && b.hasDeadline) {
            return 1;
          } else if (a.hasDeadline && !b.hasDeadline) {
            return -1;
          }
          return a.deadline.compareTo(b.deadline);
        } else if (filterBy == FilterBy.progressBTS) {
          double progressA =
              a.totalItems == 0 ? 0 : a.accomplishedItems / a.totalItems;
          double progressB =
              b.totalItems == 0 ? 0 : b.accomplishedItems / b.totalItems;
          return progressB
              .compareTo(progressA); // Sorting by progress in descending order
        } else if (filterBy == FilterBy.progressSTB) {
          double progressA =
              a.totalItems == 0 ? 0 : a.accomplishedItems / a.totalItems;
          double progressB =
              b.totalItems == 0 ? 0 : b.accomplishedItems / b.totalItems;
          return progressA
              .compareTo(progressB); // Sorting by progress in ascending order
        }
        return 0; // Default case
      });
    }

    sortFunction(activeLists);
    sortFunction(achievedLists);
    sortFunction(withoutDeadlineLists);

    setState(() {
      activeItemsFuture = Future.value(activeLists);
      achievedItemsFuture = Future.value(achievedLists);
      withoutDeadlineItemsFuture = Future.value(withoutDeadlineLists);
    });
  }

  void deleteItem(ToDoList item) {
    setState(() {
      activeItemsFuture = activeItemsFuture.then((activeItems) {
        return provider.deleteList(item.id).then((_) {
          return provider.getActiveItems();
        });
      });
      achievedItemsFuture = achievedItemsFuture.then((achievedItems) {
        return provider.deleteList(item.id).then((_) {
          return provider.getAchievedItems();
        });
      });
      withoutDeadlineItemsFuture =
          withoutDeadlineItemsFuture.then((withoutDeadlineItems) {
        return provider.deleteList(item.id).then((_) {
          return provider.getWithoutDeadlineItems();
        });
      });
    });
  }

  void addItem(String title, DateTime deadline, bool hasDeadline) {
    setState(() {
      if (hasDeadline) {
        onItemTapped(0);
        activeItemsFuture = activeItemsFuture.then((activeItems) {
          return provider.createNewList(title, deadline, hasDeadline).then((_) {
            return provider.getActiveItems();
          });
        });
      } else {
        onItemTapped(2);
        withoutDeadlineItemsFuture =
            withoutDeadlineItemsFuture.then((withoutDeadlineItems) {
          return provider.createNewList(title, deadline, hasDeadline).then((_) {
            return provider.getWithoutDeadlineItems();
          });
        });
      }
      sortLists(FilterBy.creationNTL);
    });
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex.animateToPage(
        index,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeInOut,
      );
      currentIndex = index;
    });
  }

  Future<void> refreshLists() async {
    setState(() {
      provider.invalidateCache();
      activeItemsFuture = provider.getActiveItems();
      achievedItemsFuture = provider.getAchievedItems();
      withoutDeadlineItemsFuture = provider.getWithoutDeadlineItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<ListsProvider>(context);
    return Scaffold(
      bottomNavigationBar: DiamondBottomNavigation(
        itemIcons: const [
          Icons.checklist,
          Icons.archive,
          Icons.notifications_off_rounded,
          Icons.settings,
        ],
        add_item: addItem,
        selectedIndex: currentIndex,
        onItemPressed: onItemTapped,
        bgColor: Theme.of(context).primaryColor,
        selectedColor: Theme.of(context).focusColor,
        unselectedColor: Theme.of(context).unselectedWidgetColor,
      ),
      body: RefreshIndicator(
        onRefresh: refreshLists,
        child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      currentIndex == 3
                          ? SizedBox(
                              width: 10,
                            )
                          : PopupMenuButton<FilterBy>(
                              icon: const Icon(Icons.filter_list),
                              onSelected: (value) {
                                setState(() {
                                  sortLists(value);
                                });
                              },
                              itemBuilder: (BuildContext cnx) => [
                                PopupMenuItem<FilterBy>(
                                  value: FilterBy.creationNTL,
                                  child: Text(
                                    AppLocalizations.of(context).translate(
                                        "Creation Date: Newest to Oldest"),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                PopupMenuItem<FilterBy>(
                                  value: FilterBy.creationLTN,
                                  child: Text(
                                    AppLocalizations.of(context).translate(
                                        "Creation Date: Oldest to Newest"),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                PopupMenuItem<FilterBy>(
                                  value: FilterBy.deadlineLTN,
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Deadline: Later to Sooner"),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                PopupMenuItem<FilterBy>(
                                  value: FilterBy.deadlineNTL,
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Deadline: Sooner to Later"),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                PopupMenuItem<FilterBy>(
                                  value: FilterBy.progressBTS,
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Progress: High to Low"),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                PopupMenuItem<FilterBy>(
                                  value: FilterBy.progressSTB,
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate("Progress: Low to High"),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    titles[currentIndex],
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: PageView(
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    controller: selectedIndex,
                    children: [
                      FutureBuilder<List<ToDoList>>(
                        key: PageStorageKey(1),
                        future: activeItemsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Text(
                              AppLocalizations.of(context)
                                  .translate("Error has occurred"),
                              style: TextStyle(color: Colors.white),
                            );
                          } else {
                            return ItemsScreen(
                              selectedIndex: 0,
                              existingItems: snapshot.data!,
                              deleteItem: deleteItem,
                              refresh: refreshLists,
                            );
                          }
                        },
                      ),
                      FutureBuilder<List<ToDoList>>(
                        key: PageStorageKey(2),
                        future: achievedItemsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: Duration(seconds: 2),
                                content: Text(
                                  AppLocalizations.of(context)
                                      .translate("Error has occurred"),
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                            return Text(
                              AppLocalizations.of(context)
                                  .translate("Error has occurred"),
                              style: TextStyle(color: Colors.white),
                            );
                          } else {
                            return ItemsScreen(
                              selectedIndex: 1,
                              existingItems: snapshot.data!,
                              deleteItem: deleteItem,
                              refresh: refreshLists,
                            );
                          }
                        },
                      ),
                      FutureBuilder<List<ToDoList>>(
                        key: PageStorageKey(3),
                        future: withoutDeadlineItemsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: Duration(seconds: 2),
                                content: Text(
                                  AppLocalizations.of(context)
                                      .translate("Error has occurred"),
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                            return Text(
                              AppLocalizations.of(context)
                                  .translate("Error has occurred"),
                              style: TextStyle(color: Colors.white),
                            );
                          } else {
                            return ItemsScreen(
                              selectedIndex: 1,
                              existingItems: snapshot.data!,
                              deleteItem: deleteItem,
                              refresh: refreshLists,
                            );
                          }
                        },
                      ),
                      Settings(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

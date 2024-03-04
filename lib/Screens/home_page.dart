import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Widgets/settigns_widget.dart';
import '../Widgets/diamond_bottom_navigation_bar.dart';
import '../Widgets/items_screen.dart';
import '../Utils/strings.dart';
import '../Utils/shared_preferences_helper.dart';

enum SortBy {
  creationNTL,
  creationLTN,
  deadlineLTN,
  deadlineNTL,
  progressBTS,
  progressSTB
}

class HomePage extends StatefulWidget {
  static const routeName = '/home_page';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ListsProvider provider;
  late Future<List<ToDoList>> activeItemsFuture;
  late Future<List<ToDoList>> achievedItemsFuture;
  late Future<List<ToDoList>> withoutDeadlineItemsFuture;
  SortBy selectedOption = SortBy.creationNTL;
  late int currentIndex;
  late PageController selectedIndex;
  late List<String> titles;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    titles = [
      context.translate(Strings.activeLists),
      context.translate(Strings.archivedLists),
      context.translate(Strings.withoutDeadline),
      context.translate(Strings.settings),
    ];
  }

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    selectedIndex = PageController(initialPage: 0);
    Provider.of<ListsProvider>(context, listen: false).initialization(context);
    activeItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getActiveItems();
    achievedItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getAchievedItems();
    withoutDeadlineItemsFuture =
        Provider.of<ListsProvider>(context, listen: false)
            .getWithoutDeadlineItems();
    _loadCheckedStatus();
    sortLists();
  }

  void _loadCheckedStatus() async {
    int index = await SharedPreferencesHelper.instance.sortByIndex();
    setState(() {
      selectedOption = SortBy.values[index];
    });
  }

  Future<void> sortLists() async {
    List<ToDoList> activeLists = await activeItemsFuture;
    List<ToDoList> achievedLists = await achievedItemsFuture;
    List<ToDoList> withoutDeadlineLists = await withoutDeadlineItemsFuture;

    void sortFunction(List<ToDoList> lists) {
      lists.sort((a, b) {
        switch (selectedOption) {
          case SortBy.creationLTN:
            return a.creationDate.isBefore(b.creationDate) ? -1 : 1;
          case SortBy.creationNTL:
            return b.creationDate.isBefore(a.creationDate) ? -1 : 1;
          case SortBy.deadlineLTN:
            if (!a.hasDeadline && b.hasDeadline) {
              return 1;
            } else if (a.hasDeadline && !b.hasDeadline) {
              return -1;
            }
            return b.deadline.isBefore(a.deadline) ? -1 : 1;
          case SortBy.deadlineNTL:
            if (!a.hasDeadline && b.hasDeadline) {
              return 1;
            } else if (a.hasDeadline && !b.hasDeadline) {
              return -1;
            }
            return a.deadline.isBefore(b.deadline) ? -1 : 1;
          case SortBy.progressBTS:
            return (b.totalItems == 0 ? 0 : b.accomplishedItems / b.totalItems)
                .compareTo(
                    a.totalItems == 0 ? 0 : a.accomplishedItems / a.totalItems);
          case SortBy.progressSTB:
            return (a.totalItems == 0 ? 0 : a.accomplishedItems / a.totalItems)
                .compareTo(
                    b.totalItems == 0 ? 0 : b.accomplishedItems / b.totalItems);
          default:
            return 0; // Default case
        }
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

  void showMessage(String text, IconData icon) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: text,
        backgroundColor: Theme.of(context).highlightColor,
        icon: Icon(
          icon,
          color: const Color(0x15000000),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      displayDuration: Duration(seconds: 1),
    );
  }

  Future<void> deleteList(ToDoList item) async {
    setState(() {
      activeItemsFuture = activeItemsFuture.then((activeItems) {
        return provider.deleteList(item).then((_) {
          return provider.getActiveItems();
        });
      });
      achievedItemsFuture = achievedItemsFuture.then((achievedItems) {
        return provider.deleteList(item).then((_) {
          return provider.getAchievedItems();
        });
      });
      withoutDeadlineItemsFuture =
          withoutDeadlineItemsFuture.then((withoutDeadlineItems) {
        return provider.deleteList(item).then((_) {
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
          return provider
              .createNewList(title, deadline, hasDeadline)
              .then((result) {
            if (result) {
              showMessage(context.translate(Strings.scheduleNotification),
                  Icons.notification_add);
            }
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
      //sortLists(SortBy.creationNTL);
    });
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
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
      backgroundColor: Theme.of(context).primaryColor,
      bottomNavigationBar: DiamondBottomNavigation(
        itemIcons: const [
          Icons.checklist,
          Icons.archive,
          Icons.notifications_off_rounded,
          Icons.settings,
        ],
        addItem: addItem,
        selectedIndex: currentIndex,
        onItemPressed: onItemTapped,
        bgColor: Theme.of(context).primaryColor,
        selectedColor: Theme.of(context).focusColor,
        unselectedColor: Theme.of(context).unselectedWidgetColor,
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'Assets/appName.svg',
                        fit: BoxFit.contain,
                        width: 170,
                      ),
                    ),
                    currentIndex == 3
                        ? const Text(
                            " ",
                            style: TextStyle(fontSize: 33),
                          )
                        : PopupMenuButton<SortBy>(
                            icon: const Icon(Icons.filter_list),
                            onSelected: (value) async {
                              setState(() {
                                selectedOption = value;
                                sortLists();
                              });
                              await SharedPreferencesHelper.instance
                                  .setSortByIndex(SortBy.values.indexOf(value));
                            },
                            itemBuilder: (BuildContext cnx) => [
                              CheckedPopupMenuItem<SortBy>(
                                value: SortBy.creationNTL,
                                checked: selectedOption == SortBy.creationNTL,
                                child: Text(
                                  context.translate(
                                      Strings.creationDateNewestToOldest),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              CheckedPopupMenuItem<SortBy>(
                                value: SortBy.creationLTN,
                                checked: selectedOption == SortBy.creationLTN,
                                child: Text(
                                  context.translate(
                                      Strings.creationDateOldestToNewest),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              CheckedPopupMenuItem<SortBy>(
                                value: SortBy.deadlineLTN,
                                checked: selectedOption == SortBy.deadlineLTN,
                                child: Text(
                                  context
                                      .translate(Strings.deadlineLaterToSooner),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              CheckedPopupMenuItem<SortBy>(
                                value: SortBy.deadlineNTL,
                                checked: selectedOption == SortBy.deadlineNTL,
                                child: Text(
                                  context
                                      .translate(Strings.deadlineSoonerToLater),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              CheckedPopupMenuItem<SortBy>(
                                value: SortBy.progressBTS,
                                checked: selectedOption == SortBy.progressBTS,
                                child: Text(
                                  context.translate(Strings.progressHighToLow),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              CheckedPopupMenuItem<SortBy>(
                                value: SortBy.progressSTB,
                                checked: selectedOption == SortBy.progressSTB,
                                child: Text(
                                  context.translate(Strings.progressLowToHigh),
                                  style: Theme.of(context).textTheme.bodyLarge,
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
                      key: const PageStorageKey(1),
                      future: activeItemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          print(snapshot.error);
                          return Text(
                            context.translate(Strings.errorHasOccurred),
                            style: const TextStyle(color: Colors.white),
                          );
                        } else {
                          return ItemsScreen(
                            selectedIndex: 0,
                            existingItems: snapshot.data!,
                            deleteItem: deleteList,
                            refresh: refreshLists,
                          );
                        }
                      },
                    ),
                    FutureBuilder<List<ToDoList>>(
                      key: const PageStorageKey(2),
                      future: achievedItemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            context.translate(Strings.errorHasOccurred),
                            style: const TextStyle(color: Colors.white),
                          );
                        } else {
                          return ItemsScreen(
                            selectedIndex: 1,
                            existingItems: snapshot.data!,
                            deleteItem: deleteList,
                            refresh: refreshLists,
                          );
                        }
                      },
                    ),
                    FutureBuilder<List<ToDoList>>(
                      key: const PageStorageKey(3),
                      future: withoutDeadlineItemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            context.translate(Strings.errorHasOccurred),
                            style: const TextStyle(color: Colors.white),
                          );
                        } else {
                          return ItemsScreen(
                            selectedIndex: 1,
                            existingItems: snapshot.data!,
                            deleteItem: deleteList,
                            refresh: refreshLists,
                          );
                        }
                      },
                    ),
                    const Settings(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Providers/notification_provider.dart';
import '../Screens/single_list_screen.dart';
import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/shared_preferences_helper.dart';
import '../Utils/show_case_helper.dart';
import '../Utils/strings.dart';
import '../Widgets/diamond_bottom_navigation_bar.dart';
import '../Widgets/items_screen.dart';
import '../Widgets/settigns_widget.dart';

enum SortBy {
  creationNTL,
  creationLTN,
  deadlineLTN,
  deadlineNTL,
  progressBTS,
  progressSTB
}

class HomePage extends StatefulWidget {
  static const routeName = Keys.homePageRouteName;

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ListsProvider provider;
  late Future<List<ToDoList>> activeItemsFuture;
  late Future<List<ToDoList>> achievedItemsFuture;
  late Future<List<ToDoList>> withoutDeadlineItemsFuture;
  late Future<List<ToDoList>> searchResults;
  late int currentIndex;
  late PageController selectedIndex;
  late List<String> titles;
  bool searchMode = false;
  final GlobalKey<ScaffoldState> addListKey = GlobalKey<ScaffoldState>();

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
    Provider.of<NotificationProvider>(context, listen: false)
        .setUpNotifications();
    activeItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getActiveItems();
    achievedItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getAchievedItems();
    withoutDeadlineItemsFuture =
        Provider.of<ListsProvider>(context, listen: false)
            .getWithoutDeadlineItems();
    searchResults = Provider.of<ListsProvider>(context, listen: false)
        .searchListsByTitle("");
  }

  void showMessage(String text, IconData icon) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: text,
        backgroundColor: Theme.of(context).highlightColor,
        icon: Icon(
          icon,
          color: Theme.of(context).primaryColorDark.withOpacity(0.2),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 80,
      ),
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
      searchMode = false;
    });
  }

  Future<void> addItem(
      String title, DateTime deadline, bool hasDeadline) async {
    setState(() {
      if (hasDeadline) {
        onItemTapped(0);
        activeItemsFuture.then((activeItems) {
          return provider
              .createNewList(title, deadline, hasDeadline)
              .then((result) {
            if (result.success) {
              showMessage(context.translate(Strings.scheduleNotification),
                  Icons.notification_add_rounded);
            }
            if (result.data != null) {
              Navigator.pushNamed(context, SingleListScreen.routeName,
                      arguments: result.data)
                  .then((value) => refreshLists());
            }
            return provider.getActiveItems();
          });
        });
      } else {
        onItemTapped(2);
        withoutDeadlineItemsFuture.then((withoutDeadlineItems) {
          return provider
              .createNewList(title, deadline, hasDeadline)
              .then((result) {
            if (result.data != null) {
              Navigator.pushNamed(context, SingleListScreen.routeName,
                      arguments: result.data)
                  .then((value) => refreshLists());
            }
            return provider.getWithoutDeadlineItems();
          });
        });
      }
    });
  }

  void onItemTapped(int index) {
    setState(() {
      searchMode = false;
      selectedIndex.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      currentIndex = index;
    });
  }

  Future<void> refreshLists(
      {String searchVal = "", bool restartSearchMode = false}) async {
    setState(() {
      provider.invalidateCache();
      activeItemsFuture = provider.getActiveItems();
      achievedItemsFuture = provider.getAchievedItems();
      withoutDeadlineItemsFuture = provider.getWithoutDeadlineItems();
      searchResults = provider.searchListsByTitle(searchVal);
      if (restartSearchMode) {
        searchMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<ListsProvider>(context);
    return ShowCaseWidget(
      builder: Builder(builder: (cnx) {
        return Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          bottomNavigationBar: searchMode
              ? null
              : ShowCaseHelper.instance.customShowCase(
                  key: addListKey,
                  description: context.translate(
                      ShowCaseHelper.instance.homePageShowCaseDescription),
                  context: context,
                  child: DiamondBottomNavigation(
                    itemIcons: const [
                      Icons.checklist_rounded,
                      Icons.archive_rounded,
                      Icons.watch_off_rounded,
                      Icons.settings_rounded,
                    ],
                    addItem: (String title, DateTime deadline,
                        bool hasDeadline) async {
                      await addItem(title, deadline, hasDeadline);
                      setState(() {
                        refreshLists();
                      });
                    },
                    selectedIndex: currentIndex,
                    onItemPressed: onItemTapped,
                    bgColor: Theme.of(context).primaryColor,
                    selectedColor: Theme.of(context).focusColor,
                    unselectedColor: Theme.of(context).unselectedWidgetColor,
                    height: 50,
                  ),
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
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: searchMode
                        ? TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText:
                                  context.translate(Strings.enterListTitle),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    searchMode = false;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            onChanged: (value) {
                              refreshLists(searchVal: value);
                            },
                          )
                        : Row(
                            textDirection: TextDirection.ltr,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Center(
                                child: SvgPicture.asset(
                                  Keys.appNameSvg,
                                  fit: BoxFit.contain,
                                  width: 170,
                                ),
                              ),
                              const Spacer(),
                              if (currentIndex != 3)
                                IconButton(
                                  onPressed: () async {
                                    await refreshLists();
                                    setState(() {
                                      searchMode = true;
                                    });
                                  },
                                  icon: const Icon(Icons.search_rounded),
                                ),
                              currentIndex == 3
                                  ? Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: IconButton(
                                        icon: Icon(
                                          ShowCaseHelper.instance.isActive
                                              ? Icons
                                                  .pause_circle_outline_rounded
                                              : Icons.help_outline_rounded,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            ShowCaseHelper.instance
                                                .toggleIsActive();
                                          });
                                          ShowCaseHelper.instance
                                              .startShowCaseBeginning(
                                                  cnx, [addListKey]);
                                        },
                                      ),
                                    )
                                  : PopupMenuButton<SortBy>(
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10.0),
                                        ),
                                      ),
                                      icon:
                                          const Icon(Icons.filter_list_rounded),
                                      onSelected: (value) async {
                                        provider.selectedOptionVal = value;
                                        await SharedPreferencesHelper.instance
                                            .setSortByIndex(
                                                SortBy.values.indexOf(value));
                                        await refreshLists();
                                      },
                                      itemBuilder: (BuildContext cnx) => [
                                        CheckedPopupMenuItem<SortBy>(
                                          value: SortBy.creationNTL,
                                          checked: provider.selectedOptionVal ==
                                              SortBy.creationNTL,
                                          child: Text(
                                            context.translate(Strings
                                                .creationDateNewestToOldest),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        CheckedPopupMenuItem<SortBy>(
                                          value: SortBy.creationLTN,
                                          checked: provider.selectedOptionVal ==
                                              SortBy.creationLTN,
                                          child: Text(
                                            context.translate(Strings
                                                .creationDateOldestToNewest),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        CheckedPopupMenuItem<SortBy>(
                                          value: SortBy.deadlineLTN,
                                          checked: provider.selectedOptionVal ==
                                              SortBy.deadlineLTN,
                                          child: Text(
                                            context.translate(
                                                Strings.deadlineLaterToSooner),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        CheckedPopupMenuItem<SortBy>(
                                          value: SortBy.deadlineNTL,
                                          checked: provider.selectedOptionVal ==
                                              SortBy.deadlineNTL,
                                          child: Text(
                                            context.translate(
                                                Strings.deadlineSoonerToLater),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        CheckedPopupMenuItem<SortBy>(
                                          value: SortBy.progressBTS,
                                          checked: provider.selectedOptionVal ==
                                              SortBy.progressBTS,
                                          child: Text(
                                            context.translate(
                                                Strings.progressHighToLow),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                        CheckedPopupMenuItem<SortBy>(
                                          value: SortBy.progressSTB,
                                          checked: provider.selectedOptionVal ==
                                              SortBy.progressSTB,
                                          child: Text(
                                            context.translate(
                                                Strings.progressLowToHigh),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16.0),
                  searchMode
                      ? Expanded(
                          child: FutureBuilder<List<ToDoList>>(
                            key: const PageStorageKey(1),
                            future: searchResults,
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
                                  existingItems: snapshot.data!,
                                  deleteItem: deleteList,
                                  refresh: refreshLists,
                                  title:
                                      context.translate(Strings.searchResults),
                                );
                              }
                            },
                          ),
                        )
                      : Expanded(
                          child: PageView(
                            onPageChanged: (index) {
                              setState(() {
                                currentIndex = index;
                                searchMode = false;
                                refreshLists();
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
                                      context
                                          .translate(Strings.errorHasOccurred),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    );
                                  } else {
                                    return ItemsScreen(
                                      existingItems: snapshot.data!,
                                      deleteItem: deleteList,
                                      refresh: refreshLists,
                                      title: titles[currentIndex],
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
                                      context
                                          .translate(Strings.errorHasOccurred),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    );
                                  } else {
                                    return ItemsScreen(
                                      existingItems: snapshot.data!,
                                      deleteItem: deleteList,
                                      refresh: refreshLists,
                                      title: titles[currentIndex],
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
                                      context
                                          .translate(Strings.errorHasOccurred),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    );
                                  } else {
                                    return ItemsScreen(
                                      existingItems: snapshot.data!,
                                      deleteItem: deleteList,
                                      refresh: refreshLists,
                                      title: titles[currentIndex],
                                    );
                                  }
                                },
                              ),
                              Settings(refresh: refreshLists),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

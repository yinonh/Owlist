import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Controllers/home_page_controller.dart'; // Changed
import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
// import '../Providers/notification_provider.dart'; // No longer directly needed for init
import '../Screens/single_list_screen.dart';
import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
// import '../Utils/shared_preferences_helper.dart'; // Handled by controller
import '../Utils/show_case_helper.dart';
import '../Utils/strings.dart';
import '../Widgets/diamond_bottom_navigation_bar.dart';
import '../Widgets/items_screen.dart';
import '../Widgets/settigns_widget.dart';

// SortBy enum is also in home_page_controller.dart, ensure they are compatible or use one from controller
// For now, assuming it's fine or will be harmonized.
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
  late HomePageController _controller; // Changed
  late PageController _pageController; // Renamed from selectedIndex for clarity
  late List<String> _titles; // Renamed from titles
  final GlobalKey<ScaffoldState> _addListKey = GlobalKey<ScaffoldState>(); // Renamed

  @override
  void initState() {
    super.initState();
    final listsProvider = Provider.of<ListsProvider>(context, listen: false);
    _controller = HomePageController(listsProvider: listsProvider, context: context);
    _pageController = PageController(initialPage: _controller.currentPageIndex);

    // Listener to sync PageController with HomePageController's currentPageIndex
    _controller.addListener(_handleControllerChanges);

    // Initialization of providers like NotificationProvider if needed directly by HomePage
    // is now expected to be handled within HomePageController's initialization if it's a prerequisite for its operation.
    // Provider.of<NotificationProvider>(context, listen: false).setUpNotifications(); // Moved to controller or not needed here
  }

  void _handleControllerChanges() {
    // If page index changed in controller, update PageView
    // Ensure PageController is attached to a PageView before accessing .page
    if (_pageController.hasClients && _pageController.page?.round() != _controller.currentPageIndex) {
      _pageController.animateToPage(
        _controller.currentPageIndex,
        duration: const Duration(milliseconds: 300), // Shorter duration for programmatic changes
        curve: Curves.easeInOut,
      );
    }
    // HomePage might need to rebuild if other relevant states in controller change (e.g. isLoading)
    // This is implicitly handled if HomePage's build method consumes controller's properties.
    // A selective setState can be called if only specific parts of HomePage (not covered by PageView) need updates.
    if (mounted) { // Ensure the widget is still in the tree
      setState(() {});
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize titles here as it uses context.translate
    _titles = [
      context.translate(Strings.activeLists),
      context.translate(Strings.archivedLists),
      context.translate(Strings.withoutDeadline),
      context.translate(Strings.settings),
    ];
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanges);
    _pageController.dispose();
    _controller.dispose(); // Dispose the controller
    super.dispose();
  }

  void _showMessage(String text, IconData icon) { // Renamed
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: text,
        backgroundColor: Theme.of(context).highlightColor,
        icon: Icon(
          icon,
          color: Theme.of(context).primaryColorDark.withValues(alpha: 0.2),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.top,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 80,
      ),
      displayDuration: const Duration(seconds: 1),
    );
  }

  Future<void> _deleteList(ToDoList item) async { // Renamed
    await _controller.deleteList(item);
    // UI update will be handled by controller's notifyListeners
  }

  Future<void> _addItem(String title, DateTime deadline, bool hasDeadline) async { // Renamed
    if (hasDeadline) {
      _controller.onPageChanged(0); // Switch to active lists page
    } else {
      _controller.onPageChanged(2); // Switch to without deadline lists page
    }

    String? newListId = await _controller.createNewList(title, deadline, hasDeadline);

    if (newListId != null) {
      // Potentially show message for notification scheduling if createNewList indicates success for it
      // This logic might need refinement based on what createNewList in controller returns
      final list = await Provider.of<ListsProvider>(context, listen: false).getListById(newListId);
      if (list != null && list.hasDeadline && (await Provider.of<ListsProvider>(context, listen: false).notificationProvider.isAndroidPermissionGranted())) {
         _showMessage(context.translate(Strings.scheduleNotification), Icons.notification_add_rounded);
      }
      Navigator.pushNamed(context, SingleListScreen.routeName, arguments: newListId)
          .then((_) => _controller.refreshAllLists()); // Refresh lists when returning
    }
    // UI update will be handled by controller's notifyListeners
  }

  // No longer need refreshLists as a standalone public method in HomePageState.
  // Controller handles its internal refreshes.

  @override
  Widget build(BuildContext context) {
    // No longer need to get provider here if controller handles it all
    // provider = Provider.of<ListsProvider>(context);
    // Instead, we'll use the _controller

    return ShowCaseWidget(builder: (showcaseCnx) { // Renamed context variable
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        bottomNavigationBar: _controller.searchMode
            ? null
            : ShowCaseHelper.instance.customShowCase(
                key: _addListKey,
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
                  addItem: _addItem, // Use the new _addItem
                  selectedIndex: _controller.currentPageIndex, // From controller
                  onItemPressed: (index) { // Directly call controller's method
                    _pageController.animateToPage( // Also animate PageController
                         index,
                         duration: const Duration(milliseconds: 500),
                         curve: Curves.easeInOut,
                    );
                    _controller.onPageChanged(index);
                  },
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
                  child: _controller.searchMode
                      ? TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: context.translate(Strings.enterListTitle),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _controller.setSearchMode(false);
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
                            _controller.searchLists(value);
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
                            if (_controller.currentPageIndex != 3) // From controller
                              IconButton(
                                onPressed: () {
                                  _controller.setSearchMode(true);
                                },
                                icon: const Icon(Icons.search_rounded),
                              ),
                            _controller.currentPageIndex == 3 // From controller
                                ? Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: IconButton(
                                      icon: Icon(
                                        ShowCaseHelper.instance.isActive
                                            ? Icons.pause_circle_outline_rounded
                                            : Icons.help_outline_rounded,
                                      ),
                                      onPressed: () {
                                        // Keep setState for purely local UI changes if any
                                        setState(() {
                                          ShowCaseHelper.instance.toggleIsActive();
                                        });
                                        ShowCaseHelper.instance
                                            .startShowCaseBeginning(
                                                showcaseCnx, [_addListKey]);
                                      },
                                    ),
                                  )
                                : PopupMenuButton<SortBy>(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10.0),
                                      ),
                                    ),
                                    icon: const Icon(Icons.filter_list_rounded),
                                    onSelected: (value) async {
                                      await _controller.changeSortBy(value);
                                    },
                                    itemBuilder: (BuildContext cnx) => [
                                      CheckedPopupMenuItem<SortBy>(
                                        value: SortBy.creationNTL,
                                        checked: _controller.currentSortBy == // From controller
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
                                        checked: _controller.currentSortBy == // From controller
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
                                        checked: _controller.currentSortBy == // From controller
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
                                        checked: _controller.currentSortBy == // From controller
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
                                        checked: _controller.currentSortBy == // From controller
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
                                        checked: _controller.currentSortBy == // From controller
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
                Expanded(
                  child: _controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _controller.searchMode
                          ? ItemsScreen(
                              existingItems: _controller.searchResults, // From controller
                              deleteItem: _deleteList, // Use new method
                              refresh: _controller.refreshAllLists, // Pass controller's refresh
                              title: context.translate(Strings.searchResults),
                            )
                          : PageView(
                              onPageChanged: (index) {
                                // Note: This onPageChanged is from user swipe.
                                // We need to inform the controller.
                                _controller.onPageChanged(index);
                              },
                              controller: _pageController, // Use the local PageController
                              children: [
                                ItemsScreen(
                                  existingItems: _controller.activeLists, // From controller
                                  deleteItem: _deleteList,
                                  refresh: _controller.refreshAllLists,
                                  title: _titles[_controller.currentPageIndex], // Use controller's index
                                ),
                                ItemsScreen(
                                  existingItems: _controller.achievedLists, // From controller
                                  deleteItem: _deleteList,
                                  refresh: _controller.refreshAllLists,
                                  title: _titles[_controller.currentPageIndex],
                                ),
                                ItemsScreen(
                                  existingItems: _controller.withoutDeadlineLists, // From controller
                                  deleteItem: _deleteList,
                                  refresh: _controller.refreshAllLists,
                                  title: _titles[_controller.currentPageIndex],
                                ),
                                Settings(refresh: _controller.refreshAllLists), // Pass controller's refresh
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

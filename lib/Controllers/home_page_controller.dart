import 'package:flutter/material.dart';
import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Screens/home_page.dart'; // For SortBy enum

class HomePageController extends ChangeNotifier {
  final ListsProvider _listsProvider;
  BuildContext context; // Needed for initialization and potentially other context-dependent provider actions

  List<ToDoList> _activeLists = [];
  List<ToDoList> _achievedLists = [];
  List<ToDoList> _withoutDeadlineLists = [];
  List<ToDoList> _searchResults = [];

  bool _isLoading = false;
  int _currentPageIndex = 0;
  bool _searchMode = false;

  // Getters for the UI to consume
  List<ToDoList> get activeLists => _activeLists;
  List<ToDoList> get achievedLists => _achievedLists;
  List<ToDoList> get withoutDeadlineLists => _withoutDeadlineLists;
  List<ToDoList> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  int get currentPageIndex => _currentPageIndex;
  SortBy get currentSortBy => _listsProvider.selectedOptionVal;
  bool get searchMode => _searchMode;

  HomePageController({required ListsProvider listsProvider, required this.context})
      : _listsProvider = listsProvider {
    // Listen to changes in ListsProvider to refresh data if underlying data changes externally
    // However, the controller will manage when to notify its own listeners.
    _listsProvider.addListener(_handleListsProviderChanges);
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners(); // Notify UI that loading has started

    await _listsProvider.initialization(context);
    await _fetchAllLists();

    _isLoading = false;
    notifyListeners(); // Notify UI that loading is complete
  }

  Future<void> _fetchAllLists() async {
    _activeLists = await _listsProvider.getActiveItems();
    _achievedLists = await _listsProvider.getAchievedItems();
    _withoutDeadlineLists = await _listsProvider.getWithoutDeadlineItems();
  }

  // Called when ListsProvider notifies its listeners
  // This allows the controller to react to external changes if necessary
  // For example, if another part of the app modifies a list.
  void _handleListsProviderChanges() async {
    // Re-fetch all lists and notify listeners.
    // This is a broad update, we can refine this later if needed.
    await refreshAllLists();
  }

  Future<void> refreshAllLists({String searchVal = ""}) async {
    _isLoading = true;
    notifyListeners(); // Optional: notify UI that a refresh is happening

    _listsProvider.invalidateCache(); // Ensure fresh data from DB
    await _fetchAllLists();
    if (_searchMode && searchVal.isNotEmpty) {
        _searchResults = await _listsProvider.searchListsByTitle(searchVal);
    } else if (_searchMode && searchVal.isEmpty) {
        _searchResults = []; // Or fetch all lists for search mode if that's the desired UX
    }

    _isLoading = false;
    notifyListeners();
  }

  void onPageChanged(int index) {
    if (_currentPageIndex == index) return;
    _currentPageIndex = index;
    _searchMode = false; // Exit search mode when changing pages
    // No need to re-fetch all lists here if they are already loaded,
    // unless a specific page needs fresh data not covered by general refresh.
    notifyListeners();
  }

  Future<void> deleteList(ToDoList list) async {
    _isLoading = true;
    notifyListeners();
    await _listsProvider.deleteList(list); // This will call invalidateCache and notifyListeners in ListsProvider
    // _handleListsProviderChanges will be triggered, which calls refreshAllLists.
    // So, no need to call _fetchAllLists or notifyListeners here directly if _handleListsProviderChanges is robust.
    // However, for more immediate feedback, we can update the local cache directly or just rely on the provider's notification.
    // For now, relying on _handleListsProviderChanges.
    // If _handleListsProviderChanges is too broad, we might manually update:
    // _activeLists.remove(list);
    // _achievedLists.remove(list);
    // _withoutDeadlineLists.remove(list);
    // _isLoading = false;
    // notifyListeners();
  }

  Future<String?> createNewList(String title, DateTime deadline, bool hasDeadline) async {
    _isLoading = true;
    notifyListeners();
    final result = await _listsProvider.createNewList(title, deadline, hasDeadline);
    // _handleListsProviderChanges will refresh the lists.
    // The result.data contains the new list ID.
    _isLoading = false;
    // We might want to notify listeners here if the UI needs to react before _handleListsProviderChanges kicks in,
    // or if _handleListsProviderChanges isn't called for createNewList (it should be due to notifyListeners in provider).
    notifyListeners();
    return result.data;
  }

  Future<void> editListTitle(ToDoList list, String newTitle) async {
    _isLoading = true;
    notifyListeners();
    await _listsProvider.editTitle(list, newTitle);
    // _handleListsProviderChanges will refresh.
    _isLoading = false;
    // notifyListeners(); // Potentially notify if immediate UI update needed before provider sync
  }

  Future<bool> editListDeadline(ToDoList list, DateTime? newDeadline) async {
    _isLoading = true;
    notifyListeners();
    bool result = await _listsProvider.editDeadline(list, newDeadline);
    // _handleListsProviderChanges will refresh.
    _isLoading = false;
    // notifyListeners();
    return result;
  }

  Future<void> changeSortBy(SortBy newSortBy) async {
    // isLoading state and notifyListeners will be handled by the refreshAllLists flow,
    // which is triggered by the _listsProvider.selectedOptionVal setter.
    await SharedPreferencesHelper.instance.setSortByIndex(SortBy.values.indexOf(newSortBy));
    _listsProvider.selectedOptionVal = newSortBy;
  }

  void setSearchMode(bool enabled, {String initialSearchVal = ""}) async {
    if (_searchMode == enabled && enabled == false) return;

    _searchMode = enabled;
    if (_searchMode) {
        _isLoading = true;
        notifyListeners();
        _searchResults = await _listsProvider.searchListsByTitle(initialSearchVal);
        _isLoading = false;
    } else {
        _searchResults = [];
    }
    notifyListeners();
  }

  Future<void> searchLists(String searchVal) async {
    if (!_searchMode) return;

    _isLoading = true;
    notifyListeners();
    _searchResults = await _listsProvider.searchListsByTitle(searchVal);
    _isLoading = false;
    notifyListeners();
  }


  @override
  void dispose() {
    _listsProvider.removeListener(_handleListsProviderChanges);
    super.dispose();
  }
}

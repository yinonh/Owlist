import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Widgets/items_screen.dart';
import '../Widgets/add_list.dart';
import '../Screens/sign_in_sign_up_screen.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home_page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ListsProvider provider;
  late Future<List<ToDoList>> activeItemsFuture;
  late Future<List<ToDoList>> achievedItemsFuture;

  int currentIndex = 0;
  PageController selectedIndex = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    activeItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getActiveItems();
    achievedItemsFuture =
        Provider.of<ListsProvider>(context, listen: false).getAchievedItems();
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
    });
  }

  void addItem(String title, DateTime deadline) {
    setState(() {
      activeItemsFuture = activeItemsFuture.then((activeItems) {
        return provider.createNewList(title, deadline).then((_) {
          return provider.getActiveItems();
        });
      });
    });
  }

  void _onItemTapped(int index) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<ListsProvider>(context);
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: currentIndex,
        onTap: _onItemTapped,
        selectedIconTheme: const IconThemeData(
          size: 30,
        ),
        unselectedIconTheme: const IconThemeData(
          size: 20,
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.fact_check,
            ),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.archive,
            ),
            label: 'Archived',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshLists,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF635985), Color(0xFF18122B)],
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
                      IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(
                            context,
                            LoginScreen.routeName,
                          );
                        },
                        icon: Icon(Icons.logout),
                      ),
                      const Text(
                        'To-Do',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      AddList(add_item: addItem),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    currentIndex == 0 ? 'Active Items' : 'Archived Items',
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
                    onPageChanged: _onItemTapped,
                    controller: selectedIndex,
                    children: [
                      FutureBuilder<List<ToDoList>>(
                        future: activeItemsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(seconds: 2),
                                content: Text(
                                  'Error',
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                            return Text(
                              'Error: ${snapshot.error}',
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
                                  'Error',
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                            return Text(
                              'Error: ${snapshot.error}',
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

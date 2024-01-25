import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/l10n/app_localizations.dart';

import '../Providers/lists_provider.dart';
import '../Widgets/statistics_graphs.dart';

class StatisticsScreen extends StatefulWidget {
  static const routeName = '/statistics';

  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;
  Map<String, int>? statistics;

  @override
  Widget build(BuildContext context) {
    final listsProvider = Provider.of<ListsProvider>(context);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Text(
                        AppLocalizations.of(context).translate("Statistics"),
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                        width: 20,
                      )
                    ],
                  ),
                ),
                statistics == null
                    ? FutureBuilder<Map<String, int>>(
                        future: listsProvider.updateStatistics(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else {
                            statistics = snapshot.data;
                            return StatisticsGraphs(statistics: statistics!);
                          }
                        },
                      )
                    : StatisticsGraphs(statistics: statistics!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

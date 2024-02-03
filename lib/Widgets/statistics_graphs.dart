import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../Utils/l10n/app_localizations.dart';

class StatisticsGraphs extends StatefulWidget {
  final Map<String, int> statistics;
  const StatisticsGraphs({Key? key, required this.statistics})
      : super(key: key);

  @override
  State<StatisticsGraphs> createState() => _StatisticsGraphsState();
}

class _StatisticsGraphsState extends State<StatisticsGraphs> {
  @override
  Widget build(BuildContext context) {
    final listsStatisticList = showingListSections(widget.statistics);
    final itemsStatisticList = showingItemsSections(widget.statistics);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate("List Data:"),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          widget.statistics['totalLists'] == 0
              ? SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate("No Data"),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: PieChart(
                    PieChartData(
                      borderData: FlBorderData(
                        show: false,
                      ),
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: listsStatisticList,
                    ),
                  ),
                ),
          Text(
            AppLocalizations.of(context).translate("Items Data"),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          widget.statistics['totalItems'] == 0
              ? SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate("No Data"),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: itemsStatisticList,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingListSections(Map<String, int>? statistics) {
    return List.generate(3, (i) {
      const radius = 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Theme.of(context).highlightColor,
            value: statistics!['withoutDeadline']!.toDouble(),
            title:
                '${AppLocalizations.of(context).translate("Without Deadline")}\n ${(statistics['withoutDeadline']! / statistics['totalLists']! * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Theme.of(context).focusColor,
            value: (statistics!['activeLists']!).toDouble(),
            title:
                '${AppLocalizations.of(context).translate("Active Lists")}\n ${(statistics['activeLists']! / statistics['totalLists']! * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Theme.of(context).primaryColorLight,
            value: statistics!['listsDone']!.toDouble(),
            title:
                '${AppLocalizations.of(context).translate("Archived Lists")}\n ${(statistics['listsDone']! / statistics['totalLists']! * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  List<PieChartSectionData> showingItemsSections(Map<String, int>? statistics) {
    return List.generate(3, (i) {
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Theme.of(context).highlightColor,
            value: widget.statistics['itemsNotDone']!.toDouble(),
            title:
                "${AppLocalizations.of(context).translate("Items in process")}\n ${(widget.statistics['itemsNotDone']! / widget.statistics['totalItems']! * 100).toStringAsFixed(1)}%",
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
            radius: 80,
          );
        case 1:
          return PieChartSectionData(
            color: Theme.of(context).focusColor,
            value: widget.statistics['itemsDelayed']!.toDouble(),
            title:
                "${AppLocalizations.of(context).translate("Items delayed")}\n ${(widget.statistics['itemsDelayed']! / widget.statistics['totalItems']! * 100).toStringAsFixed(1)}%",
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            radius: 70,
          );
        case 2:
          return PieChartSectionData(
            color: Theme.of(context).primaryColorLight,
            value: widget.statistics['itemsDone']!.toDouble(),
            title:
                "${AppLocalizations.of(context).translate("Items done")}\n ${(widget.statistics['itemsDone']! / widget.statistics['totalItems']! * 100).toStringAsFixed(1)}%",
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            radius: 60,
          );
        default:
          throw Error();
      }
    });
  }
}

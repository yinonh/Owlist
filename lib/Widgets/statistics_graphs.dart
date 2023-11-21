import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:to_do/l10n/app_localizations.dart';

class StatisticsGraphs extends StatefulWidget {
  final Map<String, int> statistics;
  const StatisticsGraphs({Key? key, required this.statistics})
      : super(key: key);

  @override
  State<StatisticsGraphs> createState() => _StatisticsGraphsState();
}

class _StatisticsGraphsState extends State<StatisticsGraphs> {
  int touchedListIndex = -1;
  int touchedItemIndex = -1;

  @override
  Widget build(BuildContext context) {
    final listsStatisticList = showingListSections(widget.statistics);
    final itemsStatisticList = showingItemsSections(widget.statistics);
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate("List Data:"),
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            height: 250,
            width: double.infinity,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedListIndex = -1;
                        return;
                      }
                      touchedListIndex = listsStatisticList.indexOf(
                          pieTouchResponse.touchedSection!.props[0]
                              as PieChartSectionData);
                    });
                  },
                ),
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
            AppLocalizations.of(context).translate("Items Data:"),
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            height: 250,
            width: double.infinity,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedItemIndex = -1;
                        return;
                      }
                      touchedItemIndex = itemsStatisticList.indexOf(
                          pieTouchResponse.touchedSection!.props[0]
                              as PieChartSectionData);
                    });
                  },
                ),
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
      final isTouched = i == touchedListIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Theme.of(context).highlightColor,
            value: statistics!['withoutDeadline']!.toDouble(),
            // badgeWidget: Container(
            //   padding: EdgeInsets.symmetric(horizontal: 5),
            //   child: Text(
            //       AppLocalizations.of(context).translate("Without Deadline"),
            //       style: TextStyle(
            //         color: Colors.white,
            //       )),
            // ),
            // badgePositionPercentageOffset: 1.4,
            title:
                'Without Deadline: ${(statistics['withoutDeadline']! / statistics['totalLists']! * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Theme.of(context).focusColor,
            value: (statistics!['activeLists']!).toDouble(),
            // badgeWidget: Text("Active",
            //     style: TextStyle(
            //       color: Colors.white,
            //     )),
            // badgePositionPercentageOffset: 1.8,
            title:
                'Active: ${(statistics['activeLists']! / statistics['totalLists']! * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Theme.of(context).primaryColorLight,
            value: statistics!['listsDone']!.toDouble(),
            // badgeWidget: Text(
            //   "Archived",
            //   style: TextStyle(
            //     color: Colors.white,
            //   ),
            // ),
            // badgePositionPercentageOffset: 1.4,
            title:
                'Archived: ${(statistics['listsDone']! / statistics['totalLists']! * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
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
      final isTouched = i == touchedItemIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      switch (i) {
        case 0:
          return PieChartSectionData(
            // badgeWidget: Text(
            //   "In Process",
            //   style: TextStyle(
            //     color: Colors.white,
            //   ),
            // ),
            // badgePositionPercentageOffset: 1.3,
            color: Theme.of(context).highlightColor,
            value: widget.statistics['itemsNotDone']!.toDouble(),
            title:
                "In Process: ${(widget.statistics['itemsNotDone']! / widget.statistics['totalItems']! * 100).toStringAsFixed(1)} %",
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
            radius: 80,
          );
        case 1:
          return PieChartSectionData(
            // badgeWidget: Text(
            //   "Delayed",
            //   style: TextStyle(
            //     color: Colors.white,
            //   ),
            // ),
            // badgePositionPercentageOffset: 1.6,
            color: Theme.of(context).focusColor,
            value: widget.statistics['itemsDelayed']!.toDouble(),
            title:
                "Delayed: ${(widget.statistics['itemsDelayed']! / widget.statistics['totalItems']! * 100).toStringAsFixed(1)} %",
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            radius: 70,
          );
        case 2:
          return PieChartSectionData(
            // badgeWidget: Text(
            //   "Done",
            //   style: TextStyle(
            //     color: Colors.white,
            //   ),
            // ),
            // badgePositionPercentageOffset: 1.6,
            color: Theme.of(context).primaryColorLight,
            value: widget.statistics['itemsDone']!.toDouble(),
            title:
                "Done: ${(widget.statistics['itemsDone']! / widget.statistics['totalItems']! * 100).toStringAsFixed(1)} %",
            titleStyle: TextStyle(
              fontSize: fontSize,
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

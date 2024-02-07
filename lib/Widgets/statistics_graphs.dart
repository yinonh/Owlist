import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:to_do/main.dart';

import '../Utils/l10n/app_localizations.dart';

class StatisticsGraphs extends StatefulWidget {
  final Map<String, int> statistics;
  const StatisticsGraphs({Key? key, required this.statistics})
      : super(key: key);

  @override
  State<StatisticsGraphs> createState() => _StatisticsGraphsState();
}

class _StatisticsGraphsState extends State<StatisticsGraphs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          widget.statistics['totalLists'] != 0
              ? FadeTransition(
                  opacity: _animation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProgressBar(
                              title: AppLocalizations.of(context)
                                  .translate("Archived Lists"),
                              value: widget.statistics['listsDone']!.toInt(),
                              total: widget.statistics['totalLists']!),
                          _buildProgressBar(
                              title: AppLocalizations.of(context)
                                  .translate("Active Lists"),
                              value: widget.statistics['activeLists']!.toInt(),
                              total: widget.statistics['totalLists']!),
                          _buildProgressBar(
                              title: AppLocalizations.of(context)
                                  .translate("Without Deadline"),
                              value:
                                  widget.statistics['withoutDeadline']!.toInt(),
                              total: widget.statistics['totalLists']!),
                        ],
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 0,
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
                  child: FadeTransition(
                    opacity: _animation,
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
                ),
          Text(
            AppLocalizations.of(context).translate("Items Data"),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          widget.statistics['totalItems'] != 0
              ? FadeTransition(
                  opacity: _animation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProgressBar(
                              title: AppLocalizations.of(context)
                                  .translate("Items done"),
                              value: widget.statistics['itemsDone']!.toInt(),
                              total: widget.statistics['totalItems']!),
                          _buildProgressBar(
                              title: AppLocalizations.of(context)
                                  .translate("Items delayed"),
                              value: widget.statistics['itemsDelayed']!.toInt(),
                              total: widget.statistics['totalItems']!),
                          _buildProgressBar(
                              title: AppLocalizations.of(context)
                                  .translate("Items in process"),
                              value: widget.statistics['itemsNotDone']!.toInt(),
                              total: widget.statistics['totalItems']!),
                        ],
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 0,
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
                  child: FadeTransition(
                    opacity: _animation,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: itemsStatisticList,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      {required String title, required int value, required int total}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10.0),
          Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _animation,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: value / total,
                    strokeWidth: 10,
                    backgroundColor: Color(0xFF18122B),
                  ),
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
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

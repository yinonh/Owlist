import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/strings.dart';

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
            context.translate(Strings.listData),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          widget.statistics[Keys.totalLists] != 0
              ? FadeTransition(
                  opacity: _animation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Row(
                        children: [
                          _buildProgressBar(
                              title: context.translate(Strings.archivedLists),
                              value: widget.statistics[Keys.listsDone]!.toInt(),
                              total: widget.statistics[Keys.totalLists]!),
                          _buildProgressBar(
                              title: context.translate(Strings.activeLists),
                              value:
                                  widget.statistics[Keys.activeLists]!.toInt(),
                              total: widget.statistics[Keys.totalLists]!),
                          _buildProgressBar(
                              title: context.translate(Strings.withoutDeadline),
                              value: widget.statistics[Keys.withoutDeadline]!
                                  .toInt(),
                              total: widget.statistics[Keys.totalLists]!),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(
                  height: 0,
                ),
          widget.statistics[Keys.totalLists] == 0
              ? SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      context.translate(Strings.noData),
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
            context.translate(Strings.itemsData),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          widget.statistics[Keys.totalItems] != 0
              ? FadeTransition(
                  opacity: _animation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Row(
                        children: [
                          _buildProgressBar(
                              title: context.translate(Strings.itemsDone),
                              value: widget.statistics[Keys.itemsDone]!.toInt(),
                              total: widget.statistics[Keys.totalItems]!),
                          _buildProgressBar(
                              title: context.translate(Strings.itemsDelayed),
                              value:
                                  widget.statistics[Keys.itemsDelayed]!.toInt(),
                              total: widget.statistics[Keys.totalItems]!),
                          _buildProgressBar(
                              title: context.translate(Strings.itemsInProcess),
                              value:
                                  widget.statistics[Keys.itemsNotDone]!.toInt(),
                              total: widget.statistics[Keys.totalItems]!),
                        ],
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 0,
                ),
          widget.statistics[Keys.totalItems] == 0
              ? SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      context.translate(Strings.noData),
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
            value: statistics![Keys.withoutDeadline]!.toDouble(),
            title:
                '${context.translate(Strings.withoutDeadline)}\n ${(statistics[Keys.withoutDeadline]! / statistics[Keys.totalLists]! * 100).toStringAsFixed(1)}%',
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
            value: (statistics![Keys.activeLists]!).toDouble(),
            title:
                '${context.translate(Strings.activeLists)}\n ${(statistics[Keys.activeLists]! / statistics[Keys.totalLists]! * 100).toStringAsFixed(1)}%',
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
            value: statistics![Keys.listsDone]!.toDouble(),
            title:
                '${context.translate(Strings.archivedLists)}\n ${(statistics[Keys.listsDone]! / statistics[Keys.totalLists]! * 100).toStringAsFixed(1)}%',
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
            value: widget.statistics[Keys.itemsNotDone]!.toDouble(),
            title:
                "${context.translate(Strings.itemsInProcess)}\n ${(widget.statistics[Keys.itemsNotDone]! / widget.statistics[Keys.totalItems]! * 100).toStringAsFixed(1)}%",
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
            value: widget.statistics[Keys.itemsDelayed]!.toDouble(),
            title:
                "${context.translate(Strings.itemsDelayed)}\n ${(widget.statistics[Keys.itemsDelayed]! / widget.statistics[Keys.totalItems]! * 100).toStringAsFixed(1)}%",
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
            value: widget.statistics[Keys.itemsDone]!.toDouble(),
            title:
                "${context.translate(Strings.itemsDone)}\n ${(widget.statistics[Keys.itemsDone]! / widget.statistics[Keys.totalItems]! * 100).toStringAsFixed(1)}%",
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

import 'package:day_night_time_picker/lib/constants.dart';
import 'package:day_night_time_picker/lib/daynight_timepicker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Models/notification.dart';
import '../Models/to_do_list.dart';
import '../Providers/lists_provider.dart';
import '../Providers/notification_provider.dart';
import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/notification_time.dart';
import '../Utils/shared_preferences_helper.dart';
import '../Utils/show_case_helper.dart';
import '../Utils/strings.dart';

class NotificationBottomSheet extends StatefulWidget {
  final String listId;

  const NotificationBottomSheet({required this.listId, Key? key})
      : super(key: key);

  @override
  _NotificationBottomSheetState createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  final GlobalKey<ScaffoldState> notificationsKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> notificationsStatusKey =
      GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        Duration(milliseconds: 400),
        () => ShowCaseHelper.instance.startShowCaseNotifications(
            context, [notificationsKey, notificationsStatusKey]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseHelper.instance.customShowCase(
      key: notificationsKey,
      description: context
          .translate(ShowCaseHelper.instance.notificationsShowCaseDescription),
      context: context,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.4 + 20,
        child: FutureBuilder(
          future:
              Provider.of<ListsProvider>(context).getListById(widget.listId),
          builder: (context, futureList) {
            if (futureList.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (futureList.hasError) {
              return Text('Error: ${futureList.error}');
            } else {
              ToDoList list = futureList.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).highlightColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: FutureBuilder<List<Notifications>>(
                      future: Provider.of<NotificationProvider>(context)
                          .getNotificationsByListId(list.id),
                      builder: (context, futureNotificationList) {
                        if (futureNotificationList.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (futureNotificationList.hasError) {
                          return Text('Error: ${futureNotificationList.error}');
                        } else if (futureNotificationList.hasData &&
                            futureNotificationList.data!.isEmpty) {
                          return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: header(list),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Lottie.asset(
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Keys.emptyNotificationsDark
                                          : Keys.emptyNotificationsLight,
                                    ),
                                  ),
                                ),
                              ]);
                        } else {
                          List<Notifications> notificationsList =
                              List.from(futureNotificationList.data!);
                          notificationsList.sort((a, b) => a
                              .notificationDateTime
                              .compareTo(b.notificationDateTime));
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: header(list,
                                    notificationsList: notificationsList),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: notificationsList.length,
                                  itemBuilder: (context, index) {
                                    final notification =
                                        notificationsList[index];
                                    if (index == 0) {
                                      return ShowCaseHelper.instance
                                          .customShowCase(
                                        key: notificationsStatusKey,
                                        description: context.translate(
                                            ShowCaseHelper.instance
                                                .notificationsStateShowCaseDescription),
                                        context: context,
                                        child: _buildNotificationItem(
                                            context, notification, list),
                                      );
                                    }
                                    return _buildNotificationItem(
                                        context, notification, list);
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  void showPopup(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: message,
        backgroundColor: Theme.of(context).highlightColor,
        icon: Icon(
          Icons.notifications_off_rounded,
          color: Theme.of(context).primaryColorDark.withValues(alpha: 0.2),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.top,
      displayDuration: const Duration(seconds: 1, milliseconds: 500),
    );
  }

  Widget header(ToDoList list, {List<Notifications>? notificationsList}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).dialogBackgroundColor,
              size: 32,
            )),
        FittedBox(
          child: Text(
            context.translate(Strings.notifications),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        (!list.isAchieved &&
                (notificationsList == null
                    ? true
                    : notificationsList.length < 4))
            ? IconButton(
                onPressed: () async {
                  DateTime? newTime = await _openDateTimePicker(context, list);
                  if (newTime != null) {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .addNotification(list, newTime);
                  }
                },
                icon: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).dialogBackgroundColor,
                ),
              )
            : IconButton(
                onPressed: () {
                  showPopup(context
                      .translate(Strings.youCantAddNotificationsToThisList));
                },
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.grey,
                ),
              ),
      ],
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Notifications notification, ToDoList list) {
    var dateFormatted = DateFormat(context.translate(Strings.dateFormat))
        .format(notification.notificationDateTime);

    final timeFormatted =
        DateFormat(Keys.timeFormat).format(notification.notificationDateTime);

    return ListTile(
      leading: IconButton(
        onPressed: !list.isAchieved
            ? () => Provider.of<NotificationProvider>(context, listen: false)
                .toggleNotificationDisabled(notification, list)
            : null,
        icon: Icon(
          notification.disabled
              ? Icons.notifications_off_rounded
              : notification.notificationDateTime.isBefore(DateTime.now())
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
          color: notification.disabled ||
                  notification.notificationDateTime.isBefore(DateTime.now())
              ? Theme.of(context).hintColor
              : Theme.of(context).highlightColor,
        ),
      ),
      title: Text("${context.translate(Strings.date)}: $dateFormatted"),
      subtitle: Text("${context.translate(Strings.time)}: $timeFormatted"),
      onTap: !list.isAchieved
          ? () async {
              DateTime? newTime = await _openDateTimePicker(context, list,
                  notification: notification);
              if (newTime != null) {
                Provider.of<NotificationProvider>(context, listen: false)
                    .editNotification(
                        notification.copyWith(notificationDateTime: newTime),
                        list);
              }
            }
          : null,
      trailing: IconButton(
        icon: Icon(
          Icons.delete_rounded, // Use constant trailing icon
          color: Theme.of(context).highlightColor,
        ),
        onPressed: () async {
          var notificationProvider =
              Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.deleteNotification(notification, list);
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: context.translate(Strings.itemDeletedPressHereToUndo),
              backgroundColor: Theme.of(context).highlightColor,
              icon: Icon(
                Icons.warning_rounded,
                color:
                    Theme.of(context).primaryColorDark.withValues(alpha: 0.2),
                size: 120,
              ),
            ),
            onTap: () {
              notificationProvider.addNotification(
                  list, notification.notificationDateTime);
            },
            snackBarPosition: SnackBarPosition.top,
            displayDuration: const Duration(seconds: 1, milliseconds: 500),
          );
        },
      ),
    );
  }

  bool isToday(DateTime dateTime) {
    DateTime now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  Future<DateTime?> _openDateTimePicker(BuildContext context, ToDoList list,
      {Notifications? notification}) async {
    late DateTime initialDate;
    late NotificationTime newTime;
    if (notification == null) {
      initialDate = DateTime.now();
      newTime = NotificationTime.fromInt(
          await SharedPreferencesHelper.instance.getNotificationTime());
    } else {
      initialDate = notification.notificationDateTime;
      newTime =
          NotificationTime(hour: initialDate.hour, minute: initialDate.minute);
    }

    // Check if initialDate is before the firstDate
    if (initialDate.isBefore(DateTime.now())) {
      initialDate = DateTime.now();
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: list.hasDeadline
          ? list.deadline
          : DateTime.now().add(
              const Duration(days: 3650),
            ),
    );

    if (selectedDate != null) {
      return Navigator.of(context)
          .push(
        showPicker(
          height: 350,
          is24HrFormat: true,
          backgroundColor: Theme.of(context).primaryColorLight,
          accentColor: Theme.of(context).highlightColor,
          context: context,
          showSecondSelector: false,
          value: newTime,
          onChange: (time) {
            newTime = NotificationTime(hour: time.hour, minute: time.minute);
          },
          minuteInterval: TimePickerInterval.FIVE,
          okText: context.translate(Strings.ok),
          cancelText: context.translate(Strings.cancel),
        ),
      )
          .then((value) {
        if (value == null) return null;

        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          newTime.hour,
          newTime.minute,
        );
        return selectedDateTime;
      });
    }

    return null;
  }
}

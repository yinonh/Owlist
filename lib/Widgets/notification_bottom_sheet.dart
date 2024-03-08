import 'package:day_night_time_picker/lib/constants.dart';
import 'package:day_night_time_picker/lib/daynight_timepicker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Providers/lists_provider.dart';
import '../Utils/shared_preferences_helper.dart';
import '../Providers/notification_provider.dart';
import '../Utils/notification_time.dart';
import '../Utils/strings.dart';
import '../Models/notification.dart';
import '../Models/to_do_list.dart';

class NotificationBottomSheet extends StatefulWidget {
  final String listId;

  const NotificationBottomSheet({required this.listId, Key? key})
      : super(key: key);

  @override
  _NotificationBottomSheetState createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<ListsProvider>(context).getListById(widget.listId),
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
                      return const Center(child: CircularProgressIndicator());
                    } else if (futureNotificationList.hasError) {
                      return Text('Error: ${futureNotificationList.error}');
                    } else if (futureNotificationList.hasData &&
                        futureNotificationList.data!.isEmpty) {
                      return Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: header(list),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              context.translate(Strings.noNotificationsFound),
                            ),
                          ),
                        )
                      ]);
                    } else {
                      List<Notifications> notificationsList =
                          List.from(futureNotificationList.data!);
                      notificationsList.sort((a, b) => a.notificationDateTime
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
                                final notification = notificationsList[index];
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
              Icons.arrow_downward,
              color: Theme.of(context).canvasColor,
            )),
        FittedBox(
          child: Text(
            context.translate(Strings.notifications),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        !list.isAchieved &&
                (notificationsList == null
                    ? true
                    : notificationsList.length < 4)
            ? IconButton(
                onPressed: () async {
                  DateTime? newTime = await _openDateTimePicker(context, list);
                  if (newTime != null) {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .addNotification(list, newTime);
                  }
                },
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).canvasColor,
                ),
              )
            : const IconButton(
                onPressed: null,
                icon: Icon(
                  Icons.add,
                  color: Colors.grey,
                ),
              ),
      ],
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Notifications notification, ToDoList list) {
    var dateFormatted =
        DateFormat('MM/dd/yyyy').format(notification.notificationDateTime);

    if ((SharedPreferencesHelper.instance.selectedLanguage ??
            Localizations.localeOf(context).languageCode) ==
        'he') {
      dateFormatted =
          DateFormat('dd/MM/yyyy').format(notification.notificationDateTime);
    }
    final timeFormatted =
        DateFormat('HH:mm').format(notification.notificationDateTime);

    return ListTile(
      leading: IconButton(
        onPressed: !list.isAchieved
            ? () => Provider.of<NotificationProvider>(context, listen: false)
                .toggleNotificationDisabled(notification)
            : null,
        icon: Icon(
          notification.disabled
              ? Icons.notifications_off
              : notification.notificationDateTime.isBefore(DateTime.now())
                  ? Icons.notifications_none
                  : Icons.notifications_active,
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
          Icons.delete, // Use constant trailing icon
          color: Theme.of(context).highlightColor,
        ),
        onPressed: () async {
          Provider.of<NotificationProvider>(context, listen: false)
              .deleteNotification(notification, list);
        }, // Pass notification object to function
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
      lastDate: list.deadline,
    );

    if (selectedDate != null) {
      return Navigator.of(context)
          .push(
        showPicker(
          height: 350,
          is24HrFormat: true,
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

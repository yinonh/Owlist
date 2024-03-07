import 'package:day_night_time_picker/lib/constants.dart';
import 'package:day_night_time_picker/lib/daynight_timepicker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Utils/shared_preferences_helper.dart';
import '../Providers/notification_provider.dart';
import '../Utils/notification_time.dart';
import '../Utils/strings.dart';
import '../Models/notification.dart';
import '../Models/to_do_list.dart';

class NotificationBottomSheet extends StatefulWidget {
  final ToDoList list;

  const NotificationBottomSheet({required this.list, Key? key})
      : super(key: key);

  @override
  _NotificationBottomSheetState createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(
                      width: 50,
                    ),
                    FittedBox(
                      child: Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        DateTime? newTime = await _openDateTimePicker(context);
                        if (newTime != null) {
                          Provider.of<NotificationProvider>(context,
                                  listen: false)
                              .addNotification(widget.list, newTime);
                        }
                      },
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<Notifications>>(
                future: Provider.of<NotificationProvider>(context)
                    .getNotificationsByListId(widget.list.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Placeholder while loading
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                    return const Text('No notifications found');
                  } else {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final notification = snapshot.data![index];
                        return _buildNotificationItem(context, notification);
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Notifications notification) {
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
        onPressed: () =>
            Provider.of<NotificationProvider>(context, listen: false)
                .toggleNotificationDisabled(notification),
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
      title: Text("Date: $dateFormatted"),
      subtitle: Text("Time: $timeFormatted"),
      onTap: () async {
        DateTime? newTime =
            await _openDateTimePicker(context, notification: notification);
        if (newTime != null) {
          Provider.of<NotificationProvider>(context, listen: false)
              .editNotification(
                  notification.copyWith(notificationDateTime: newTime),
                  widget.list);
        }
      },
      trailing: IconButton(
        icon: Icon(
          Icons.delete, // Use constant trailing icon
          color: Theme.of(context).highlightColor,
        ),
        onPressed: () async {
          Provider.of<NotificationProvider>(context, listen: false)
              .deleteNotification(notification, widget.list);
        }, // Pass notification object to function
      ),
    );
  }

  Future<DateTime?> _openDateTimePicker(BuildContext context,
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
      lastDate: widget.list.deadline,
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

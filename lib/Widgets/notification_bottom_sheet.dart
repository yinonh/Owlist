import 'package:day_night_time_picker/lib/constants.dart';
import 'package:day_night_time_picker/lib/daynight_timepicker.dart';
import 'package:day_night_time_picker/lib/state/time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:to_do/Providers/notification_provider.dart';
import 'package:to_do/Utils/strings.dart';

import '../Models/notification.dart';
import '../Utils/shared_preferences_helper.dart';

class NotificationBottomSheet extends StatefulWidget {
  final String listId;

  const NotificationBottomSheet({required this.listId, Key? key})
      : super(key: key);

  @override
  _NotificationBottomSheetState createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  late TextEditingController _oneDayController;
  late TextEditingController _oneWeekController;
  late TextEditingController _twoWeeksController;
  late TextEditingController _oneMonthController;

  @override
  void initState() {
    super.initState();
    _oneDayController = TextEditingController();
    _oneWeekController = TextEditingController();
    _twoWeeksController = TextEditingController();
    _oneMonthController = TextEditingController();
  }

  @override
  void dispose() {
    _oneDayController.dispose();
    _oneWeekController.dispose();
    _twoWeeksController.dispose();
    _oneMonthController.dispose();
    super.dispose();
  }

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
            color: Colors.grey[400],
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
                      onPressed: () {},
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
                    .getNotificationsByListId(widget.listId),
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
      leading: Icon(
        notification.disabled
            ? Icons.notifications_off
            : Icons.notifications_active,
        color: notification.disabled
            ? Theme.of(context).hintColor
            : Theme.of(context).highlightColor,
      ),
      title: Text("Date: $dateFormatted"),
      subtitle: Text("Time: $timeFormatted"),
      onTap: () => _openDateTimePicker(context, notification),
      trailing: IconButton(
        icon: Icon(
          Icons.delete, // Use constant trailing icon
          color: Theme.of(context).highlightColor,
        ),
        onPressed: () {}, // Pass notification object to function
      ),
    );
  }

  void onTimeChanged(Time originalTime) {
    print(originalTime);
  }

  void _openDateTimePicker(
      BuildContext context, Notifications notification) async {
    DateTime initialDateTime = notification.notificationDateTime;

    // Check if initialDateTime is before the firstDate
    if (initialDateTime.isBefore(DateTime.now())) {
      initialDateTime = DateTime.now();
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    Time value = Time(hour: 12, minute: 00);

    if (selectedDate != null) {
      Navigator.of(context).push(
        showPicker(
          height: 350,
          is24HrFormat: true,
          accentColor: Theme.of(context).highlightColor,
          context: context,
          showSecondSelector: false,
          value: value,
          onChange: onTimeChanged,
          minuteInterval: TimePickerInterval.FIVE,
          okText: context.translate(Strings.ok),
          cancelText: context.translate(Strings.cancel),
        ),
      );
    }
  }
}

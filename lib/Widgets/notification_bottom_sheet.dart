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

  String _selectedNotificationType = Keys.fixed;
  String _selectedPeriodicInterval = Keys.daily; // Default
  Notifications? _currentPeriodicNotification;
  List<Notifications> _fixedNotifications = [];
  bool _isLoading = true;
  ToDoList? _currentList; // To store the fetched list

  @override
  void initState() {
    super.initState();
    _loadNotificationsData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        Duration(milliseconds: 400),
        () => ShowCaseHelper.instance.startShowCaseNotifications(
            context, [notificationsKey, notificationsStatusKey]),
      );
    });
  }

  Future<void> _loadNotificationsData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final listProvider = Provider.of<ListsProvider>(context, listen: false);
      _currentList = await listProvider.getListById(widget.listId);
      if (_currentList == null || !mounted) return;

      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      final allNotifications =
          await notificationProvider.getNotificationsByListId(widget.listId);

      List<Notifications> fixed = [];
      Notifications? periodic;

      for (var notif in allNotifications) {
        if (notif.notificationType == Keys.periodic) {
          periodic = notif;
        } else {
          // Treat null or Keys.fixed as fixed
          fixed.add(notif);
        }
      }
      fixed.sort((a, b) =>
          a.notificationDateTime.compareTo(b.notificationDateTime));

      if (!mounted) return;
      setState(() {
        _fixedNotifications = fixed;
        _currentPeriodicNotification = periodic;
        if (periodic != null) {
          _selectedNotificationType = Keys.periodic;
          if (periodic.periodicInterval == Keys.monthly) {
            // If old data has "monthly", default UI to "daily" as "monthly" is no longer an option.
            _selectedPeriodicInterval = Keys.daily;
          } else {
            _selectedPeriodicInterval = periodic.periodicInterval ?? Keys.daily;
          }
        } else {
          _selectedNotificationType = Keys.fixed;
          _selectedPeriodicInterval = Keys.daily; // Ensure default if no periodic
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Handle error, e.g., show a snackbar
        print("Error loading notifications: $e");
      }
    }
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
        height: MediaQuery.of(context).size.height * 0.5 + // Increased height slightly
            MediaQuery.of(context).viewInsets.bottom, // For keyboard
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // For keyboard
        child: _isLoading || _currentList == null
            ? const Center(child: CircularProgressIndicator())
            : Column( // Main content structure
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).highlightColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header (using the existing header but adapted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: header(_currentList!), // Pass the fetched list
                  ),
                  _buildNotificationTypeSelector(),
                  Expanded( // To make the content scrollable if it overflows
                    child: SingleChildScrollView(
                      child: _selectedNotificationType == Keys.periodic
                          ? _buildPeriodicSettingsSection(_currentList!)
                          : _buildFixedNotificationsSection(_currentList!),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ChoiceChip(
            label: Text(context.translate(Strings.fixed)),
            selected: _selectedNotificationType == Keys.fixed,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedNotificationType = Keys.fixed;
                });
              }
            },
            selectedColor: Theme.of(context).highlightColor.withOpacity(0.5),
            labelStyle: TextStyle(
              color: _selectedNotificationType == Keys.fixed
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          ChoiceChip(
            label: Text(context.translate(Strings.periodic)),
            selected: _selectedNotificationType == Keys.periodic,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedNotificationType = Keys.periodic;
                });
              }
            },
            selectedColor: Theme.of(context).highlightColor.withOpacity(0.5),
             labelStyle: TextStyle(
              color: _selectedNotificationType == Keys.periodic
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodicSettingsSection(ToDoList list) {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.translate(Strings.periodicSettings),
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(context.translate(Strings.interval), style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Centered chips
            children: [
              ChoiceChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Text(context.translate(Strings.daily)),
                ),
              selected: _selectedPeriodicInterval == Keys.daily,
              onSelected: (selected) {
                if (selected) setState(() => _selectedPeriodicInterval = Keys.daily);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: _selectedPeriodicInterval == Keys.daily
                    ? theme.colorScheme.onPrimaryContainer
                    : textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(width: 16), // Spacing between chips
            ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(context.translate(Strings.weekly)),
              ),
              selected: _selectedPeriodicInterval == Keys.weekly,
              onSelected: (selected) {
                if (selected) setState(() => _selectedPeriodicInterval = Keys.weekly);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: _selectedPeriodicInterval == Keys.weekly
                    ? theme.colorScheme.onPrimaryContainer
                    : textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_currentPeriodicNotification != null) ...[
          Text(context.translate(Strings.currentSetting), style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Card( // Using a Card for better visual grouping of current setting
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible( // To prevent overflow if text is long
                    child: Text(
                      "${context.translate(Strings.type)}: ${(_currentPeriodicNotification!.periodicInterval == Keys.monthly ? Keys.daily : _currentPeriodicNotification!.periodicInterval)?.capitalize() ?? ''}\n${context.translate(Strings.startingAnchorDate)}: ${DateFormat(context.translate(Strings.dateFormat)).format(_currentPeriodicNotification!.notificationDateTime)}",
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                    label: Text(
                      context.translate(Strings.remove),
                      style: TextStyle(color: theme.colorScheme.error)
                    ),
                    onPressed: () async {
                      await Provider.of<NotificationProvider>(context, listen: false)
                          .deleteNotification(_currentPeriodicNotification!, list);
                      _loadNotificationsData(); // Refresh
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity, // Make button full width
          child: ElevatedButton.icon(
            icon: Icon(_currentPeriodicNotification == null ? Icons.add_alarm_rounded : Icons.update_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                _currentPeriodicNotification == null
                  ? context.translate(Strings.setPeriodicReminder)
                  : context.translate(Strings.updatePeriodicReminder),
                style: textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)
              ),
            ),
            onPressed: list.isAchieved ? null : () async {
              DateTime anchorDate = DateTime.now();
              // Anchor date for periodic notifications is now always DateTime.now()
              // as per the current NotificationProvider logic for periodicallyShow.
              // The time component is taken from user preferences (_notificationTime) in the provider.

              await Provider.of<NotificationProvider>(context, listen: false)
                  .addNotification(
                      list,
                      anchorDate,
                      Strings.periodicReminder,
                      Keys.periodic,
                      _selectedPeriodicInterval);
              _loadNotificationsData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary, // For text and icon color
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        ),
        const SizedBox(height: 16), // Some bottom padding
      ],
    );
  }

  Widget _buildFixedNotificationsSection(ToDoList list) {
    if (_fixedNotifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Lottie.asset(
            Theme.of(context).brightness == Brightness.dark
                ? Keys.emptyNotificationsDark
                : Keys.emptyNotificationsLight,
            height: 150, // Adjust size as needed
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // If inside SingleChildScrollView
      itemCount: _fixedNotifications.length,
      itemBuilder: (context, index) {
        final notification = _fixedNotifications[index];
        // Use ShowCase only for the first item if needed
        if (index == 0 && ShowCaseHelper.instance.showShowCase) { // Check if showcase is active
          return ShowCaseHelper.instance.customShowCase(
            key: notificationsStatusKey, // Ensure this key is unique or managed
            description: context.translate(
                ShowCaseHelper.instance.notificationsStateShowCaseDescription),
            context: context,
            child: _buildNotificationItem(context, notification, list),
          );
        }
        return _buildNotificationItem(context, notification, list);
      },
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
          color: Theme.of(context).primaryColorDark.withOpacity(0.2),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      displayDuration: const Duration(seconds: 1, milliseconds: 500),
    );
  }

  Widget header(ToDoList list) { // Removed notificationsList from params, uses state now
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
        // Add button logic now depends on _selectedNotificationType
        _selectedNotificationType == Keys.fixed && (!list.isAchieved && _fixedNotifications.length < 4)
            ? IconButton(
                onPressed: () async {
                  DateTime? newTime = await _openDateTimePicker(context, list);
                  if (newTime != null) {
                    await Provider.of<NotificationProvider>(context, listen: false)
                        .addNotification(list, newTime, null, Keys.fixed, null);
                    _loadNotificationsData(); // Refresh
                  }
                },
                icon: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).dialogBackgroundColor,
                ),
              )
            : IconButton( // Disabled or different action for periodic / limit reached / achieved
                onPressed: () {
                  if (list.isAchieved) {
                    showPopup(context
                      .translate(Strings.youCantAddNotificationsToThisList));
                  } else if (_selectedNotificationType == Keys.fixed && _fixedNotifications.length >=4) {
                     showPopup(context
                      .translate(Strings.fixedNotificationsLimitReached));
                  }
                  // For periodic, the add button is within its own section.
                },
                icon: Icon(
                  Icons.add_rounded,
                  color: (_selectedNotificationType == Keys.fixed && !list.isAchieved && _fixedNotifications.length < 4)
                         ? Theme.of(context).dialogBackgroundColor
                         : Colors.grey,
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
            ? () async {
                await Provider.of<NotificationProvider>(context, listen: false)
                    .toggleNotificationDisabled(notification, list);
                _loadNotificationsData(); // Refresh
              }
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
                await Provider.of<NotificationProvider>(context, listen: false)
                    .editNotification(
                        notification.copyWith(notificationDateTime: newTime),
                        list);
                _loadNotificationsData(); // Refresh
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
          // Store details for potential undo before deleting
          final DateTime originalDateTime = notification.notificationDateTime;
          final String? originalType = notification.notificationType;
          final String? originalInterval = notification.periodicInterval;

          await notificationProvider.deleteNotification(notification, list);
          _loadNotificationsData(); // Refresh immediately

          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: context.translate(Strings.itemDeletedPressHereToUndo),
              backgroundColor: Theme.of(context).highlightColor,
              icon: Icon(
                Icons.warning_rounded,
                color: Theme.of(context).primaryColorDark.withOpacity(0.2),
                size: 120,
              ),
            ),
            onTap: () async {
              // Use stored details for undo
              await notificationProvider.addNotification(
                  list, originalDateTime, null, originalType ?? Keys.fixed, originalInterval);
              _loadNotificationsData(); // Refresh after undo
            },
            snackBarPosition: SnackBarPosition.bottom,
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
      {Notifications? notification, bool isPeriodic = false}) async { // Added isPeriodic flag
    late DateTime initialDateForDatePicker;
    late TimeOfDay initialTimeForTimePicker;

    if (notification == null || isPeriodic) {
      initialDateForDatePicker = DateTime.now();
      // Default to user's preference or current time for the time picker
      NotificationTime prefTime = NotificationTime.fromInt(
          await SharedPreferencesHelper.instance.getNotificationTime());
      initialTimeForTimePicker = TimeOfDay(hour: prefTime.hour, minute: prefTime.minute);
    } else { // Editing existing fixed notification
      initialDateForDatePicker = notification.notificationDateTime;
      initialTimeForTimePicker = TimeOfDay(hour: notification.notificationDateTime.hour, minute: notification.notificationDateTime.minute);
    }

    // Ensure initialDateForDatePicker is not before the first selectable date
    DateTime firstSelectableDate = DateTime.now();
    if (!isPeriodic && list.hasDeadline && list.deadline.isBefore(firstSelectableDate)) {
        firstSelectableDate = list.deadline;
    }
     if (initialDateForDatePicker.isBefore(firstSelectableDate)) {
      initialDateForDatePicker = firstSelectableDate;
    }

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDateForDatePicker,
      firstDate: firstSelectableDate,
      lastDate: list.hasDeadline && !isPeriodic
          ? list.deadline
          : DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate != null) {
      // Use the TimeOfDay for the 'value' parameter of showPicker
      final TimeOfDay? pickedTime = await Navigator.of(context).push<TimeOfDay?>(
        showPicker(
          context: context,
          value: initialTimeForTimePicker, // Pass TimeOfDay here
          is24HrFormat: true,
          accentColor: Theme.of(context).highlightColor,
          minuteInterval: TimePickerInterval.FIVE,
          okText: context.translate(Strings.ok),
          cancelText: context.translate(Strings.cancel),
          showSecondSelector: false,
          // onChange is optional if we use the returned value from push.
          // If used for live updates, ensure it handles TimeOfDay.
          // onChange: (newSelectedTime) { /* newSelectedTime is TimeOfDay */ },
        ),
      );

      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        // Ensure the selected date time is not in the past for fixed notifications.
        // For periodic, this check might be less strict as it's an anchor.
        if (!isPeriodic && finalDateTime.isBefore(DateTime.now())) {
          // Optionally, show a message or adjust.
          // For now, we allow it; addNotification will disable if it's still in the past.
        }
        return finalDateTime;
      }
    }
    return null;
  }
}

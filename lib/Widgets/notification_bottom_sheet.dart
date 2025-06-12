import 'package:day_night_time_picker/day_night_time_picker.dart';
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

  const NotificationBottomSheet({required this.listId, super.key});

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
        const Duration(milliseconds: 400),
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
      fixed.sort(
          (a, b) => a.notificationDateTime.compareTo(b.notificationDateTime));

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
          _selectedPeriodicInterval =
              Keys.daily; // Ensure default if no periodic
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
        height: MediaQuery.of(context).size.height *
                0.6 + // Increased height slightly
            MediaQuery.of(context).viewInsets.bottom, // For keyboard
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom), // For keyboard
        child: _isLoading || _currentList == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                // Main content structure
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).highlightColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header (using the existing header but adapted)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: header(_currentList!), // Pass the fetched list
                  ),
                  _buildNotificationTypeSelector(),
                  Expanded(
                    // To make the content scrollable if it overflows
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
      physics:
          const NeverScrollableScrollPhysics(), // If inside SingleChildScrollView
      itemCount: _fixedNotifications.length,
      itemBuilder: (context, index) {
        final notification = _fixedNotifications[index];
        // Use ShowCase only for the first item if needed
        if (index == 0 && ShowCaseHelper.instance.isActive) {
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
          color: Theme.of(context).primaryColorDark.withValues(alpha: 0.2),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.top,
      displayDuration: const Duration(seconds: 1, milliseconds: 500),
    );
  }

  Widget header(ToDoList list) {
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
        _selectedNotificationType == Keys.fixed &&
                (!list.isAchieved && _fixedNotifications.length < 4)
            ? IconButton(
                onPressed: () async {
                  try {
                    DateTime? newTime =
                        await _openDateTimePicker(context, list);
                    if (newTime != null) {
                      await Provider.of<NotificationProvider>(context,
                              listen: false)
                          .addNotification(
                              list, newTime, null, Keys.fixed, null);
                      _loadNotificationsData(); // Refresh
                    }
                  } catch (e) {
                    // Handle the error and show user feedback
                    String errorMessage;
                    if (e.toString().contains("Periodic notification exists")) {
                      errorMessage =
                          "Please delete the periodic notification first before adding fixed notifications";
                    } else if (e
                        .toString()
                        .contains("Fixed notifications limit reached")) {
                      errorMessage =
                          "You can only have up to 4 fixed notifications per list";
                    } else {
                      errorMessage =
                          "Failed to add notification. Please try again.";
                    }

                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.error(
                        message: errorMessage,
                        backgroundColor: Colors.red,
                        icon: Icon(
                          Icons.error_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 120,
                        ),
                      ),
                      snackBarPosition: SnackBarPosition.top,
                      displayDuration: const Duration(seconds: 2),
                    );

                    print("Error adding notification: $e");
                  }
                },
                icon: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).dialogBackgroundColor,
                ),
              )
            : IconButton(
                // Disabled or different action for periodic / limit reached / achieved
                onPressed: () {
                  String message;
                  if (list.isAchieved) {
                    message = context
                        .translate(Strings.youCantAddNotificationsToThisList);
                  } else if (_selectedNotificationType == Keys.fixed &&
                      _fixedNotifications.length >= 4) {
                    message =
                        "You can only have up to 4 fixed notifications per list";
                  } else if (_selectedNotificationType == Keys.periodic) {
                    message = "Use the button below to set periodic reminders";
                  } else {
                    message = "Cannot add notification at this time";
                  }

                  showPopup(message);
                },
                icon: Icon(
                  Icons.add_rounded,
                  color: (_selectedNotificationType == Keys.fixed &&
                          !list.isAchieved &&
                          _fixedNotifications.length < 4)
                      ? Theme.of(context).dialogBackgroundColor
                      : Colors.grey,
                ),
              ),
      ],
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
          // Interval selection - more compact
          Text(
            "interval" /*context.translate(Strings.interval)*/,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactIntervalChip(
                  label: "daily" /*context.translate(Strings.daily)*/,
                  icon: Icons.today_rounded,
                  isSelected: _selectedPeriodicInterval == Keys.daily,
                  onSelected: () =>
                      setState(() => _selectedPeriodicInterval = Keys.daily),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactIntervalChip(
                  label: "weekly" /*context.translate(Strings.weekly)*/,
                  icon: Icons.date_range_rounded,
                  isSelected: _selectedPeriodicInterval == Keys.weekly,
                  onSelected: () =>
                      setState(() => _selectedPeriodicInterval = Keys.weekly),
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current periodic notification as list item (if exists)
          if (_currentPeriodicNotification != null) ...[
            _buildPeriodicNotificationItem(
                context, _currentPeriodicNotification!, list),
            const SizedBox(height: 16),
          ],
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                _currentPeriodicNotification == null
                    ? Icons.add_alarm_rounded
                    : Icons.update_rounded,
                color: theme.colorScheme.onPrimary,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  _currentPeriodicNotification == null
                      ? "setPeriodicReminder" /*context.translate(Strings.setPeriodicReminder)*/
                      : "updatePeriodicReminder" /*context.translate(Strings.updatePeriodicReminder)*/,
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onPressed: list.isAchieved
                  ? null
                  : () async {
                      DateTime anchorDate = DateTime.now();
                      await Provider.of<NotificationProvider>(context,
                              listen: false)
                          .addNotification(
                              list,
                              anchorDate,
                              "periodicReminder" /*Strings.periodicReminder*/,
                              Keys.periodic,
                              _selectedPeriodicInterval);
                      _loadNotificationsData();
                    },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompactIntervalChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.highlightColor
              : theme.highlightColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? theme.highlightColor : theme.highlightColor
              ..withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : theme.highlightColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.highlightColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Periodic notification item (similar to regular but with periodic indicator)
  Widget _buildPeriodicNotificationItem(
      BuildContext context, Notifications notification, ToDoList list) {
    var dateFormatted = DateFormat(context.translate(Strings.dateFormat))
        .format(notification.notificationDateTime);
    final timeFormatted =
        DateFormat(Keys.timeFormat).format(notification.notificationDateTime);
    final intervalText = (notification.periodicInterval == Keys.monthly
            ? Keys.daily
            : notification.periodicInterval) ??
        Keys.daily;

    return ListTile(
      leading: Stack(
        children: [
          IconButton(
            onPressed: !list.isAchieved
                ? () async {
                    await Provider.of<NotificationProvider>(context,
                            listen: false)
                        .toggleNotificationDisabled(notification, list);
                    _loadNotificationsData();
                  }
                : null,
            icon: Icon(
              notification.disabled
                  ? Icons.notifications_off_rounded
                  : Icons.repeat_rounded, // Different icon for periodic
              color: notification.disabled
                  ? Theme.of(context).hintColor
                  : Theme.of(context).highlightColor,
            ),
          ),
        ],
      ),
      title: Text("${context.translate(Strings.date)}: $dateFormatted"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${context.translate(Strings.time)}: $timeFormatted"),
          Text(
            "Repeats: $intervalText",
            style: TextStyle(
              color: Theme.of(context).highlightColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_rounded,
          color: Theme.of(context).highlightColor,
        ),
        onPressed: () async {
          await Provider.of<NotificationProvider>(context, listen: false)
              .deleteNotification(notification, list);
          _loadNotificationsData();
        },
      ),
    );
  }

// Compact notification type selector
  Widget _buildNotificationTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).highlightColor..withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedNotificationType = Keys.fixed),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _selectedNotificationType == Keys.fixed
                      ? Theme.of(context).highlightColor
                      : Colors.transparent,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(8.0)),
                ),
                child: Text(
                  "Fixed",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedNotificationType == Keys.fixed
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).highlightColor..withValues(alpha: 0.2),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedNotificationType = Keys.periodic),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _selectedNotificationType == Keys.periodic
                      ? Theme.of(context).highlightColor
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8.0)),
                ),
                child: Text(
                  "Periodic",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedNotificationType == Keys.periodic
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        onPressed: !list.isAchieved && _currentPeriodicNotification == null
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
      onTap: !list.isAchieved && _currentPeriodicNotification == null
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
          : _currentPeriodicNotification != null
              ? () => showPopup(
                  "Fixed notifications can't activate when periodic notification is active")
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
                color: Theme.of(context).primaryColorDark
                  ..withValues(alpha: 0.2),
                size: 120,
              ),
            ),
            onTap: () async {
              // Use stored details for undo
              await notificationProvider.addNotification(list, originalDateTime,
                  null, originalType ?? Keys.fixed, originalInterval);
              _loadNotificationsData(); // Refresh after undo
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
      {Notifications? notification, bool isPeriodic = false}) async {
    // Added isPeriodic flag
    late DateTime initialDateForDatePicker;
    late TimeOfDay initialTimeForTimePicker;

    if (notification == null || isPeriodic) {
      initialDateForDatePicker = DateTime.now();
      // Default to user's preference or current time for the time picker
      NotificationTime prefTime = NotificationTime.fromInt(
          await SharedPreferencesHelper.instance.getNotificationTime());
      initialTimeForTimePicker =
          TimeOfDay(hour: prefTime.hour, minute: prefTime.minute);
    } else {
      // Editing existing fixed notification
      initialDateForDatePicker = notification.notificationDateTime;
      initialTimeForTimePicker = TimeOfDay(
          hour: notification.notificationDateTime.hour,
          minute: notification.notificationDateTime.minute);
    }

    // Ensure initialDateForDatePicker is not before the first selectable date
    DateTime firstSelectableDate = DateTime.now();
    if (!isPeriodic &&
        list.hasDeadline &&
        list.deadline.isBefore(firstSelectableDate)) {
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
      // Initialize with the current initial time
      TimeOfDay? pickedTime = initialTimeForTimePicker;

      // Show the time picker and wait for result
      final result = await Navigator.of(context).push(
        showPicker(
            backgroundColor: Theme.of(context).primaryColor,
            borderRadius: 30.0,
            height: 350,
            is24HrFormat: true,
            accentColor: Theme.of(context).highlightColor,
            context: context,
            showSecondSelector: false,
            value: Time(
                hour: initialTimeForTimePicker.hour,
                minute: initialTimeForTimePicker.minute),
            onChange: (newSelectedTime) {
              pickedTime = newSelectedTime;
            },
            minuteInterval: TimePickerInterval.FIVE,
            okText: context.translate(Strings.ok),
            cancelText: context.translate(Strings.cancel),
            blurredBackground: true),
      );

      // Check if user confirmed the time picker (didn't cancel)
      if (result != null && pickedTime != null) {
        DateTime finalDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          pickedTime!.hour,
          pickedTime!.minute,
        );
        if (!isPeriodic && finalDateTime.isBefore(DateTime.now())) {}
        return finalDateTime;
      }
    }
    return null;
  }
}

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  String translate(String text) {
    return AppLocalizations.of(this).translate(text);
  }
}

class Strings {
  // content screen
  static String addSomeContent = "Add some content";

  // home page
  static String activeLists = "Active Lists";
  static String archivedLists = "Archived Lists";
  static String withoutDeadline = "Without Deadline";
  static String settings = "Settings";
  static String theNotificationForThisListWasCanceled =
      "The notification for this list was canceled";
  static String creationDateNewestToOldest = "Creation Date: Newest to Oldest";
  static String creationDateOldestToNewest = "Creation Date: Oldest to Newest";
  static String deadlineLaterToSooner = "Deadline: Later to Sooner";
  static String deadlineSoonerToLater = "Deadline: Sooner to Later";
  static String progressHighToLow = "Progress: High to Low";
  static String progressLowToHigh = "Progress: Low to High";

  // single list screen
  static String scheduleNotification = "Schedule notification";
  static String notificationsUpdated = "Notifications updated";

  //statistics screen
  static String statistics = "Statistics";

  // errors
  static String errorHasOccurred = "Error has occurred";
  static String couldNotLaunch = "Could not launch";

  // date picker
  static String deadline = "Deadline:";

  // edit item title popup
  static String enterNewItemTitle = "Enter New Item Title";
  static String title = "Title";
  static String cancel = "Cancel";
  static String add = "Add";

  // list item tile
  static String confirmDeletion = "Confirm Deletion";
  static String areYouSureYouWantToDeleteThisItem =
      "Are you sure you want to delete this item?";
  static String delete = "Delete";
  static String done = "Done";
  static String today = "Today";
  static String remainingDays = "Remaining Days:";
  static String remainingHours = "Remaining Hours:";
  static String creationDate = "Creation Date: ";
  static String totalItems = "Total Items:";
  static String accomplishedItems = "Accomplished Items:";
  static String progress = "Progress:";

  // my bottom navigation bar
  static String enterListTitle = "Enter list title";
  static String checkForAddingDeadline = "Check for adding deadline";
  static String save = "Save";

  // settings widget
  static String allTheChangesWillTakeEffectFromNowOnOnly =
      "All the changes will take effect from now on only";
  static String chooseLanguage = "Choose language:";
  static String switchThemeMode = "Switch theme mode:";
  static String dark = "Dark";
  static String automatic = "Automatic";
  static String light = "Light";
  static String enableNotifications = "Enable notifications:";
  static String chooseDefaultTimeForNotification =
      "Choose default time for notification:";
  static String ok = "OK";
  static String chooseTime = "Choose time";

  // statistics graphs
  static String listData = "List Data:";
  static String noData = "No Data";
  static String itemsData = "Items Data";
  static String itemsDone = "Items Done";
  static String itemsDelayed = "Items delayed";
  static String itemsInProcess = "Items In Process";

  // to do item widget
  static String itemDeletedPressHereToUndo = "Item deleted press here to undo";

  //notifications provider
  static String hurryUpTomorrowsDeadline = "Hurry up! Tomorrow's Deadline!";
  static String reminderTomorrowsTheDeadline =
      "⏰ Reminder: Tomorrow's the Deadline!";
  static String finalCallTaskDueTomorrow = "Final Call: Task Due Tomorrow!";
  static String deadlineAlertDueTomorrow = "Deadline Alert: Due Tomorrow!";
  static String timesRunningOutDueTomorrow =
      "Time's Running Out: Due Tomorrow!";
  static String dontForgetDueTomorrow = "Don't Forget: Due Tomorrow!";
  static String lastDayReminderDueTomorrow = "Last Day Reminder: Due Tomorrow!";
  static String actNowTomorrowsDeadline = "Act Now: Tomorrow's Deadline!";
  static String urgentReminderDueTomorrow = "Urgent Reminder: Due Tomorrow!";
  static String justOneDayLeftDeadlineTomorrow =
      "Just One Day Left: Deadline Tomorrow!";
}

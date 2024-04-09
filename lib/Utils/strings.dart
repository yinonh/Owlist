import 'package:flutter/material.dart';

import '../Utils/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  String translate(String text) {
    return AppLocalizations.of(this).translate(text);
  }
}

class Strings {
  // Content screen
  static String addSomeContent = "Add some content";

  // Home page
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

  // Single list screen
  static String scheduleNotification = "Schedule notification";
  static String notificationsUpdated = "Notifications updated";

  // Statistics screen
  static String statistics = "Statistics";

  // Errors
  static String errorHasOccurred = "Error has occurred";
  static String couldNotLaunch = "Could not launch";

  // Date picker
  static String deadline = "Deadline:";

  // Edit item title popup
  static String enterNewItemTitle = "Enter New Item Title";
  static String title = "Title";
  static String cancel = "Cancel";
  static String add = "Add";

  // List item tile
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
  static String editList = "Edit list";
  static String thereIsNoDeadline = "There is no deadline";

  // My bottom navigation bar
  static String enterListTitle = "Enter list title";
  static String checkForAddingDeadline = "Check for adding deadline";
  static String save = "Save";
  static String listMustHaveTitle = "List must have a title";

  // Settings widget
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
  static String setReminderDayBeforeDeadline =
      "Set a reminder one day before the deadline";

  // Statistics graphs
  static String listData = "List Data:";
  static String noData = "No Data";
  static String itemsData = "Items Data";
  static String itemsDone = "Items Done";
  static String itemsDelayed = "Items delayed";
  static String itemsInProcess = "Items In Process";

  // To do item widget
  static String itemDeletedPressHereToUndo = "Item deleted press here to undo";

  // Notifications provider
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

  // Notifications Bottom Sheet
  static String notifications = "Notifications";
  static String date = "Date";
  static String time = "Time";
  static String youCantAddNotificationsToThisList =
      "You can't add notifications to this list";

  // ShowCase Helper
  static String homePageShowCaseDescription = "Home page show case description";
  static String singleListScreenEditListShowCaseDescription =
      "Single list screen edit list show case description";
  static String singleListScreenAddItemShowCaseDescription =
      "Single list screen add item show case description";
  static String notificationsShowCaseDescription =
      "Notifications show case description";
  static String notificationsStateShowCaseDescription =
      "Notifications state show case description";
  static String contentShowCaseDescription = "Content show case description";
}

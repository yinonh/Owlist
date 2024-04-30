final class Keys {
  // Common keys
  static const String id = 'id';
  static const String emptyChar = '';
  static const String filterFormat = r'\n';

  // db table
  static const String toDoTable = 'to_do.db';

  // Notifications
  static const String notificationIndex = 'notificationIndex';
  static const String notificationDateTime = 'notificationDateTime';
  static const String disabled = 'disabled';
  static const String notificationDateTimeFormat = 'yyyy-MM-dd HH:mm';

  // To do list
  static const String listId = 'listId';
  static const String userID = 'userID';
  static const String hasDeadline = 'hasDeadline';
  static const String title = 'title';
  static const String creationDate = 'creationDate';
  static const String deadline = 'deadline';
  static const String totalItems = 'totalItems';
  static const String accomplishedItems = 'accomplishedItems';
  static const String listDateFormat = 'yyyy-MM-dd';

  // To do item
  static const String content = 'content';
  static const String done = 'done';
  static const String itemIndex = 'itemIndex';

  // List provider
  static const String totalLists = 'totalLists';
  static const String listsDone = 'listsDone';
  static const String activeLists = 'activeLists';
  static const String withoutDeadline = 'withoutDeadline';
  static const String itemsDone = 'itemsDone';
  static const String itemsDelayed = 'itemsDelayed';
  static const String itemsNotDone = 'itemsNotDone';

  // Notifications provider
  static const String appIcon = '@mipmap/ic_launcher';
  static const String mainChannelId = 'main_channel_id';
  static const String mainChannelName = 'Deadline notifications';
  static const String mainChannelDescription = 'Notification for the lists';

  // Rout Names
  static const String contentScreenRouteName = '/content';
  static const String homePageRouteName = '/home_page';
  static const String singleListScreenRouteName = '/single_list_screen';
  static const String statisticsScreenRouteName = '/statistics';

  // Assets
  static const String appNameSvg = 'Assets/appName.svg';
  static const String emptyNotificationsDark =
      'Assets/empty notifications dark.json';
  static const String emptyNotificationsLight =
      'Assets/empty notifications light.json';

  // Languages
  static const String english = "English";
  static const String hebrew = "עברית";
  static const String french = "française";

  // Unicorn button
  static const String addTextHeroTag = 'Text';
  static const String addNotificationsHeroTag = 'Notification';
  static const String parentHeroTag = 'Parent';

  // Shared preferences
  static const String selectedLanguage = 'selectedLanguage';
  static const String selectedTheme = 'selectedTheme';
  static const String darkTheme = 'dark';
  static const String lightTheme = 'light';
  static const String notificationActive = 'notificationActive';
  static const String notificationTime = 'notification_time';
  static const String autoNotification = 'auto_notification';
  static const String sortByIndex = 'sortByIndex';

  // Notification bottom sheet
  static const String timeFormat = 'HH:mm';
}

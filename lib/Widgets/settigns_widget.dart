import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'package:app_settings/app_settings.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Providers/notification_provider.dart';
import '../Screens/statistics_screen.dart';
import '../Utils/context_extensions.dart';
import '../Utils/keys.dart';
import '../Utils/notification_time.dart';
import '../Utils/shared_preferences_helper.dart';
import '../Utils/show_case_helper.dart';
import '../Utils/strings.dart';
import '../main.dart';

class Settings extends StatefulWidget {
  final Function refresh;

  const Settings({required this.refresh, Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String? _selectedLanguages = "en";
  late NotificationProvider notificationProvider;
  late NotificationTime _time;
  late bool _notificationsActive;
  late bool _autoNotificationsActive;
  Map<String, String> languages = {
    "en": Keys.english,
    "zh": Keys.mandarin,
    "hi": Keys.hindi,
    "es": Keys.spanish,
    "he": Keys.hebrew,
    "fr": Keys.french,
    "ru": Keys.russian,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSharedPreferences();
    notificationProvider = Provider.of<NotificationProvider>(context);
    _time = notificationProvider.notificationTime;
    _notificationsActive = SharedPreferencesHelper.instance.notificationsActive;
    _autoNotificationsActive = notificationProvider.autoNotification;
  }

  Future<void> _loadSharedPreferences() async {
    String selectedLanguage =
        SharedPreferencesHelper.instance.selectedLanguage ??
            Localizations.localeOf(context).languageCode;

    setState(() {
      _selectedLanguages = selectedLanguage;
    });
  }

  void onTimeChanged(Time originalTime) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message:
            context.translate(Strings.allTheChangesWillTakeEffectFromNowOnOnly),
        backgroundColor: Theme.of(context).highlightColor,
        icon: Icon(
          Icons.warning_rounded,
          color: Theme.of(context).primaryColorDark.withOpacity(0.2),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 80,
      ),
      displayDuration: const Duration(seconds: 2),
    );

    NotificationTime newTime = NotificationTime(
      hour: originalTime.hour,
      minute: originalTime.minute,
    );
    Provider.of<NotificationProvider>(context, listen: false)
        .saveNotificationTimeToPrefs(newTime);
  }

  Future<String> writeImageToStorage(Uint8List feedbackScreenshot) async {
    final Directory output = await getTemporaryDirectory();
    final String screenshotFilePath = '${output.path}/feedback.png';
    final File screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(feedbackScreenshot);
    return screenshotFilePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                context.translate(Strings.settings),
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        context.translate(Strings.chooseLanguage),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Theme.of(context).primaryColorDark,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            DropdownButtonHideUnderline(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: DropdownButton<String>(
                                  value: _selectedLanguages,
                                  isExpanded: false,
                                  borderRadius: BorderRadius.circular(10.0),
                                  dropdownColor:
                                      Theme.of(context).primaryColorDark,
                                  onChanged: (String? newValue) async {
                                    if (newValue == null) return;
                                    setState(() {
                                      _selectedLanguages = newValue;
                                    });

                                    SharedPreferencesHelper
                                        .instance.selectedLanguage = newValue;

                                    Locale newLocale = Locale(newValue);
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      OwlistApp.setLocale(context, newLocale);
                                    });
                                  },
                                  items: languages.entries.map(
                                    (entry) {
                                      String languageCode = entry.key;
                                      String languageName = entry.value;
                                      return DropdownMenuItem(
                                        value: languageCode,
                                        child: Text(
                                          languageName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: Text(
                    context.translate(Strings.switchThemeMode),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Column(
                  children: [
                    ToggleSwitch(
                      initialLabelIndex: OwlistApp.themeMode(context),
                      minWidth: MediaQuery.of(context).size.width - 20,
                      totalSwitches: 3,
                      customIcons: [
                        Icon(Icons.dark_mode_rounded),
                        Icon(Icons.autorenew_rounded),
                        Icon(Icons.light_mode_rounded)
                      ],
                      customTextStyles: [TextStyle(color: Colors.white)],
                      activeBgColors: const [
                        [Color(0xFF251D43)],
                        [Color(0xFF635985)],
                        [Color(0xFF9685D9)]
                      ],
                      inactiveBgColor: Theme.of(context).primaryColorDark,
                      animate: true,
                      curve: Curves.easeInQuad,
                      centerText: true,
                      onToggle: (index) {
                        switch (index) {
                          case 0:
                            SharedPreferencesHelper.instance.selectedTheme =
                                Keys.darkTheme;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              OwlistApp.setTheme(context, Keys.darkTheme);
                            });
                            break;
                          case 1:
                            SharedPreferencesHelper.instance
                                .removeSelectedTheme();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              OwlistApp.setTheme(context, null);
                            });
                            break;
                          case 2:
                            SharedPreferencesHelper.instance.selectedTheme =
                                Keys.lightTheme;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              OwlistApp.setTheme(context, Keys.lightTheme);
                            });
                            break;
                        }
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 56),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.translate(Strings.dark),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            context.translate(Strings.automatic),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            context.translate(Strings.light),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            context.translate(Strings.enableNotifications),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Transform.scale(
                          scale: 1,
                          child: Switch(
                            onChanged: (val) async {
                              if (val) {
                                if (await Permission.notification.request() ==
                                    PermissionStatus.permanentlyDenied) {
                                  AppSettings.openAppSettings(
                                      type: AppSettingsType.notification);
                                  return;
                                } else {
                                  await notificationProvider
                                      .requestPermissions(true);
                                  if (!await notificationProvider
                                      .isAndroidPermissionGranted()) {
                                    return;
                                  }
                                }
                              }
                              notificationProvider.saveActive(val);
                              setState(() {
                                ShowCaseHelper.instance.toggleIsActive(false);
                                widget.refresh();
                              });
                            },
                            value: _notificationsActive,
                            trackColor: WidgetStateProperty.all<Color>(
                                _notificationsActive
                                    ? Theme.of(context).primaryColorLight
                                    : Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context
                              .translate(Strings.setReminderDayBeforeDeadline),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Transform.scale(
                        scale: 1,
                        child: Switch(
                          onChanged: (val) {
                            notificationProvider.saveAutoNotification(val);
                          },
                          value:
                              _notificationsActive && _autoNotificationsActive,
                          trackColor: WidgetStateProperty.all<Color>(
                              _notificationsActive && _autoNotificationsActive
                                  ? Theme.of(context).primaryColorLight
                                  : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.translate(
                              Strings.chooseDefaultTimeForNotification),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Transform.scale(
                        scale: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: ElevatedButton(
                            onPressed: _notificationsActive &&
                                    _autoNotificationsActive
                                ? () {
                                    Navigator.of(context).push(
                                      showPicker(
                                          height: 350,
                                          is24HrFormat: true,
                                          accentColor:
                                              Theme.of(context).highlightColor,
                                          context: context,
                                          showSecondSelector: false,
                                          value: _time,
                                          onChange: onTimeChanged,
                                          minuteInterval:
                                              TimePickerInterval.FIVE,
                                          okText: context.translate(Strings.ok),
                                          cancelText:
                                              context.translate(Strings.cancel),
                                          blurredBackground: true),
                                    );
                                  }
                                : null,
                            child: Text(
                              context.translate(Strings.chooseTime),
                              style: _notificationsActive &&
                                      _autoNotificationsActive
                                  ? Theme.of(context)
                                      .primaryTextTheme
                                      .titleMedium!
                                      .copyWith(color: Colors.white)
                                  : Theme.of(context)
                                      .primaryTextTheme
                                      .titleMedium!
                                      .copyWith(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(StatisticsScreen.routeName);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            context.translate(Strings.statistics),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .titleMedium!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          BetterFeedback.of(context).show((feedback) async {
                            // draft an email and send to developer
                            final screenshotFilePath =
                                await writeImageToStorage(feedback.screenshot);

                            final Email email = Email(
                              body: feedback.text,
                              subject: 'Owlist Feedback',
                              recipients: ['yinon.h21+owlist@gmail.com'],
                              attachmentPaths: [screenshotFilePath],
                              isHTML: false,
                            );
                            await FlutterEmailSender.send(email);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            context.translate(Strings.sendFeedback),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .titleMedium!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

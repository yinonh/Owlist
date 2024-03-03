import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:to_do/Providers/notification_provider.dart';
import 'package:to_do/Screens/statistics_screen.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:to_do/Utils/strings.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../Utils/shared_preferences_helper.dart';
import '../main.dart';
import '../Utils/notification_time.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<bool> _selectedLanguages = [true, false];
  late NotificationProvider notificationProvider;
  late NotificationTime _time;
  late bool _notificationsActive;
  List<Widget> languages = <Widget>[
    SvgPicture.asset(
      'Assets/english.svg',
      width: 60,
      // height: 45,
    ),
    SvgPicture.asset(
      'Assets/hebrew.svg',
      width: 60,
      // height: 45,
    )
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSharedPreferences();
    notificationProvider = Provider.of<NotificationProvider>(context);
    _time = notificationProvider.notificationTime;
    _notificationsActive = notificationProvider.isActive;
  }

  Future<void> _loadSharedPreferences() async {
    String selectedLanguage =
        SharedPreferencesHelper.instance.selectedLanguage ??
            Localizations.localeOf(context).languageCode;

    setState(() {
      _selectedLanguages =
          selectedLanguage == 'he' ? [false, true] : [true, false];
    });
  }

  void onTimeChanged(Time originalTime) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message:
            context.translate(Strings.allTheChangesWillTakeEffectFromNowOnOnly),
        backgroundColor: Theme.of(context).highlightColor,
        icon: const Icon(
          Icons.warning,
          color: Color(0x15000000),
          size: 120,
        ),
      ),
      snackBarPosition: SnackBarPosition.bottom,
      displayDuration: const Duration(seconds: 2),
    );

    NotificationTime newTime = NotificationTime(
      hour: originalTime.hour,
      minute: originalTime.minute,
      second: 0,
    );
    Provider.of<NotificationProvider>(context, listen: false)
        .saveNotificationTimeToPrefs(newTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.translate(Strings.chooseLanguage),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: ToggleButtons(
                  onPressed: (int index) async {
                    setState(() {
                      _selectedLanguages = List.generate(
                          _selectedLanguages.length, (i) => i == index);
                    });

                    String newLanguageCode = index == 0 ? 'en' : 'he';
                    SharedPreferencesHelper.instance.selectedLanguage =
                        newLanguageCode;

                    Locale newLocale = Locale(newLanguageCode);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      OwlistApp.setLocale(context, newLocale);
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedColor: Theme.of(context).primaryColor,
                  fillColor: Theme.of(context).primaryColorLight,
                  constraints: const BoxConstraints(
                    minHeight: 40.0,
                    minWidth: 80.0,
                  ),
                  isSelected: _selectedLanguages,
                  children: languages,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  Icon(Icons.dark_mode),
                  Icon(Icons.autorenew),
                  Icon(Icons.light_mode)
                ],
                customTextStyles: [TextStyle(color: Colors.white)],
                activeBgColors: const [
                  [Color(0xFF38305B)],
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
                      SharedPreferencesHelper.instance.selectedTheme = "dark";
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        OwlistApp.setTheme(context, "dark");
                      });
                      break;
                    case 1:
                      SharedPreferencesHelper.instance.removeSelectedTheme();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        OwlistApp.setTheme(context, null);
                      });
                      break;
                    case 2:
                      SharedPreferencesHelper.instance.selectedTheme = "light";
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        OwlistApp.setTheme(context, "light");
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
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      context.translate(Strings.automatic),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      context.translate(Strings.light),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  ],
                ),
              )
            ],
          ),
          //   ],
          // ),
          const SizedBox(
            height: 25,
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.translate(Strings.enableNotifications),
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
                      notificationProvider.saveActive(val);
                    },
                    value: _notificationsActive,
                    trackColor: MaterialStateProperty.all<Color>(
                        _notificationsActive
                            ? Theme.of(context).primaryColorLight
                            : Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 25,
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.translate(Strings.chooseDefaultTimeForNotification),
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
                      onPressed: _notificationsActive
                          ? () {
                              Navigator.of(context).push(
                                showPicker(
                                  height: 350,
                                  is24HrFormat: true,
                                  accentColor: Theme.of(context).highlightColor,
                                  context: context,
                                  showSecondSelector: false,
                                  value: _time,
                                  onChange: onTimeChanged,
                                  minuteInterval: TimePickerInterval.FIVE,
                                  okText: context.translate(Strings.ok),
                                  cancelText: context.translate(Strings.cancel),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        context.translate(Strings.chooseTime),
                        style: _notificationsActive
                            ? Theme.of(context)
                                .primaryTextTheme
                                .titleMedium!
                                .copyWith(color: Colors.white)
                            : Theme.of(context)
                                .primaryTextTheme
                                .titleMedium!
                                .copyWith(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 25,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(StatisticsScreen.routeName);
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  context.translate(Strings.statistics),
                  style: Theme.of(context)
                      .primaryTextTheme
                      .titleMedium!
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
        ],
      ),
    );
  }
}

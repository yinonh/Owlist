import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../l10n/app_localizations.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<bool> _selectedLanguages = [true, false];
  List<Widget> languages = <Widget>[
    Image.asset(
      'Assets/english.png',
      width: 45,
      height: 45,
    ),
    Image.asset(
      'Assets/israel.png',
      width: 45,
      height: 45,
    )
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String selectedLanguage = prefs.getString('selectedLanguage') ?? 'en';

    setState(() {
      _selectedLanguages =
          selectedLanguage == 'en' ? [true, false] : [false, true];
    });
  }

  Future<void> _saveSelectedLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context).translate("Choose language:"),
                    style: TextStyle(
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
                    await _saveSelectedLanguage(newLanguageCode);

                    Locale newLocale = Locale(newLanguageCode);
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      MyApp.setLocale(context, newLocale);
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
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Switch to ${MyApp.isDark(context) ? "light" : "dark"} mode: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Transform.scale(
                  scale: 1.5,
                  child: Switch(
                    activeThumbImage: AssetImage('Assets/lightMode.png'),
                    inactiveThumbImage: AssetImage('Assets/darkMode.png'),
                    onChanged: (mode) async {
                      WidgetsBinding.instance!.addPostFrameCallback((_) {
                        MyApp.setTheme(context);
                      });
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setString(
                          'selectedTheme', mode ? "dark" : "light");
                    },
                    value: MyApp.isDark(context),

                    // child: Text('Switch Theme'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

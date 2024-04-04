import 'dart:ui';

import 'package:bluetooth_app/shareddata.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_app/main.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({super.key, required this.onChangeIndex});
  final Function(int) onChangeIndex;

  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> with AutomaticKeepAliveClientMixin<MySettingsPage> {
  List<bool> _selected = [true];

  String get currentTheme => _selected[0] ? "Dark Mode" : "Light Mode";

  IconData get currentIcon => _selected[0] ? Icons.dark_mode : Icons.light_mode;

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey modeKey = GlobalKey();
  bool _isThemeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure the theme is initialized only once
    if (!_isThemeInitialized) {
      // Access the theme and create tutorial only when dependencies change
      createTutorial();
      _isThemeInitialized = true;
    }
  }

  void showTutorial(BuildContext context) {
    tutorialCoachMark.show(context: context);
  }

  void createTutorial() {
    ThemeData theme = Theme.of(context);
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(theme),
      colorShadow: Theme.of(context).shadowColor,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onSkip: () {
        return true;
      },
    );
  }

  List<TargetFocus> _createTargets(ThemeData theme) {
    List<TargetFocus> targets = [];

    targets.add(TargetFocus(
      identify: "Theme Button",
      keyTarget: modeKey,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Dark / Light Mode Button",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Click here to toggle between dark and light mode.",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));

    return targets;
  }

  @override
  void initState() {
    super.initState();
    _initializeSelected();
  }

  Future<void> _initializeSelected() async {
    await Future.delayed(Duration.zero);

    setState(() {
      _selected = [MediaQuery.of(context).platformBrightness == Brightness.dark];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Invoke the overridden method

    final ThemeData theme = Theme.of(context);
    final readTheme = context.read<ThemeFlip>();
    final watchBLE = context.watch<SharedBluetoothData>();

    if (watchBLE.showTutorial[4]) {
      showTutorial(context);
      watchBLE.showTutorial[4] = false;
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'Mode: $currentTheme',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ),
                    ToggleButtons(
                      key: modeKey,
                      isSelected: _selected,
                      onPressed: (int index) {
                        setState(() {
                          _selected[index] = !_selected[index];
                          readTheme.toggleTheme();
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      children: [
                        Icon(currentIcon),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

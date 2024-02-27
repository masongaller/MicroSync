import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluetooth_app/main.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({super.key});

  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage>
    with AutomaticKeepAliveClientMixin<MySettingsPage> {
  List<bool> _selected = [true];

  String get currentTheme => _selected[0] ? "Dark Mode" : "Light Mode";

  IconData get currentIcon => _selected[0] ? Icons.dark_mode : Icons.light_mode;

  @override
  void initState() {
    super.initState();
    _initializeSelected();
  }

  Future<void> _initializeSelected() async {
    await Future.delayed(Duration.zero);

    setState(() {
      _selected = [
        MediaQuery.of(context).platformBrightness == Brightness.dark
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final readTheme = context.read<ThemeFlip>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

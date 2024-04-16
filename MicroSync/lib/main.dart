import 'package:micro_sync/shareddata.dart';
import 'package:micro_sync/welcome.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeFlip()),
        ChangeNotifierProvider(create: (context) => SharedBluetoothData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final _defaultDarkColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple, brightness: Brightness.dark);
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.indigo, brightness: Brightness.light);

  @override
  Widget build(BuildContext context) {
    final watchTheme = context.watch<ThemeFlip>();
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
        themeMode: watchTheme.themeMode,
        home: const WelcomeScreen(),
      );
    });
  }
}

class ThemeFlip extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(darkModeBool) {
    _themeMode = darkModeBool ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}


//https://www.youtube.com/watch?v=bu_s2sviuck
//Onboarding page tutorial
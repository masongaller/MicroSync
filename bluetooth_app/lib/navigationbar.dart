import 'package:bluetooth_app/data.dart';
import 'package:bluetooth_app/home.dart';
import 'package:bluetooth_app/saved.dart';
import 'package:bluetooth_app/settings.dart';
import 'package:flutter/material.dart';

class MyNavigationBar extends StatefulWidget {
  const MyNavigationBar({super.key});

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  int currentPageIndex = 2;
  String appBarTitle = "Connect";
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(appBarTitle),
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: _onDestinationSelected,
        indicatorColor: theme.colorScheme.inversePrimary,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
              selectedIcon: Icon(Icons.analytics),
              icon: Icon(Icons.analytics_outlined),
              label: "Data"),
          NavigationDestination(
              selectedIcon: Icon(Icons.abc),
              icon: Icon(Icons.abc),
              label: "Place Holder"),
          NavigationDestination(
            selectedIcon: Icon(Icons.bluetooth),
            icon: Icon(Icons.bluetooth_outlined),
            label: 'Connect',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.bookmark),
            icon: Icon(Icons.bookmark_outline),
            label: 'Saved',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          MyDataPage(),
          MySavedPage(),
          MyHomePage(),
          MySavedPage(),
          MySettingsPage(),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      currentPageIndex = index;
      _pageController.jumpToPage(index);
      appBarTitle = _getAppBarTitle(index);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Data';
      case 1:
        return 'Place Holder';
      case 2:
        return 'Connect';
      case 3:
        return 'Saved';
      case 4:
        return 'Settings';
      default:
        return '';
    }
  }
}

import 'package:bluetooth_app/graph.dart';
import 'package:bluetooth_app/home.dart';
import 'package:bluetooth_app/saved.dart';
import 'package:bluetooth_app/settings.dart';
import 'package:bluetooth_app/shareddata.dart';
import 'package:bluetooth_app/table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyNavigationBar extends StatefulWidget {
  const MyNavigationBar({super.key});

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  int currentPageIndex = 2;
  String appBarTitle = "Connect";
  final PageController _pageController = PageController(initialPage: 2);

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
              label: "Graph"),
          NavigationDestination(
              selectedIcon: Icon(Icons.table_rows),
              icon: Icon(Icons.table_rows_outlined),
              label: "Table"),
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
      body: ChangeNotifierProvider(
        create: (context) => SharedData(),
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: const [
            MyDataPage(),
            MyTablePage(),
            MyHomePage(),
            MySavedPage(),
            MySettingsPage(),
          ],
        ),
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
        return 'Graph';
      case 1:
        return 'Table';
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

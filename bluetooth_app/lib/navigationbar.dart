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

    List<Widget> buildAppBarActions(int currentIndex) {
      if (currentIndex == 0 || currentIndex == 1) {
        return [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share') {
                context.read<SharedBluetoothData>().exportViaCSV();
              } else if (value == 'refresh') {
                context.read<SharedBluetoothData>().refreshData();
              } else if (value == 'delete') {
                context.read<SharedBluetoothData>().sendErase();
              } else if (value == 'save') {
                if (context.read<SharedBluetoothData>().fullHeaders.isNotEmpty) {
                  context.read<SharedBluetoothData>().promptFileName(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.error, color: theme.colorScheme.error),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No Data to Save!',
                                style: TextStyle(
                                  color: theme.snackBarTheme.actionTextColor,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.error, color: theme.colorScheme.error),
                        ],
                      ),
                      backgroundColor: theme.snackBarTheme.backgroundColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text('Refresh'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'save',
                  child: ListTile(
                    leading: Icon(Icons.save_alt),
                    title: Text('Save'),
                  ),
                ),
              ];
            },
          ),
        ];
      }
      return [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        actions: buildAppBarActions(currentPageIndex),
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: _onDestinationSelected,
        selectedIndex: currentPageIndex,
        backgroundColor: theme.primaryColor,
        elevation: 0,
        destinations: const <Widget>[
          NavigationDestination(
              selectedIcon: Icon(Icons.analytics), icon: Icon(Icons.analytics_outlined), label: "Graph"),
          NavigationDestination(
              selectedIcon: Icon(Icons.table_rows), icon: Icon(Icons.table_rows_outlined), label: "Table"),
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
        children: [
          const MyDataPage(),
          const MyTablePage(),
          const MyHomePage(),
          MySavedPage(onChangeIndex: _onDestinationSelected),
          const MySettingsPage(),
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

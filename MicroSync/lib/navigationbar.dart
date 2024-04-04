import 'package:micro_sync/graph.dart';
import 'package:micro_sync/home.dart';
import 'package:micro_sync/saved.dart';
import 'package:micro_sync/settings.dart';
import 'package:micro_sync/shareddata.dart';
import 'package:micro_sync/table.dart';
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

  // Define a map to store help messages based on index
  final Map<int, String> helpMessages = {
    0: 'Help message for Graph',
    1: 'Help message for Table',
    2: 'Help message for Connect',
    3: 'Help message for Saved',
    4: 'Help message for Settings',
  };

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
                if (context.read<SharedBluetoothData>().openedFile != null) {
                  context.read<SharedBluetoothData>().promptRefresh(context);
                } else {
                  context.read<SharedBluetoothData>().refreshData();
                }
              } else if (value == 'delete') {
                if (context.read<SharedBluetoothData>().openedFile != null) {
                  context.read<SharedBluetoothData>().promptDeleteFile(context);
                } else {
                  context.read<SharedBluetoothData>().sendErase();
                }
              } else if (value == 'save') {
                if (context.read<SharedBluetoothData>().fullHeaders.isNotEmpty) {
                  if (context.read<SharedBluetoothData>().openedFile != null) {
                    context.read<SharedBluetoothData>().promptOverwriteFile(context);
                  } else {
                    context.read<SharedBluetoothData>().promptFileName(context);
                  }
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
              } else if (value == 'unload') {
                if (context.read<SharedBluetoothData>().openedFile != null) {
                  context.read<SharedBluetoothData>().unloadFile();
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
                                'No Data to Unload!',
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
                    title: Text('Refetch Data'),
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
                const PopupMenuItem<String>(
                  value: 'unload',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_remove_rounded),
                    title: Text('Unload File'),
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
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            switch (currentPageIndex) {
              case 0:
              case 1:
                if (context.read<SharedBluetoothData>().rows.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please Connect to the Microbit on the Connect Page to Fetch Data!'),
                      duration: const Duration(seconds: 5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  setState(() {
                    context.read<SharedBluetoothData>().showTutorial[currentPageIndex] = true;
                  });
                }
                break;
              default:
                setState(() {
                    context.read<SharedBluetoothData>().showTutorial[currentPageIndex] = true;
                  });
            }
          },
        ),
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
          MyDataPage(onChangeIndex: _onDestinationSelected),
          MyTablePage(onChangeIndex: _onDestinationSelected),
          MyHomePage(onChangeIndex: _onDestinationSelected),
          MySavedPage(onChangeIndex: _onDestinationSelected),
          MySettingsPage(onChangeIndex: _onDestinationSelected),
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

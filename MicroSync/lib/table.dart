import 'dart:ui';
import 'package:micro_sync/shareddata.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MyTablePage extends StatefulWidget {
  const MyTablePage({Key? key, required this.onChangeIndex}) : super(key: key);
  final Function(int) onChangeIndex;

  @override
  State<MyTablePage> createState() => _MyTablePageState();
}

class _MyTablePageState extends State<MyTablePage> with AutomaticKeepAliveClientMixin<MyTablePage> {
  bool initOnce = true;
  List<bool> sortAscending = [];
  List<double> columnWidths = []; // List to store calculated column widths

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey keyColumnCollapse = GlobalKey();
  bool _isThemeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isThemeInitialized) {
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
      identify: "Sort",
      keyTarget: keyColumnCollapse,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Sort Button",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Clicking here will allow you to sort by the given column.",
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
  Widget build(BuildContext context) {
    super.build(context);

    final watchPoints = context.watch<SharedBluetoothData>();
    final readPoints = context.read<SharedBluetoothData>();
    double columnWidthTotal = 0;

    if (watchPoints.fullHeaders.isNotEmpty) {
      if (initOnce || sortAscending.length != watchPoints.headers.length) {
        initOnce = false;
        sortAscending = List.generate(watchPoints.headers.length, (index) => true);
        columnWidths = List.generate(watchPoints.headers.length, (index) {
          // Calculate width required for each header text
          final headerText = watchPoints.headers[index];
          final textWidth = TextPainter(
            text: TextSpan(text: headerText, style: const TextStyle(fontStyle: FontStyle.italic)),
            textDirection: TextDirection.ltr,
          )..layout();
          columnWidthTotal += textWidth.width * 2; // Add width required for each header text
          return textWidth.width * 2; // Return the width required for the header text
        });
      }

      if (watchPoints.showTutorial[1]) {
        showTutorial(context);
        watchPoints.showTutorial[1] = false;
      }

      return Scaffold(
        body: Center(
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 1000,
            fixedTopRows: 1,
            isHorizontalScrollBarVisible: true,
            isVerticalScrollBarVisible: true,
            columns: List<DataColumn>.generate(
              watchPoints.headers.length,
              (int index) => DataColumn2(
                label: Row(
                  children: [
                    Icon(
                      sortAscending[index] ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      key: index == 0 ? keyColumnCollapse : null,
                    ),
                    Flexible(
                      child: Text(
                        watchPoints.headers[index],
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                fixedWidth: columnWidthTotal > MediaQuery.of(context).size.width ? null : columnWidths[index], // Set fixed width based on calculated column width if columnWidthTotal is less than maximumWidth, otherwise use null
                onSort: (columnIndex, ascending) {
                  setState(() {
                    sortAscending[columnIndex] = !sortAscending[columnIndex];
                    // Perform sorting based on columnIndex
                    watchPoints.rows.sort((a, b) {
                      // Check if a or b is a reboot row
                      bool isAReboot = a.length == 2 && a[0] == "Reboot";
                      bool isBReboot = b.length == 2 && b[0] == "Reboot";

                      // Handle reboot rows separately
                      if (isAReboot && isBReboot) {
                        return 0; // Keep reboot rows in their relative order
                      } else if (isAReboot) {
                        return 1; // Place reboot row 'a' after non-reboot row 'b'
                      } else if (isBReboot) {
                        return -1; // Place non-reboot row 'b' before reboot row 'a'
                      }

                      // Compare non-reboot rows based on column values
                      final aValue = a[columnIndex + 3]; // Skip first 3 elements
                      final bValue = b[columnIndex + 3];

                      if (aValue is String && bValue is String) {
                        return sortAscending[columnIndex] ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
                      } else if (aValue is int && bValue is int) {
                        return sortAscending[columnIndex] ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
                      }

                      return 0; // Default case, no change in order
                    });
                  });
                },
              ),
            ),
            rows: watchPoints.rows.where((rowData) => !(rowData.length == 2)).map((rowData) {
              return DataRow(
                cells: List<DataCell>.generate(rowData.length - 3, (cellIndex) {
                  return DataCell(
                    Text(rowData[cellIndex + 3].toString()),
                  );
                }),
              );
            }).toList(),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Text(
            'No Data Yet!',
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}

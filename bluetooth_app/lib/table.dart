import 'dart:ui';

import 'package:bluetooth_app/shareddata.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MyTablePage extends StatefulWidget {
  const MyTablePage({super.key});
  @override
  State<MyTablePage> createState() => _MyTablePageState();
}

class _MyTablePageState extends State<MyTablePage> with AutomaticKeepAliveClientMixin<MyTablePage> {
  bool initOnce = true;
  List<bool> visibleColumns = [];

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey keyColumnCollapse = GlobalKey();
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

    // Styling for the infoButton target
    targets.add(TargetFocus(
      identify: "Collumn Collapse",
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
                  "Column Collapse Button",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Clicking here will allows you to collapse the column to take up less space.",
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
    super.build(context); // Invoke the overridden method

    final watchPoints = context
        .watch<SharedBluetoothData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readPoints = context.read<SharedBluetoothData>(); //To modify the data without rebuilding the widget

    if (watchPoints.fullHeaders.isNotEmpty) {
      if (initOnce || visibleColumns.length != watchPoints.headers.length) {
        initOnce = false;
        visibleColumns = List.generate(watchPoints.headers.length, (index) => true);
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
                fixedWidth: visibleColumns[index] ? 175 : 55,
                label: Expanded(
                  child: Row(
                    children: [
                      Icon(
                        !visibleColumns[index] ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        key: index == 0 ? keyColumnCollapse : null,
                      ),
                      Visibility(
                        visible: visibleColumns[index],
                        child: Flexible(
                          child: Text(
                            watchPoints.headers[index],
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis, // Apply ellipsis for long text
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onSort: (columnIndex, ascending) {
                  setState(() {
                    visibleColumns[index] = !visibleColumns[index];
                  });
                },
              ),
            ),
            rows: watchPoints.rows
                .where((rowData) => !(rowData.length == 1)) //Do not include reboot rows
                .map((rowData) {
              return DataRow(
                cells: List<DataCell>.generate(rowData.length - 3, (cellIndex) {
                  bool cellVisibility = visibleColumns[cellIndex];
                  return DataCell(
                    Visibility(
                      visible: cellVisibility,
                      child: Text(rowData[cellIndex + 3].toString()),
                    ),
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
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}

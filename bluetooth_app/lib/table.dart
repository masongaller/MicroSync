import 'package:bluetooth_app/shareddata.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyTablePage extends StatefulWidget {
  const MyTablePage({super.key});
  @override
  State<MyTablePage> createState() => _MyTablePageState();
}

class _MyTablePageState extends State<MyTablePage> with AutomaticKeepAliveClientMixin<MyTablePage> {
  bool initOnce = true;
  List<bool> visibleColumns = [];

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

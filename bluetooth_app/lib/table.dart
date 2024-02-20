import 'package:bluetooth_app/enumerator.dart';
import 'package:bluetooth_app/shareddata.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyTablePage extends StatefulWidget {
  const MyTablePage({super.key});
  @override
  State<MyTablePage> createState() => _MyTablePageState();
}

class _MyTablePageState extends State<MyTablePage>
    with AutomaticKeepAliveClientMixin<MyTablePage> {
  @override
  Widget build(BuildContext context) {
    final watchPoints = context.watch<
        SharedBluetoothData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readPoints = context.read<
        SharedBluetoothData>(); //To modify the data without rebuilding the widget

    if (watchPoints.fullHeaders.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
              child: Column(
            children: [
              DataTable(
                columns: List<DataColumn>.generate(
                  watchPoints.headers.length,
                  (int index) => DataColumn(
                    label: Expanded(
                      child: Text(
                        watchPoints.headers[index],
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ),
                rows: watchPoints.rows.map((rowData) {
                  return DataRow(
                    cells: rowData.skip(3).map((cellData) {
                      return DataCell(Text(cellData.toString()));
                    }).toList(),
                  );
                }).toList(),
              ),
            ],
          )),
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

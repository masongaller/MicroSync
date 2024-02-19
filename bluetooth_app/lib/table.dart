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
                rows: List<DataRow>.generate(
                  watchPoints.rows.length,
                  (int index) => DataRow(
                    cells: <DataCell>[
                      DataCell(Text(watchPoints.rows[index][3].toString())),
                      DataCell(Text(watchPoints.rows[index][4].toString())),
                      DataCell(Text(watchPoints.rows[index][5].toString())),
                    ],
                  ),
                ),
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
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}

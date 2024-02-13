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
    final readPoints = context
        .read<SharedBluetoothData>(); //To modify the data without rebuilding the widget

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          children: [
            FloatingActionButton(
              onPressed: () {
                readPoints.addPoint();
              },
              tooltip: 'Add Point',
              child: const Icon(Icons.add),
            ),
            DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Time(s)',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'X',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Y',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows: List<DataRow>.generate(
                watchPoints.points.length,
                (int index) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text(index.toString())),
                    DataCell(Text(watchPoints.points[index].x.toString())),
                    DataCell(Text(watchPoints.points[index].y.toString())),
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

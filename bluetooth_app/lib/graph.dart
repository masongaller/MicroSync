import 'package:bluetooth_app/enumerator.dart';
import 'package:bluetooth_app/shareddata.dart';
import 'package:bluetooth_app/zoomable_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Graph Tool Tip Tutorial From https://blog.logrocket.com/build-beautiful-charts-flutter-fl-chart/#customizing-tooltip

class MyDataPage extends StatefulWidget {
  const MyDataPage({Key? key}) : super(key: key);

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage>
    with AutomaticKeepAliveClientMixin<MyDataPage> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final watchPoints = context.watch<
        SharedBluetoothData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readPoints = context.read<
        SharedBluetoothData>(); //To modify the data without rebuilding the widget

    if (watchPoints.fullHeaders.isNotEmpty) {
      double? maxTime;

      for (var row in watchPoints.rows) {
        dynamic timeValue = row[RowIndices.intTime];

        if (timeValue is num) {
          // If timeValue is a number (int or double), update maxTime
          if (maxTime == null || timeValue > maxTime!) {
            maxTime = timeValue.toDouble();
          }
        }
      }

      return Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              const SizedBox(
                height: 15,
              ),
              Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center, // Align text to the center
                      child: const Text(
                        'Sample Chart',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 6),
                  child: ZoomableChart(
                    maxX: maxTime ?? 0,
                    builder: (minX, maxX) {
                      List<LineChartBarData> lineBarsData =
                          List<LineChartBarData>.generate(
                        watchPoints.headers.length - 1,
                        (barIndex) {
                          String header = watchPoints.headers[barIndex + 1];
                          return LineChartBarData(
                            spots: List<FlSpot>.generate(
                              watchPoints.rows.length,
                              (index) {
                                dynamic value = watchPoints.rows[index]
                                    [watchPoints.fullHeaders.indexOf(header)];
                                double yValue = (value is double ||
                                        value is int)
                                    ? value
                                        .toDouble() // Already a double or int, no need to parse
                                    : double.parse(value
                                        .toString()); // Parse if it's a String

                                return FlSpot(
                                  watchPoints.rows[index][RowIndices.intTime]
                                      .toDouble(),
                                  yValue,
                                );
                              },
                            ),
                            isCurved: false,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          );
                        },
                      );

                      return LineChart(
                        LineChartData(
                          lineBarsData: lineBarsData,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: bottomTitles,
                              axisNameWidget: Text('Axis name'),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: leftTitles,
                              axisNameWidget: Text('Axis name'),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.2),
                                  width: 4),
                              left: const BorderSide(color: Colors.transparent),
                              right:
                                  const BorderSide(color: Colors.transparent),
                              top: const BorderSide(color: Colors.transparent),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                              enabled: false,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 20.0,
                                showOnTopOfTheChartBoxArea: true,
                                fitInsideHorizontally: true,
                                tooltipMargin: 0,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map(
                                    (LineBarSpot touchedSpot) {
                                      const textStyle = TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      );
                                      return LineTooltipItem(
                                        "X: ${touchedSpot.x.toStringAsFixed(2)}\nY: ${touchedSpot.y.toStringAsFixed(2)}",
                                        textStyle,
                                      );
                                    },
                                  ).toList();
                                },
                              ),
                              getTouchedSpotIndicator:
                                  (LineChartBarData barData,
                                      List<int> indicators) {
                                return indicators.map(
                                  (int index) {
                                    final line = FlLine(
                                        color: theme.dividerColor,
                                        strokeWidth: 1,
                                        dashArray: [2, 4]);
                                    return TouchedSpotIndicatorData(
                                      line,
                                      FlDotData(show: false),
                                    );
                                  },
                                ).toList();
                              },
                              getTouchLineEnd: (_, __) => double.infinity),
                          gridData: const FlGridData(show: true),
                          minX: minX,
                          minY: 0,
                          maxX: maxX,
                          // maxY: maxY,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ],
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

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: bottomTitleWidgets,
      );

  SideTitles get leftTitles => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        reservedSize: 32,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    text = Text(value.toStringAsFixed(0), style: style);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    String text;
    text = value.toStringAsFixed(0);

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  @override
  bool get wantKeepAlive => true;
}

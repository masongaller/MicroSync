import 'package:bluetooth_app/shareddata.dart';
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
  double minY = 0;
  double maxY = 10;
  double minX = 0;
  double maxX = 10;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final watchPoints = context.watch<
        SharedData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readPoints = context
        .read<SharedData>(); //To modify the data without rebuilding the widget

    return AspectRatio(
      aspectRatio: 1.23,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              const SizedBox(
                height: 15,
              ),
              Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Positioned(
                    bottom: 15,
                    left: 15,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.add),
                      iconSize: 20,
                      onPressed: () {
                        setState(() {
                          maxY += 1;
                        });
                      },
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.remove),
                      iconSize: 20,
                      onPressed: () {
                        setState(() {
                          maxY -= 1;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center, // Align text to the center
                      child: Text(
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
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: List<FlSpot>.generate(
                              watchPoints.points.length,
                              (index) => FlSpot(
                                  watchPoints.points[index].x.toDouble(),
                                  watchPoints.points[index].y.toDouble())),
                          isCurved: true,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
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
                          right: const BorderSide(color: Colors.transparent),
                          top: const BorderSide(color: Colors.transparent),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                          enabled: true,
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
                                    "Y: " +
                                        watchPoints
                                            .points[touchedSpot.spotIndex].y
                                            .toStringAsFixed(2) +
                                        "\nX: " +
                                        watchPoints
                                            .points[touchedSpot.spotIndex].x
                                            .toStringAsFixed(2),
                                    textStyle,
                                  );
                                },
                              ).toList();
                            },
                          ),
                          getTouchedSpotIndicator:
                              (LineChartBarData barData, List<int> indicators) {
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
                      minY: minY,
                      // maxX: maxX,
                      // maxY: maxY,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.remove),
                    iconSize: 20,
                    onPressed: () {
                      setState(() {
                        maxX -= 1;
                      });
                    },
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.add),
                    iconSize: 20,
                    onPressed: () {
                      setState(() {
                        maxX += 1;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ],
      ),
    );
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
    text = Text(value.toStringAsFixed(1), style: style);

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

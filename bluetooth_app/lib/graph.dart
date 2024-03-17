import 'dart:math';
import 'package:bluetooth_app/enumerator.dart';
import 'package:bluetooth_app/shareddata.dart';
import 'package:bluetooth_app/zoomable_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Graph Tool Tip Tutorial From https://blog.logrocket.com/build-beautiful-charts-flutter-fl-chart/#customizing-tooltip

class MyDataPage extends StatefulWidget {
  const MyDataPage({super.key});

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage>
    with AutomaticKeepAliveClientMixin<MyDataPage> {
  List<bool> selectedButton = [];
  List<Color>? barColors;
  Icon playPauseIcon = const Icon(Icons.pause);
  bool zoomable = true;
  List<String> currHeaders = [];
  double maxY = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Invoke the overridden method

    var theme = Theme.of(context);
    final watchPoints = context.watch<
        SharedBluetoothData>(); //Use context.watch<T>() when the widget needs to rebuild when the model changes.
    final readPoints = context.read<
        SharedBluetoothData>(); //To modify the data without rebuilding the widget

    List<VerticalLine> verticalLines = [];

    List<Color> generateRandomColors(int count) {
      Random random = Random();
      List<Color> colors = List.generate(count, (index) {
        return Color.fromRGBO(
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
          1.0,
        );
      });
      return colors;
    }

    if (watchPoints.fullHeaders.isNotEmpty) {
      //Only initialize it once
      if (selectedButton.isEmpty) {
        for (int i = 0; i < watchPoints.headers.length - 1; i++) {
          selectedButton.add(true);
        }
        barColors = generateRandomColors(watchPoints.headers.length);
        currHeaders = readPoints.headers.sublist(1);
      }

      double? maxTime;
      maxY = 0;
      for (var row in watchPoints.rows) {
        if (row.length == 1) {
          //Skip reboot rows
          continue;
        }
        dynamic timeValue = row[RowIndices.intTime];

        if (timeValue is num) {
          // If timeValue is a number (int or double), update maxTime
          if (maxTime == null || timeValue > maxTime) {
            maxTime = timeValue.toDouble();
          }
        }

        if (selectedButton.isNotEmpty) {
          for (int i = 0; i < currHeaders.length; i++) {
            String header = currHeaders[i];
            dynamic value = row[readPoints.fullHeaders.indexOf(header)];
            double yValue = (value is double || value is int)
                ? value.toDouble()
                : double.parse(value.toString());

            if (maxY == 0 || yValue > maxY) {
              maxY = yValue;
            }
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
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: playPauseIcon,
                          onPressed: () {
                            zoomable = !zoomable;
                            setState(() {
                              if (zoomable) {
                                playPauseIcon = const Icon(Icons.pause);
                              } else {
                                playPauseIcon = const Icon(Icons.play_arrow);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
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
                    minX: readPoints.rows.isNotEmpty
                        ? readPoints.rows[0][RowIndices.intTime].toDouble()
                        : 0,
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
                                if (watchPoints.rows[index][0] == "Reboot") {
                                  //Create discontinuity in graph to signify data reboot
                                  verticalLines.add(VerticalLine(
                                      x: watchPoints.rows[index - 1]
                                                  [RowIndices.intTime]
                                              .toDouble() +
                                          0.5,
                                      dashArray: [2, 4]));
                                  return FlSpot.nullSpot;
                                }
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
                            show: selectedButton[barIndex],
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                            color: barColors?[barIndex] ??
                                theme.colorScheme.onBackground,
                          );
                        },
                      );

                      return LineChart(
                        LineChartData(
                          extraLinesData: ExtraLinesData(
                            verticalLines: verticalLines,
                          ),
                          lineBarsData: lineBarsData,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: bottomTitles,
                              axisNameWidget: Text(readPoints.headers[0]),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: leftTitles,
                              axisNameWidget: Text(currHeaders.join(", ")),
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
                              enabled: !zoomable,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 20.0,
                                showOnTopOfTheChartBoxArea: true,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipMargin: 0,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map(
                                    (LineBarSpot touchedSpot) {
                                      const textStyle = TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      );
                                      return LineTooltipItem(
                                        "${readPoints.headers[touchedSpot.barIndex + 1]}: ${touchedSpot.x.toStringAsFixed(2)}, ${touchedSpot.y.toStringAsFixed(2)}",
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
                                      const FlDotData(show: false),
                                    );
                                  },
                                ).toList();
                              },
                              getTouchLineEnd: (_, __) => double.infinity),
                          gridData: const FlGridData(show: true),
                          minX: minX,
                          minY: 0,
                          maxX: maxX,
                          maxY: maxY,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 6),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: readPoints.headers.length - 1,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(readPoints.headers[index + 1]),
                            value: selectedButton[index],
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: barColors?[index] ??
                                theme.colorScheme.onBackground,
                            onChanged: (value) {
                              setState(() {
                                selectedButton[index] = value!;
                                if (value) {
                                  currHeaders
                                      .add(readPoints.headers[index + 1]);
                                } else {
                                  currHeaders
                                      .remove(readPoints.headers[index + 1]);
                                }
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info),
                          onPressed: () {
                            // Calculate mean, median, and mode
                            String header = watchPoints.headers[index + 1];
                            List<double> values = [];

                            // Collect all values corresponding to the header
                            for (List<dynamic> row in readPoints.rows) {
                              if (row[0] == "Reboot") {
                                continue;
                              }
                              dynamic value =
                                  row[readPoints.fullHeaders.indexOf(header)];
                              if (value != null && value is String) {
                                values.add(
                                    value.isNotEmpty ? double.parse(value) : 0);
                              }
                            }

                            // Calculate Mean
                            double mean = values.isNotEmpty
                                ? values.reduce((a, b) => a + b) / values.length
                                : 0;

                            // Calculate Median
                            double median = 0;
                            if (values.isNotEmpty) {
                              values.sort();
                              int middle = values.length ~/ 2;
                              median = values.length.isEven
                                  ? (values[middle - 1] + values[middle]) / 2.0
                                  : values[middle];
                            }

                            // Calculate Mode
                            int mode = 0;
                            if (values.isNotEmpty) {
                              Map<double, int> counts = {};
                              values.forEach((element) {
                                counts[element] = counts.containsKey(element)
                                    ? counts[element]! + 1
                                    : 1;
                              });
                              mode = counts.entries
                                  .fold(counts.entries.first,
                                      (a, b) => b.value > a.value ? b : a)
                                  .key
                                  .toInt();
                            }

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    readPoints.headers[index + 1],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8),
                                      Text(
                                        'Mean: $mean',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Median: $median',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Mode: $mode',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
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

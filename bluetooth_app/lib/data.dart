import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
                      color: Colors.green,
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
                      color: Colors.red,
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
                          color: theme.colorScheme.primary,
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
                          spots: [
                            const FlSpot(0, 3),
                            const FlSpot(1, 1),
                            const FlSpot(2, 4),
                            const FlSpot(3, 2),
                            const FlSpot(4, 5),
                          ],
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 4,
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
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
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
                      gridData: const FlGridData(show: true),
                      minX: minX,
                      minY: minY,
                      maxX: maxX,
                      maxY: maxY,
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
                    color: Colors.red,
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
                    color: Colors.green,
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
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  SideTitles get leftTitles => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 32,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    text = Text(value.toInt().toString(), style: style);

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
    text = value.toInt().toString();

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  @override
  bool get wantKeepAlive => true;
}

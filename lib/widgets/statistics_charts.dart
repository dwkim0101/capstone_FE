import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// 실내/실외 비교 BarChart
class IndoorOutdoorBarChart extends StatelessWidget {
  final List<double> indoorScores;
  final List<double> outdoorScores;
  final List<String> labels;
  const IndoorOutdoorBarChart({
    required this.indoorScores,
    required this.outdoorScores,
    required this.labels,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: List.generate(labels.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: indoorScores[i], color: Colors.blue),
              BarChartRodData(toY: outdoorScores[i], color: Colors.green),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(labels[value.toInt()]),
            ),
          ),
        ),
      ),
    );
  }
}

// 시간별 트렌드 LineChart
class HourlyLineChart extends StatelessWidget {
  final List<double> hourlyScores;
  final List<String> hourLabels;
  const HourlyLineChart({
    required this.hourlyScores,
    required this.hourLabels,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              hourlyScores.length,
              (i) => FlSpot(i.toDouble(), hourlyScores[i]),
            ),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(hourLabels[value.toInt()]),
            ),
          ),
        ),
      ),
    );
  }
}

// 일별 트렌드 BarChart
class DailyBarChart extends StatelessWidget {
  final List<double> dailyScores;
  final List<String> dayLabels;
  const DailyBarChart({
    required this.dailyScores,
    required this.dayLabels,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: List.generate(dayLabels.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: dailyScores[i], color: Colors.orange),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(dayLabels[value.toInt()]),
            ),
          ),
        ),
      ),
    );
  }
}

// 주간 트렌드 AreaChart (LineChart + 아래 영역 색상)
class WeeklyAreaChart extends StatelessWidget {
  final List<double> weeklyScores;
  final List<String> weekLabels;
  const WeeklyAreaChart({
    required this.weeklyScores,
    required this.weekLabels,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              weeklyScores.length,
              (i) => FlSpot(i.toDouble(), weeklyScores[i]),
            ),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.3),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(weekLabels[value.toInt()]),
            ),
          ),
        ),
      ),
    );
  }
}

// 이상치 감지 (LineChart + 마커)
class OutlierLineChart extends StatelessWidget {
  final List<double> scores;
  final List<int> outlierIndices;
  final List<String> labels;
  const OutlierLineChart({
    required this.scores,
    required this.outlierIndices,
    required this.labels,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              scores.length,
              (i) => FlSpot(i.toDouble(), scores[i]),
            ),
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                if (outlierIndices.contains(index)) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.black,
                  );
                }
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.teal,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(labels[value.toInt()]),
            ),
          ),
        ),
      ),
    );
  }
}

// 예측 (LineChart, dotted)
class PredictionLineChart extends StatelessWidget {
  final List<double> actualScores;
  final List<double> predictedScores;
  final List<String> labels;
  const PredictionLineChart({
    required this.actualScores,
    required this.predictedScores,
    required this.labels,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              actualScores.length,
              (i) => FlSpot(i.toDouble(), actualScores[i]),
            ),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: List.generate(
              predictedScores.length,
              (i) => FlSpot(i.toDouble(), predictedScores[i]),
            ),
            isCurved: true,
            color: Colors.grey,
            barWidth: 2,
            dashArray: [8, 4],
            dotData: FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(labels[value.toInt()]),
            ),
          ),
        ),
      ),
    );
  }
}

// 만족도 PieChart
class SatisfactionPieChart extends StatelessWidget {
  final double satisfied;
  final double neutral;
  final double dissatisfied;
  const SatisfactionPieChart({
    required this.satisfied,
    required this.neutral,
    required this.dissatisfied,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: satisfied,
            color: Colors.green,
            title: '만족',
          ),
          PieChartSectionData(value: neutral, color: Colors.grey, title: '보통'),
          PieChartSectionData(
            value: dissatisfied,
            color: Colors.red,
            title: '불만',
          ),
        ],
      ),
    );
  }
}

// 데이터 없음/로딩 안내 카드
Widget buildLoadingOrEmpty({
  required bool loading,
  required bool empty,
  required String message,
}) {
  if (loading) {
    return Center(child: Text('조회중 ...'));
  }
  if (empty) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(message, style: TextStyle(fontSize: 18)),
      ),
    );
  }
  return SizedBox.shrink();
}

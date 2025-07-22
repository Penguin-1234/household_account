import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PredictionPage extends StatefulWidget {
  final Map<DateTime, Map<String, List<Map<String, dynamic>>>> entries;

  const PredictionPage({
    super.key,
    required this.entries,
  });

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  DateTime _selectedMonth = DateTime.now();
  final formatter = NumberFormat("#,###");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C),
        title: const Text('支出予測'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 月選択
            _buildMonthSelector(),
            // グラフ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPredictionChart(),
              ),
            ),
            // 予測情報
            _buildPredictionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          Text(
            DateFormat('yyyy年MM月').format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionChart() {
    final chartData = _calculateChartData();

    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'この月のデータがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // グラフタイトルと凡例
            _buildChartHeader(),
            const SizedBox(height: 16),
            // グラフ本体
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    horizontalInterval: _calculateGridInterval(chartData),
                    verticalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        interval: _calculateGridInterval(chartData),
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _formatCurrency(value.toInt()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt();
                          if (day % 5 == 0 && day <= _getDaysInMonth(_selectedMonth)) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${day}日',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    // 実際の累積支出
                    LineChartBarData(
                      spots: chartData['actual']!,
                      isCurved: true,
                      color: const Color(0xFFE53E3E),
                      barWidth: 4,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFFE53E3E),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFE53E3E).withOpacity(0.1),
                      ),
                    ),
                    // 予測線
                    if (chartData['prediction']!.isNotEmpty)
                      LineChartBarData(
                        spots: chartData['prediction']!,
                        isCurved: true,
                        color: Colors.grey.withOpacity(0.8),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.grey.withOpacity(0.8),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        dashArray: [8, 4],
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.grey.withOpacity(0.05),
                        ),
                      ),
                  ],
                  minX: 1,
                  maxX: _getDaysInMonth(_selectedMonth).toDouble(),
                  minY: 0,
                  maxY: _calculateMaxY(chartData),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final isActual = touchedSpot.barIndex == 0;
                          final label = isActual ? '実際' : '予測';
                          return LineTooltipItem(
                            '$label\n${touchedSpot.x.toInt()}日: ${_formatCurrency(touchedSpot.y.toInt())}円',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // グラフヘッダー（タイトルと凡例）
  Widget _buildChartHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '月間累積支出グラフ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // 凡例
        Row(
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: const BoxDecoration(
                color: Color(0xFFE53E3E),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '実際',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.8),
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '予測',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  // 通貨フォーマット関数
  String _formatCurrency(int value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}千';
    } else {
      return '${value}';
    }
  }
  final predictionData = _calculatePredictionData();

  return Container(
  padding: const EdgeInsets.all(16),
  child: Card(
  child: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text(
  '予測情報',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 12),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text('現在の累積支出：'),
  Text('${formatter.format(predictionData['currentTotal'])}円'),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text('月末予測支出：'),
  Text(
  '${formatter.format(predictionData['predictedTotal'])}円',
  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
  ),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text('1日平均支出：'),
  Text('${formatter.format(predictionData['dailyAverage'])}円'),
  ],
  ),
  const SizedBox(height: 8),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Text('残り日数：'),
  Text('${predictionData['remainingDays']}日'),
  ],
  ),
  ],
  ),
  ),
  ),
  );
}

Map<String, List<FlSpot>> _calculateChartData() {
  final daysInMonth = _getDaysInMonth(_selectedMonth);
  final actualSpots = <FlSpot>[];
  final predictionSpots = <FlSpot>[];

  int cumulativeExpense = 0;
  final today = DateTime.now();
  final currentDay = (today.year == _selectedMonth.year && today.month == _selectedMonth.month)
      ? today.day : daysInMonth;

  // 実際のデータを計算
  for (int day = 1; day <= currentDay && day <= daysInMonth; day++) {
    final date = DateTime.utc(_selectedMonth.year, _selectedMonth.month, day);
    final dayExpenses = widget.entries[date]?['支出'] ?? [];
    final dayTotal = dayExpenses.fold(0, (sum, e) => sum + (e['amount'] as int));
    cumulativeExpense += dayTotal;
    actualSpots.add(FlSpot(day.toDouble(), cumulativeExpense.toDouble()));
  }

  // 予測データを計算
  if (actualSpots.isNotEmpty && currentDay < daysInMonth) {
    final dailyAverage = cumulativeExpense / currentDay;

    // 現在の日から予測開始
    for (int day = currentDay; day <= daysInMonth; day++) {
      final predictedTotal = dailyAverage * day;
      predictionSpots.add(FlSpot(day.toDouble(), predictedTotal));
    }
  }

  return {
    'actual': actualSpots,
    'prediction': predictionSpots,
  };
}

Map<String, int> _calculatePredictionData() {
  final daysInMonth = _getDaysInMonth(_selectedMonth);
  final today = DateTime.now();
  final currentDay = (today.year == _selectedMonth.year && today.month == _selectedMonth.month)
      ? today.day : daysInMonth;

  int currentTotal = 0;

  // 現在までの累積支出を計算
  for (int day = 1; day <= currentDay && day <= daysInMonth; day++) {
    final date = DateTime.utc(_selectedMonth.year, _selectedMonth.month, day);
    final dayExpenses = widget.entries[date]?['支出'] ?? [];
    final dayTotal = dayExpenses.fold(0, (sum, e) => sum + (e['amount'] as int));
    currentTotal += dayTotal;
  }

  final dailyAverage = currentDay > 0 ? (currentTotal / currentDay).round() : 0;
  final predictedTotal = dailyAverage * daysInMonth;
  final remainingDays = daysInMonth - currentDay;

  return {
    'currentTotal': currentTotal,
    'predictedTotal': predictedTotal,
    'dailyAverage': dailyAverage,
    'remainingDays': remainingDays > 0 ? remainingDays : 0,
  };
}

int _getDaysInMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0).day;
}

double _calculateMaxY(Map<String, List<FlSpot>> chartData) {
  double maxY = 1000; // 最小値

  for (final spots in chartData.values) {
    for (final spot in spots) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }
  }

  return maxY * 1.1; // 10%のマージンを追加
}

double _calculateGridInterval(Map<String, List<FlSpot>> chartData) {
  final maxY = _calculateMaxY(chartData);

  // より適切な間隔を計算
  if (maxY <= 5000) {
    return 1000;
  } else if (maxY <= 10000) {
    return 2000;
  } else if (maxY <= 25000) {
    return 5000;
  } else if (maxY <= 50000) {
    return 10000;
  } else if (maxY <= 100000) {
    return 20000;
  } else {
    return (maxY / 5).roundToDouble();
  }
}
}
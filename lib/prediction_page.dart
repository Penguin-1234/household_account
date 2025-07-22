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
            DateFormat('yyyy年M月').format(_selectedMonth),
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
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: _calculateGridInterval(chartData),
              verticalInterval: 5,
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() % 5 == 0 && value.toInt() <= 31) {
                      return Text(
                        '${value.toInt()}日',
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              // 実際の累積支出
              LineChartBarData(
                spots: chartData['actual']!,
                isCurved: false,
                color: Colors.red,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
              // 予測線
              LineChartBarData(
                spots: chartData['prediction']!,
                isCurved: false,
                color: Colors.grey.withOpacity(0.6),
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 2,
                      color: Colors.grey.withOpacity(0.6),
                    );
                  },
                ),
                dashArray: [5, 5], // 破線スタイル
              ),
            ],
            minX: 1,
            maxX: _getDaysInMonth(_selectedMonth).toDouble(),
            minY: 0,
            maxY: _calculateMaxY(chartData),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionInfo() {
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
    return (maxY / 5).roundToDouble(); // 5つのグリッド線に分割
  }
}
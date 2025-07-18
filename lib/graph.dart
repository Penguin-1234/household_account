import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GraphPage extends StatefulWidget {
  final Map<String, int> incomeData;
  final Map<String, int> expenseData;

  const GraphPage({
    super.key,
    required this.incomeData,
    required this.expenseData,
  });

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  bool _isIncome = false; // ← 初期状態は「支出」を表示

  @override
  Widget build(BuildContext context) {
    final categoryData = _isIncome ? widget.incomeData : widget.expenseData;

    final total = categoryData.isEmpty
        ? 1
        : categoryData.values.fold(0, (a, b) => a + b);

    final formatter = NumberFormat("#,###");

    final colorMap = {
      '食費': Colors.orange,
      '交通費': Colors.blue,
      '日用品': Colors.green,
      '娯楽': Colors.red,
      'その他': Colors.grey,
      '給料': Colors.indigo,
      'お小遣い': Colors.teal,
      '副業': Colors.pink,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? '今月の収入グラフ' : '今月の支出グラフ'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isIncome = !_isIncome; // 状態を切り替え
              });
            },
            child: Text(
              _isIncome ? '支出に切り替え' : '収入に切り替え',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Center(
        child: categoryData.isEmpty
            ? Text(_isIncome ? '今月の収入データがありません' : '今月の支出データがありません')
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categoryData.entries.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = (amount / total) * 100;
                final titleText =
                    '${category}\n¥${formatter.format(amount)}\n${percentage.toStringAsFixed(1)}%';

                return PieChartSectionData(
                  color: colorMap[category] ?? Colors.purple,
                  value: amount.toDouble(),
                  title: titleText,
                  radius: 110,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

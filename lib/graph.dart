import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GraphPage extends StatefulWidget {
  // 変更点: 全ての取引データを受け取る
  final Map<DateTime, Map<String, List<Map<String, dynamic>>>> entries;

  const GraphPage({
    super.key,
    required this.entries,
  });

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  bool _isIncome = false;
  DateTime _currentDate = DateTime.now(); // 現在表示している月

  // 追加: 月のデータを集計する関数
  Map<String, Map<String, int>> _calculateMonthlyData() {
    final Map<String, int> monthlyIncome = {};
    final Map<String, int> monthlyExpense = {};

    widget.entries.forEach((date, types) {
      if (date.year == _currentDate.year && date.month == _currentDate.month) {
        // 収入データを集計
        types['収入']?.forEach((entry) {
          final category = entry['category'] as String;
          final amount = entry['amount'] as int;
          monthlyIncome.update(category, (value) => value + amount, ifAbsent: () => amount);
        });

        // 支出データを集計
        types['支出']?.forEach((entry) {
          final category = entry['category'] as String;
          final amount = entry['amount'] as int;
          monthlyExpense.update(category, (value) => value + amount, ifAbsent: () => amount);
        });
      }
    });

    return {
      'income': monthlyIncome,
      'expense': monthlyExpense,
    };
  }


  @override
  Widget build(BuildContext context) {
    // 変更点: buildメソッド内でデータを計算する
    final monthlyData = _calculateMonthlyData();
    final incomeData = monthlyData['income']!;
    final expenseData = monthlyData['expense']!;

    final categoryData = _isIncome ? incomeData : expenseData;

    final total = categoryData.values.fold<int>(0, (a, b) => a + b);

    final formatter = NumberFormat("#,###");

    final colorMap = {
      '食費': const Color(0xFF4CAF50), // グリーン
      '外食費': const Color(0xFFFF9800), // オレンジ
      '交通費': const Color(0xFFE91E63), // ピンク
      '日用品': const Color(0xFF2196F3), // ブルー
      '医療費': const Color(0xFF9C27B0), // パープル
      '娯楽費': const Color(0xFFFFC107), // アンバー
      '趣味': const Color(0xFFF44336), // レッド
      '美容費': const Color(0xFF607D8B), // ブルーグレー
      '交際費': const Color(0xFF795548), // ブラウン
      'その他': const Color(0xFF9E9E9E), // グレー
      '給料': const Color(0xFF3F51B5), // インディゴ
      'お小遣い': const Color(0xFF009688), // ティール
      '副業': const Color(0xFFE91E63), // ピンク
    };

    // 表示用の年月を生成
    final yearMonth = '${_currentDate.year}年${_currentDate.month.toString()}月';
    final Month = '${_currentDate.month.toString()}月';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // ベージュ系背景
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C), // 薄いブラウン
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
                });
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  yearMonth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
                });
              },
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // タブ切り替えボタン
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabButton('支出', false),
                _buildTabButton('収入', true),
              ],
            ),
          ),

          // 円グラフまたはメッセージ表示
          Expanded(
            child: categoryData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isIncome ? Icons.trending_up : Icons.trending_down,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${Month}の${_isIncome ? '収入' : '支出'}データがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: [
                // 円グラフ
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(16),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: categoryData.entries.map((entry) {
                        final category = entry.key;
                        final amount = entry.value;
                        final percentage = total > 0 ? (amount / total) * 100 : 0;

                        return PieChartSectionData(
                          color: colorMap[category] ?? Colors.grey,
                          value: amount.toDouble(),
                          title: percentage > 5
                              ? '${category}\n${percentage.toStringAsFixed(1)}%'
                              : '',
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 合計表示
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Month}の合計',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${formatter.format(total)}円',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isIncome ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // カテゴリ別リスト
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoryData.length,
                    itemBuilder: (context, index) {
                      final sortedEntries = categoryData.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      final entry = sortedEntries[index];
                      final category = entry.key;
                      final amount = entry.value;
                      final color = colorMap[category] ?? Colors.purple;
                      final percentage = total > 0 ? (amount / total) * 100 : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${formatter.format(amount)}円',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 月選択ダイアログを表示
  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '月を選択',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: YearPicker(
                    firstDate: DateTime(2020),
                    lastDate: DateTime(now.year + 2),
                    selectedDate: _currentDate,
                    onChanged: (DateTime dateTime) {
                      Navigator.of(context).pop(DateTime(dateTime.year, _currentDate.month));
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (index) {
                    final month = index + 1;
                    final isSelected = month == _currentDate.month;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(DateTime(_currentDate.year, month));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD2B48C) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${month}月',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _currentDate = picked;
      });
    }
  }

  // タブボタンを生成するヘルパーメソッド
  Widget _buildTabButton(String title, bool isIncomeTab) {
    final bool isSelected = _isIncome == isIncomeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isIncome = isIncomeTab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
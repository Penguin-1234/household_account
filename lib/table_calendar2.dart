import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'category_service.dart';
import 'category_settings_page.dart';

class CalendarPage extends StatefulWidget {
  final Map<DateTime, Map<String, List<Map<String, dynamic>>>> entries;
  final Function(Map<DateTime, Map<String, List<Map<String, dynamic>>>>) onUpdateEntries;

  const CalendarPage({
    super.key,
    required this.entries,
    required this.onUpdateEntries,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _currentDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  final formatter = NumberFormat("#,###");
  final CategoryService _categoryService = CategoryService();
  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final incomeCategories = await _categoryService.getIncomeCategories();
      final expenseCategories = await _categoryService.getExpenseCategories();

      if (mounted) {
        setState(() {
          _incomeCategories = incomeCategories;
          _expenseCategories = expenseCategories;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategorySettingsPage()),
    );

    await _loadCategories();

    if (mounted) {
      setState(() {});
    }
  }

  // 特定の日の支出総額を取得
  int _getDayExpenseTotal(DateTime day) {
    final date = DateTime.utc(day.year, day.month, day.day);
    final expenses = widget.entries[date]?['支出'] ?? [];
    return expenses.fold(0, (sum, e) => sum + (e['amount'] as int));
  }

  // 月の最大支出額を取得（グラデーションの基準値として使用）
  int _getMaxMonthlyExpense() {
    int maxExpense = 1000; // 最小基準値

    widget.entries.forEach((date, types) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        final expenses = types['支出'] ?? [];
        final dayExpense = expenses.fold(0, (sum, e) => sum + (e['amount'] as int));
        if (dayExpense > maxExpense) {
          maxExpense = dayExpense;
        }
      }
    });

    return maxExpense;
  }

  // 支出額に応じた色を取得
  Color _getExpenseColor(DateTime day) {
    final dayExpense = _getDayExpenseTotal(day);
    if (dayExpense == 0) {
      return Colors.transparent; // 支出がない場合は透明
    }

    final maxExpense = _getMaxMonthlyExpense();
    final ratio = (dayExpense / maxExpense).clamp(0.0, 1.0);

    // グラデーション色を計算（薄いピンクから濃い赤へ）
    return Color.lerp(
      const Color(0xFFFFE4E1), // 薄いピンク
      const Color(0xFFDC143C), // 濃い赤
      ratio,
    ) ?? Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getMonthlySummary();
    final balance = summary['balance'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C),
        title: const Text('お小遣い帳'),
        actions: [
          // IconButtonの代わりにTextButtonを配置
          TextButton.icon(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.category_outlined, color: Colors.white), // アイコン
            label: const Text(
              'カテゴリ設定', // 表示するテキスト
              style: TextStyle(color: Colors.white), // テキストの色を白に
            ),
            style: TextButton.styleFrom(
              // ボタンの見た目を調整
              foregroundColor: Colors.white, // ボタンを押したときのエフェクト色
            ),
          ),
          const SizedBox(width: 8), // 右端に少し余白を追加
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_currentDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _currentDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.rectangle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.rectangle,
                ),
              ),
              // カスタムビルダーで各日付セルの背景色を設定
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCalendarCell(day, false, false);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarCell(day, true, false);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarCell(day, false, true);
                },
                outsideBuilder: (context, day, focusedDay) {
                  return _buildCalendarCell(day, false, false, isOutside: true);
                },
              ),
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 12),

            // 凡例を追加
            _buildLegend(),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  const Text(
                    '今月の合計',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text('収入：${formatter.format(summary['income'])}円'),
                  const SizedBox(width: 16),
                  Text('支出：${formatter.format(summary['expense'])}円'),
                  const SizedBox(width: 16),
                  Text(
                      '収支：${balance > 0 ? '+' : ''}${formatter.format(summary['balance'])}円'
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  _buildEntryList('収入'),
                  _buildEntryList('支出'),
                  const Divider(),
                  Text(
                    '収支：${balance > 0 ? '+' : ''}${formatter.format(summary['balance'])}円',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showEntryDialog(type: '収入'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('収入を追加'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showEntryDialog(type: '支出'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('支出を追加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // カスタムカレンダーセルビルダー
  Widget _buildCalendarCell(DateTime day, bool isToday, bool isSelected, {bool isOutside = false}) {
    final expenseColor = _getExpenseColor(day);

    Color textColor = isOutside ? Colors.grey : Colors.black;
    Color decorationColor;

    if (isSelected) {
      decorationColor = Colors.orange;
    } else if (isToday) {
      decorationColor = Colors.green;
    } else {
      decorationColor = expenseColor;
    }

    return Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: decorationColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(4.0),
        border: isSelected || isToday ? null : Border.all(
          color: expenseColor.opacity > 0 ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: (isSelected || isToday) ? Colors.white : textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 凡例ウィジェット
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('支出額: ', style: TextStyle(fontSize: 12)),
          Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4E1),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const Text(' 少 ', style: TextStyle(fontSize: 10)),
          Container(
            width: 100,
            height: 8,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFE4E1), Color(0xFFDC143C)],
              ),
            ),
          ),
          const Text(' 多 ', style: TextStyle(fontSize: 10)),
          Container(
            width: 15,
            height: 15,
            decoration: const BoxDecoration(
              color: Color(0xFFDC143C),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getEntriesForDay(DateTime day, String type) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return widget.entries[date]?[type] ?? [];
  }

  Widget _buildEntryList(String type) {
    final entries = _getEntriesForDay(_currentDay, type);
    final total = entries.fold(0, (sum, e) => sum + (e['amount'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$type一覧:',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...entries.map((entry) => ListTile(
          leading: Icon(_getCategoryIcon(entry['category'])),
          title: Text('${entry['category']}：${formatter.format(entry['amount'])}円'),
        )),
        Text('合計：${formatter.format(total)}円',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '食費':
        return Icons.restaurant;
      case '外食費':
        return Icons.local_dining;
      case '交通費':
        return Icons.directions_bus;
      case '日用品':
        return Icons.shopping_cart;
      case '医療費':
        return Icons.local_hospital;
      case '娯楽費':
        return Icons.videogame_asset;
      case '趣味':
        return Icons.palette;
      case '美容費':
        return Icons.spa;
      case 'その他':
        return Icons.category;
      case '給料':
        return Icons.work;
      case 'お小遣い':
        return Icons.monetization_on;
      case '副業':
        return Icons.laptop;
      default:
        return Icons.category;
    }
  }

  Map<String, int> _getMonthlySummary() {
    int income = 0;
    int expense = 0;

    widget.entries.forEach((date, types) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        final incomeList = types['収入'] ?? [];
        final expenseList = types['支出'] ?? [];
        income += incomeList.fold(0, (sum, e) => sum + (e['amount'] as int));
        expense += expenseList.fold(0, (sum, e) => sum + (e['amount'] as int));
      }
    });
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<void> _showEntryDialog({required String type}) async {
    final controller = TextEditingController();
    final categories = type == '支出' ? _expenseCategories : _incomeCategories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${type}カテゴリが登録されていません。設定画面から追加してください。')),
      );
      return;
    }
    String selectedCategory = categories.first;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('${type}の追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedCategory,
                  items: categories
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '金額を入力（例：1,000）'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    Navigator.pop(context, {
                      'category': selectedCategory,
                      'amount': amount,
                    });
                  }
                },
                child: const Text('追加'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final newEntries = Map<DateTime, Map<String, List<Map<String, dynamic>>>>.from(widget.entries);
      final date = DateTime.utc(_currentDay.year, _currentDay.month, _currentDay.day);
      newEntries[date] ??= {'収入': [], '支出': []};
      newEntries[date]![type]!.add(result);
      widget.onUpdateEntries(newEntries);
    }
  }
}
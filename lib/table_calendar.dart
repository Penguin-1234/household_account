import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay =
  DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _currentDay =
  DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // 収入・支出を日付ごとに記録
  final Map<DateTime, Map<String, List<Map<String, dynamic>>>> _entries = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お小遣い帳'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
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
                todayDecoration:
                BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                selectedDecoration:
                BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  _buildEntryList('収入'),
                  _buildEntryList('支出'),
                  const Divider(),
                  Text(
                    '収支：¥${_getBalance()}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
            const SizedBox(width: 12), //収入と支出の間のスペース
            Expanded(
            child:  ElevatedButton(
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

  //特定の日付の「支出 or 収入」の一覧を取得
  List<Map<String, dynamic>> _getEntriesForDay(DateTime day, String type) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return _entries[date]?[type] ?? [];
  }

  // 一覧と合計を表示
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
          title: Text('${entry['category']}：¥${entry['amount']}'),
        )),
        Text('合計：¥$total',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
      ],
    );
  }

  // 収支（収入 − 支出）を計算
  int _getBalance() {
    final income =
    _getEntriesForDay(_currentDay, '収入').fold(0, (sum, e) => sum + (e['amount'] as int));
    final expense =
    _getEntriesForDay(_currentDay, '支出').fold(0, (sum, e) => sum + (e['amount'] as int));
    return income - expense;
  }

  // カテゴリに応じてアイコンを表示
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '食費':
        return Icons.restaurant;
      case '交通費':
        return Icons.directions_bus;
      case '日用品':
        return Icons.shopping_cart;
      case '娯楽':
        return Icons.videogame_asset;
      case 'その他':
        return Icons.category;
      case '給料':
        return Icons.work;
      case 'お小遣い':
        return Icons.monetization_on;
      default:
        return Icons.attach_money;
    }
  }

  // 収入/支出の入力ダイアログ
  Future<void> _showEntryDialog({required String type}) async {
    final controller = TextEditingController();
    String selectedCategory = type == '支出' ? '食費' : '給料';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('$typeの追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedCategory,
                  items: (type == '支出'
                      ? ['食費', '交通費', '日用品', '娯楽', 'その他']
                      : ['給料', 'その他'])
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
                  decoration: const InputDecoration(hintText: '金額を入力（例：1000）'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed:(){
                  Navigator.pop(context); //単に閉じるだけ
                },
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text);
                  if (amount != null) {
                    Navigator.pop(context, {
                      'category': selectedCategory,
                      'amount': amount,
                    });
                  } else {
                    Navigator.pop(context, null);
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
      setState(() {
        final date =
        DateTime.utc(_currentDay.year, _currentDay.month, _currentDay.day);
        _entries[date] ??= {'収入': [], '支出': []};
        _entries[date]![type]!.add(result);
      });
    }
  }
}

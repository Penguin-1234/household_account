import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // 金額をフォーマットするためにインポート


class CalendarPage extends StatefulWidget {
  // --- 変更点: 親からデータと更新用の関数を受け取る ---
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
  DateTime _focusedDay =
  DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _currentDay =
  DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  final formatter = NumberFormat("#,###");

  @override
  Widget build(BuildContext context) {
    final summary=_getMonthlySummary();
    final balance=summary['balance']??0;
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical:12,horizontal: 16),
              child:Wrap(
                alignment: WrapAlignment.center,
                spacing:4, //横方向の間隔
                runSpacing:8, //開業時の縦方向の間隔
                children: [
                  Text(
                    '今月の合計',
                    style:const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width:16),
                    Text('収入：${formatter.format(summary['income'])}円'),
                    const SizedBox(width:16),
                    Text('支出：${formatter.format(summary['expense'])}円'),
                    const SizedBox(width:16),
                    Text(
                    '収支：${balance > 0 ? '+' : ''}${formatter.format(summary['balance'])}円'),
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

  List<Map<String, dynamic>> _getEntriesForDay(DateTime day, String type) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return widget.entries[date]?[type] ?? [];
  }

  //Widgetを返す関数
  Widget _buildEntryList(String type) {
    final entries = _getEntriesForDay(_currentDay, type); //その日のデータをMapで取得
    final total = entries.fold(0, (sum, e) => sum + (e['amount'] as int));  //合計金額の計算

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$type一覧:',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...entries.map((entry) => ListTile( //ListTileでリスト表示できる
          leading: Icon(_getCategoryIcon(entry['category'])),
          title: Text('${entry['category']}：${formatter.format(entry['amount'])}円'),
        )),
        Text('合計：${formatter.format(total)}円',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
      ],
    );
  }

  int _getBalance() {
    final income = _getEntriesForDay(_currentDay, '収入')
        .fold(0, (sum, e) => sum + (e['amount'] as int));
    final expense = _getEntriesForDay(_currentDay, '支出')
        .fold(0, (sum, e) => sum + (e['amount'] as int));
    return income - expense;
  }

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
      case '副業':
        return Icons.laptop;
      default:
        return Icons.attach_money;
    }
  }
  //月の収支を計算する関数
  Map<String,int> _getMonthlySummary(){
    int income=0;
    int expense=0;

    widget.entries.forEach((date,types){
      if(date.year==_focusedDay.year&&date.month==_focusedDay.month){
        final incomeList=types['収入']??[];
        final expenseList=types['支出']??[];
        income+=incomeList.fold(0,(sum,e)=>sum + (e['amount']as int));
        expense+=expenseList.fold(0,(sum,e)=>sum + (e['amount']as int));

      }
    });
    return{
      'income':income,
      'expense':expense,
      'balance':income-expense,
    };
  }

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
                      : ['給料', 'お小遣い', '副業', 'その他'])
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
                  if (amount != null && amount > 0) { // 金額が有効かチェック
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
      final date =
      DateTime.utc(_currentDay.year, _currentDay.month, _currentDay.day);
      newEntries[date] ??= {'収入': [], '支出': []};
      newEntries[date]![type]!.add(result);
      widget.onUpdateEntries(newEntries);
    }
  }
}

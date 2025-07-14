import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // どの月を表示するかを決める
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  // カレンダー上でマークが表示される日付(選択された日付)
  DateTime _currentDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  // 日付をキーとして支出のリストを保持するMap
  // キーのDateTimeは必ずUTCの午前0時に正規化して使用する
  final Map<DateTime, List<int>> _expenses = {};

  List<int> _getExpensesForDay(DateTime day) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return _expenses[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              // selectedDayPredicateで選択されている日を判定する
              selectedDayPredicate: (day) {
                return isSameDay(_currentDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                // setStateでUIの更新
                setState(() {
                  if (!isSameDay(_currentDay, selectedDay)) {
                    _currentDay = selectedDay;
                    _focusedDay = focusedDay;
                  }
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              eventLoader: (day) {
                return _getExpensesForDay(day);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: _getExpensesForDay(_currentDay)
                    .map((amount) => ListTile(
                  title: Text('¥$amount'),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final controller = TextEditingController();
          final result = await showDialog<int>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('金額を入力'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '例:500'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      final value = int.tryParse(controller.text);
                      Navigator.pop(context, value);
                    },
                    child: const Text('追加'),
                  ),
                ],
              );
            },
          );
          if (result != null) {
            setState(() {
              final date = DateTime.utc(
                _currentDay.year,
                _currentDay.month,
                _currentDay.day,
              );
              // 既存のリストを取得、なければ空のリストを作成して、新しい金額を追加
              final existingExpenses = _expenses[date] ?? [];
              existingExpenses.add(result);
              _expenses[date] = existingExpenses;
            });
          }
        },
      ),
    );
  }
}
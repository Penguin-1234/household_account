import 'package:flutter/material.dart';
import 'table_calendar.dart';
import 'graph.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'お小遣いアプリ',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  //収支データをここで一元管理
  final Map<DateTime, Map<String, List<Map<String, dynamic>>>> _entries = {};

  //table_calendarからデータ更新を受け取るための関数
  void _updateEntries(Map<DateTime, Map<String, List<Map<String, dynamic>>>> newEntries) {
    // setStateを呼ぶことで、このウィジェット全体が再描画される
    setState(() {
      _entries.clear();
      _entries.addAll(newEntries);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final incomeMap = getMonthlyCategoryTotals(
      entries: _entries,
      year: now.year,
      month: now.month,
      type: '収入',
    );
    final expenceMap = getMonthlyCategoryTotals(
      entries: _entries,
      year: now.year,
      month: now.month,
      type: '支出',
    );

    // CalendarPageにはデータと更新用関数を渡す
    // GraphPageには計算された月間データを渡す
    final pages = [
      CalendarPage(
        entries: _entries,
        onUpdateEntries: _updateEntries,
      ),
      GraphPage(
        incomeData: incomeMap,
        expenseData: expenceMap,),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'グラフ',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

//月別の支出の合計を計算する関数　requiredは引数
Map<String, int> getMonthlyCategoryTotals({
  required Map<DateTime, Map<String, List<Map<String, dynamic>>>> entries,
  required int year,
  required int month,
  required String type, // '支出' or '収入'
}) {
  final Map<String, int> categoryTotals = {};

  entries.forEach((date, value) {
    if (date.year == year && date.month == month) {
      final list = value[type] ?? [];
      for (var entry in list) {
        final category = entry['category'] as String;
        final amount = entry['amount'] as int;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }
  });

  return categoryTotals;
}
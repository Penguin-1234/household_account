import 'package:flutter/material.dart';
import 'table_calendar.dart';
import 'graph.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'prediction_page2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(MyApp());
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

    // CalendarPageにはデータと更新用関数を渡す
    // GraphPageには計算された月間データを渡す
    final pages = [
      CalendarPage(
        entries: _entries,
        onUpdateEntries: _updateEntries,
      ),
      GraphPage(
        entries: _entries,),
      PredictionPage(
        entries: _entries,
      ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: '予測',
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
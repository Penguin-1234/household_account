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
        primarySwatch: Colors.indigo,  //全体のテーマ色
      ),
      debugShowCheckedModeBanner: false, //debugバーの非表示
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState()=> _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  int _currentIndex=0;
  final _pages=[
    const CalendarPage(),
    const GraphPage(),
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body:_pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon:Icon(Icons.bar_chart),
            label:'グラフ',
          ),
        ],
        onTap:(index){
    setState((){
    _currentIndex=index;
    });
    },
          ),
    );
  }
}
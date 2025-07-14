import 'package:flutter/material.dart';
import 'table_calendar.dart';


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
        primarySwatch: Colors.green,  //全体のテーマ色
      ),
      debugShowCheckedModeBanner: false, //debugバーの非表示
      home: CalendarPage(),
    );
  }
}
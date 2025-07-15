import 'package:flutter/material.dart';

class GraphPage extends StatelessWidget{
  const GraphPage({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(
        title:const Text('グラフ'),
      ),
      body: const Center(
        child:Text(
          'グラフページ（準備中）',
          style:TextStyle(fontSize:24),
        ),
      ),
    );
  }
}
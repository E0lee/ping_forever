import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'BGtest.dart';
import 'Notitest.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Notitest.initializeService();
  await BGtest.initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '熱點維穩君',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '熱點維穩君'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool is_on = true;
  final TextEditingController _ipController = TextEditingController(
    text: '8.8.8.8',
  );

  @override
  void initState() {
    super.initState();
    // BGtest.stopBackgroundService();
    // is_on = false;
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(bottom: 20),
                child: TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: '目標 IP 位址',
                    hintText: '例如: 8.8.8.8',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.network_check),
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 服務狀態顯示
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(),
              child:
                  is_on
                      ? Text('維穩中', style: TextStyle(fontSize: 35))
                      : Text('點擊開始維穩', style: TextStyle(fontSize: 35)),
            ),
            const SizedBox(height: 20),
            // 開始按鈕
            InkWell(
              onTap: () {
                if (is_on) return;

                BGtest.setTargetIp(_ipController.text);
                BGtest.startBackgroundService();
                is_on = true;
                setState(() {});
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('開始維穩😎')));
                return;
              },
              child: Container(
                height: 60,
                width: 200,

                child: Center(
                  child: Text(
                    "開始",

                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: !is_on ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 關閉按鈕
            InkWell(
              onTap: () {
                BGtest.stopBackgroundService();
                is_on = false;
                setState(() {});
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('不維穩😌')));
              },

              child: Container(
                height: 80,
                width: 200,

                child: Center(
                  child: Text(
                    "關閉",
                    style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 重新檢查狀態按鈕
          ],
        ),
      ),
    );
  }
}

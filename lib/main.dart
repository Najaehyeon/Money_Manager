import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_manager/post.dart';
import 'package:money_manager/Detail/detail.dart';
import 'package:money_manager/Home/home.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  runApp(const MoneyManager());
}

class MoneyManager extends StatelessWidget {
  const MoneyManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Money Manager",
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        splashColor: Colors.transparent,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // 1. static const를 제거하고 late 변수로 선언합니다.
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // 2. 초기 화면 설정을 여기서 합니다.
    _widgetOptions = [
      const Home(),
      const Detail(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFF5F5F7),
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_align_left_rounded),
            label: 'Detail',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        enableFeedback: true,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final postResult = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return Post();
              },
            ),
          );
          setState(() {
            _widgetOptions[0] = Home(
              key: UniqueKey(),
            );
            _widgetOptions[1] = Detail(
              key: UniqueKey(),
            );
          });
        },
        splashColor: Colors.grey[800],
        elevation: 1,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          Icons.add,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

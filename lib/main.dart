import 'package:flutter/material.dart';
import 'package:money_manager/constants/app_strings.dart';
import 'package:money_manager/constants/app_styles.dart';
import 'package:money_manager/post.dart';
import 'package:money_manager/Detail/detail.dart';
import 'package:money_manager/Home/home.dart';
import 'package:money_manager/constants/app_colors.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // MobileAds 초기화를 await로 변경하고 에러 핸들링 추가
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    // MobileAds 초기화 실패 시에도 앱이 실행되도록 함
    debugPrint('MobileAds initialization failed: $e');
  }
  
  await initializeDateFormatting();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.surface,
        splashColor: Colors.transparent,
      ),
      home: MainPage(),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: AppStrings.home),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_align_left_rounded),
            label: AppStrings.detail,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
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
        backgroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusCylinder),
        ),
        child: Icon(
          Icons.add,
          size: 28,
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }
}

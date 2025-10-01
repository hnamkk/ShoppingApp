import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoppingapp/screens/profile/address_screen.dart';
import 'package:shoppingapp/screens/profile/profile_screen.dart';
import '../screens/home/home_screen.dart' as app_home;
import '../screens/main_screen.dart';
import '../screens/search/search_screen.dart';

class BottomAppBarWidget extends StatefulWidget {
  const BottomAppBarWidget({super.key});

  @override
  State<BottomAppBarWidget> createState() => _BottomAppBarWidgetState();
}

class _BottomAppBarWidgetState extends State<BottomAppBarWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    return ConvexAppBar(
      backgroundColor: Colors.white,
      style: TabStyle.react,
      height: 60,
      color: Colors.black,
      activeColor: Colors.green,
      items: [
        TabItem(
          icon: Image.asset('assets/images/home.png'),
          activeIcon: Image.asset('assets/images/home_selected.png'),
          title: 'Trang chủ',
        ),
        TabItem(
          icon: Image.asset('assets/images/search.png'),
          activeIcon: Image.asset('assets/images/search_selected.png'),
          title: 'Tìm kiếm',
        ),
        TabItem(
          icon: Image.asset('assets/images/profile.png'),
          activeIcon: Image.asset('assets/images/profile_selected.png'),
          title: 'Tài khoản',
        ),
      ],
      initialActiveIndex: _selectedIndex,
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });

        final appState = context.read<AppState>();

        switch (index) {
          case 0:
            appState.updateScreen(
              'Trang chủ',
              const app_home.HomeScreen(),
            );
            break;
          case 1:
            appState.updateScreen(
              'Tìm kiếm',
              const SearchScreen(),
            );
            break;
          case 2:
            appState.updateScreen(
              'Tài khoản',
              const ProfileScreen(),
            );
            break;
        }
      },
    );
  }
}
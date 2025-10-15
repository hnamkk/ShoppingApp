import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoppingapp/screens/profile/profile_screen.dart';
import '../helpers/notification_helper.dart';
import '../screens/home/home_screen.dart' as app_home;
import '../screens/main_screen_wrapper.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/search/search_screen.dart';

class BottomAppBarWidget extends StatefulWidget {
  const BottomAppBarWidget({super.key});

  @override
  State<BottomAppBarWidget> createState() => _BottomAppBarWidgetState();
}

class _BottomAppBarWidgetState extends State<BottomAppBarWidget> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    _updateSelectedIndexFromAppState(appState.currentTitle);
  }

  void _updateSelectedIndexFromAppState(String title) {
    int newIndex = _selectedIndex;
    if (title == 'Trang chủ') {
      newIndex = 0;
    } else if (title == 'Tìm kiếm') {
      newIndex = 1;
    } else if (title == 'Thông báo') {
      newIndex = 2;
    } else if (title == 'Tài khoản') {
      newIndex = 3;
    }

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

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
          icon: _buildNotificationIcon(false),
          activeIcon: _buildNotificationIcon(true),
          title: 'Thông báo',
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
              'Thông báo',
              const NotificationScreen(),
            );
            break;
          case 3:
            appState.updateScreen(
              'Tài khoản',
              const ProfileScreen(),
            );
            break;
        }
      },
    );
  }

  Widget _buildNotificationIcon(bool isActive) {
    return StreamBuilder<int>(
      stream: NotificationHelper.getUnreadCountStream(),
      initialData: 0,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              isActive
                  ? 'assets/images/notification_selected.png'
                  : 'assets/images/notification.png',
            ),
            if (unreadCount > 0)
              Positioned(
                right: -5,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

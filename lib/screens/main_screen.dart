import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_app_bar.dart';
import 'home/home_screen.dart';

class AppState extends ChangeNotifier {
  String _currentTitle = "Trang chủ";
  Widget _currentBody = const HomeScreen();

  String get currentTitle => _currentTitle;

  Widget get currentBody => _currentBody;

  void updateScreen(String newTitle, Widget newBody) {
    _currentTitle = newTitle;
    _currentBody = newBody;
    notifyListeners();
  }

  void reset() {
    _currentTitle = 'Trang chủ';
    _currentBody = const HomeScreen();
    notifyListeners();
  }
}

class MainScreenWrapper extends StatelessWidget {
  const MainScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return Scaffold(
            body: appState.currentBody,
            bottomNavigationBar: const BottomAppBarWidget(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'home_screen.dart'; // The new dashboard screen
import 'health_check_screen.dart'; // The menu to input data
import 'history_screen.dart'; // The history screen
import 'alarm_screen.dart'; // The new alarm screen
import 'tips_screen.dart'; // A placeholder for the tips screen

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // The list of pages that the navigation bar will switch between
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HealthCheckScreen(),
    HistoryScreen(),
    AlarmScreen(),
    TipsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Input Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_outlined),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true, // Ensures all labels are visible
        type: BottomNavigationBarType.fixed, // Good for 5 items
        onTap: _onItemTapped,
      ),
    );
  }
}
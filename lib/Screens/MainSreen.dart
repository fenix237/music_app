import 'package:flutter/material.dart';
import 'package:music_app/Screens/Library.dart';
import 'HomePage.dart';
import 'SettingsScreen.dart';

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    return widget.child;
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
   HomeScreen(),
   LibraryScreen(),
   SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(  
        index: _currentIndex,
        children: _pages,   
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A273A).withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled),
                _buildNavItem(1, Icons.music_note_outlined),
                _buildNavItem(2, Icons.settings_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isActive ? const BoxDecoration(
          color: Color(0xFFA838FF),
          shape: BoxShape.circle,
        ) : null,
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: 28,
        ),
      ),
    );
  }
}

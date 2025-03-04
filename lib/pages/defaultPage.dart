import 'package:diplomovka/pages/features/user_auth/presentation/pages/homePage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/inspirationPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/myProblemsPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../assets/colorsStyles/text_and_color_styles.dart';

class DefaultPage extends ConsumerStatefulWidget {
  final int initialIndex;
  final bool shouldOpenShoppingList;

  const DefaultPage({
    Key? key,
    this.initialIndex = 0,
    this.shouldOpenShoppingList = false,
  }) : super(key: key);

  @override
  ConsumerState<DefaultPage> createState() => _DefaultPageState();
}

class _DefaultPageState extends ConsumerState<DefaultPage> {
  late int _selectedIndex;
  String? gender = '';

  final List<Widget> _pages = [
    const HomePage(),
    const InspirationPage(),
    const MyHatsPage(),
    const InspirationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF212121),
            ),
            child: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                _buildBottomNavItem(
                  context,
                  0,
                  'Home',
                  'workoutActive',
                  'workoutInactive',
                ),
                _buildBottomNavItem(
                  context,
                  1,
                  'Inspiration',
                  'dietActive',
                  'dietInactive',
                ),
                _buildBottomNavItem(
                  context,
                  2,
                  'My Hats',
                  'mindActive',
                  'mindInactive',
                ),
                _buildBottomNavItem(
                  context,
                  3,
                  'Inspiration',
                  'recoveryActive',
                  'recoveryInactive',
                ),
                _buildBottomNavItem(
                  context,
                  4,
                  'Profile',
                  'profileActive',
                  'profileInactive',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              enableFeedback: false,
              elevation: 0,
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    BuildContext context,
    int index,
    String label,
    String activeIcon,
    String inactiveIcon,
  ) {
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            _selectedIndex == index
                ? 'lib/assets/icons/$activeIcon.svg'
                : 'lib/assets/icons/$inactiveIcon.svg',
            color:
                _selectedIndex == index ? AppStyles.Primary50() : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: _selectedIndex == index
                ? AppStyles.bodyMedium(color: AppStyles.Primary50())
                : AppStyles.bodyMedium(color: Colors.white),
          ),
        ],
      ),
      label: '',
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/ui_scale.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/scan/scan_screen.dart';

/// Persistent shell — 4 tabs kept alive via [IndexedStack].
/// GNav provides the smooth pill-style bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), HistoryScreen(), ScanScreen(), ProfileScreen()];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    AppLogger.info('Bottom nav tab changed: $_index -> $index');
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBg = isDark ? const Color(0xFF0F1712) : Colors.white;
    final activeColor = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;
    final inactiveColor = cs.onSurface.withValues(alpha: 0.40);
    final pillColor = activeColor.withValues(alpha: isDark ? 0.14 : 0.10);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: context.rPad(horizontal: 10, vertical: 4),
            child: GNav(
              selectedIndex: _index,
              onTabChange: _onTap,
              gap: context.rGap(6),
              haptic: false, // we handle it ourselves above
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 300),
              color: inactiveColor,
              activeColor: activeColor,
              iconSize: context.rGap(25),
              tabBackgroundColor: pillColor,
              padding: context.rPad(horizontal: 14, vertical: 8),
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.bar_chart_rounded, text: 'History'),
                GButton(icon: Icons.qr_code_scanner_rounded, text: 'Scan'),
                GButton(icon: Icons.person_rounded, text: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

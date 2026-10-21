import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Aprovel/providers.dart';
import '../Aprovel/inbox_screen.dart';
import '../Report/history_screen.dart';
import '../Report/po_details_report_provider.dart';
import '../home/Home_UI/home_view.dart';
import '../home/logic/home_controller.dart';
import '../../core/theme/app_typography.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => MainShellState();
}

// Public so children can find it
class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final POApprovalController _approvalController;

  final List<Widget> _screens = const [
    HomeView(),
    InboxScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _approvalController = Get.isRegistered<POApprovalController>()
        ? Get.find<POApprovalController>()
        : Get.put(POApprovalController());
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchDashboardStats();
      }
    } else if (index == 1) {
      _approvalController.refreshData();
    } else if (index == 2) {
      if (Get.isRegistered<PaymentVoucherController>()) {
        Get.find<PaymentVoucherController>().refreshVouchers();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      switchTab(0);
      return false;
    }
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.exit_to_app, color: Color(0xFFAC945C)),
              const SizedBox(width: 10),
              Text('Exit App',
                  style: getAppleStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            content: Text('Are you sure you want to exit?',
                style: getAppleStyle(fontSize: 14)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel',
                      style: getAppleStyle(color: Colors.grey[700], fontSize: 14))),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAC945C),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text('Exit',
                    style: getAppleStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout',
            style: getAppleStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('Are you sure you want to logout?',
            style: getAppleStyle(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: getAppleStyle(color: Colors.grey[700], fontSize: 14))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child:
                Text('Logout', style: getAppleStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingDock(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    const titles = ['Dashboard', 'Inbox', 'History'];
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            titles[_currentIndex],
            style: getAppleStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, size: 22, color: Colors.white),
          ),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFAC945C), Color(0xFF8A6E40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 2,
    );
  }

  Widget _buildFloatingDock() {
    return Obx(() {
      final pendingCount = _approvalController.filteredData
          .where((v) => ![
                v.level1,
                v.level2_1,
                v.level2_2,
                v.level2_3,
                v.level3,
                v.level4,
                v.level5,
                v.level6,
                v.level7,
              ].any((l) => (l?.toLowerCase() ?? '').contains('rejected')))
          .length;

      final items = [
        {
          'label': 'Dashboard',
          'icon': Icons.dashboard_outlined,
          'activeIcon': Icons.dashboard_rounded,
        },
        {
          'label': 'Inbox',
          'icon': Icons.inbox_outlined,
          'activeIcon': Icons.inbox_rounded,
          'badge': pendingCount,
        },
        {
          'label': 'History',
          'icon': Icons.history_outlined,
          'activeIcon': Icons.history_rounded,
        },
      ];

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFFAC945C).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isSelected = _currentIndex == idx;
                final badgeCount = (item['badge'] as int?) ?? 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => switchTab(idx),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFAC945C).withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFFAC945C).withOpacity(0.35),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: isSelected ? 1.15 : 1.0,
                                child: Icon(
                                  (isSelected
                                          ? item['activeIcon']
                                          : item['icon']) as IconData,
                                  size: 22,
                                  color: isSelected
                                      ? const Color(0xFFAC945C)
                                      : Colors.grey.shade500,
                                ),
                              ),
                              if (badgeCount > 0)
                                Positioned(
                                  top: -5,
                                  right: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white,
                                          width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    child: Text(
                                      badgeCount > 99
                                          ? '99+'
                                          : '$badgeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: getAppleStyle(
                              fontSize: isSelected ? 11 : 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF8E6500)
                                  : Colors.grey.shade600,
                            ),
                            child: Text(item['label'] as String),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    });
  }
}
